//
//  JYRefreshController.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshController.h"

static CGFloat const kJYRefreshViewDefaultHeight = 44.0f;
#define JY_ANIMATION_DURATION 0.2f
#define JY_ADJUST_OFFSET [UIApplication sharedApplication].statusBarFrame.size.height

@interface JYRefreshController()

@property (nonatomic, assign) JYRefreshableDirection refreshableDirection;
@property (nonatomic, readwrite, assign) JYRefreshDirection refreshingDirection;
@property (nonatomic, strong) NSMutableDictionary *refreshViews;

@end

@implementation JYRefreshController

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  self = [super init];
  if (self) {
    // set ivars
    _scrollView = scrollView;
    _originContentInsets = scrollView.contentInset;
    _canRefreshDirection = kJYRefreshableDirectionNone;

    [_scrollView addObserver:self
                  forKeyPath:@"contentOffset"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    [_scrollView addObserver:self
                  forKeyPath:@"contentSize"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];

    [self setRefreshView:[self _defaultRefreshViewForDirection:kJYRefreshDirectionBottom]
            forDirection:kJYRefreshDirectionBottom];
    [self setRefreshView:[self _defaultRefreshViewForDirection:kJYRefreshDirectionTop]
            forDirection:kJYRefreshDirectionTop];
  }
  return self;
}

#pragma mark - life cycle

- (void)dealloc
{
  [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [_scrollView removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark - Getter

- (NSMutableDictionary *)refreshViews
{
  if (!_refreshViews) {
    _refreshViews = [NSMutableDictionary dictionary];
  }
  return _refreshViews;
}

- (UIView<JYRefreshView> *)refreshViewAtDirection:(JYRefreshDirection)direction
{
  id refreshView = self.refreshViews[@(direction)];
  if (refreshView) {
    NSAssert([self.refreshViews[@(direction)] conformsToProtocol:@protocol(JYRefreshView)],
             @"review must conforms to <JYRefreshView>");
    return refreshView;
  }
  return nil;
}

#pragma mark - Setter

- (void)setRefreshView:(UIView *)customView forDirection:(JYRefreshDirection)direction
{
  UIView *refreshView = [self refreshViewAtDirection:direction];
  if (refreshView) {
    [refreshView removeFromSuperview];
  }
  [self.refreshViews setObject:customView forKey:@(direction)];
  [self.scrollView addSubview:customView];
  [self _layoutRefreshViewForDirection:direction];
}

- (void)setCanRefreshDirection:(JYRefreshableDirection)canRefreshDirection
{
  _canRefreshDirection = canRefreshDirection;

  for (NSInteger index = 0; index < 2; index++) {
    JYRefreshDirection direction = 1 << index;
    UIView<JYRefreshView> *refreshView = [self refreshViewAtDirection:direction];
    if (direction & canRefreshDirection) {
      refreshView.visible = YES;
      [self _layoutRefreshViewForDirection:direction];
    } else {
      refreshView.visible = NO;
    }
  }
  UIEdgeInsets contentInset = self.originContentInsets;
  if (canRefreshDirection & kJYRefreshDirectionBottom) {
    contentInset.bottom += kJYRefreshViewDefaultHeight;
  } else {
    contentInset.bottom = self.originContentInsets.bottom;
  }
  self.scrollView.contentInset = contentInset;
}

- (void)_setRefreshState:(JYRefreshState)refreshState atDirection:(JYRefreshDirection)direction
{
  UIView<JYRefreshView> *refreshView = [self refreshViewAtDirection:direction];
  [refreshView layoutSubviewsForRefreshState:refreshState];
  if ([self.delegate respondsToSelector:@selector(refreshControl:didRefreshStateChanged:atDirection:)]) {
    [self.delegate refreshControl:self didRefreshStateChanged:refreshState atDirection:direction];
  }
}

#pragma mark - trigger & stop refresh
- (void)triggerRefreshAtDirection:(JYRefreshDirection)direction
{
  [self triggerRefreshAtDirection:direction animated:NO];
}

- (void)triggerRefreshAtDirection:(JYRefreshDirection)direction animated:(BOOL)flag
{
  JYRefreshableDirection refreshableDirection = kJYRefreshableDirectionNone;
  UIEdgeInsets contentInset = _scrollView.contentInset;
  CGPoint contentOffset = CGPointZero;

  CGFloat refreshingInset = kJYRefreshViewDefaultHeight;
  if ([self.delegate respondsToSelector:@selector(refreshControl:refreshingInsetForDirection:)]) {
    refreshingInset = [self.delegate refreshControl:self refreshingInsetForDirection:direction];
  }

  switch (direction) {
    case kJYRefreshDirectionTop:
      refreshableDirection = kJYRefreshableDirectionTop;
      contentInset = UIEdgeInsetsMake(refreshingInset + contentInset.top, contentInset.left, contentInset.bottom, contentInset.right);
      contentOffset = CGPointMake(0, -(refreshingInset + contentInset.top));
      break;
    case kJYRefreshDirectionBottom:
      refreshableDirection = kJYRefreshableDirectionBottom;
      contentOffset = CGPointMake(0, _scrollView.contentSize.height - _scrollView.bounds.size.height
                                  + refreshingInset + contentInset.bottom);
      break;
    default:
      break;
  }

  [self _setRefreshState:kJYRefreshStateLoading atDirection:direction];

  NSTimeInterval duration = flag ? JY_ANIMATION_DURATION : 0.0f;
  [UIView animateWithDuration:duration animations:^{
    _scrollView.contentInset = contentInset;
    _scrollView.contentOffset = contentOffset;
  } completion:^(BOOL finished) {
    self.refreshingDirection |= direction;
    self.refreshableDirection &= ~refreshableDirection;
    if (self.refreshHandleAction) {
      self.refreshHandleAction(direction);
    }
  }];
}

- (void)stopRefreshAtDirection:(JYRefreshDirection)direction completion:(void (^)())completion
{
  [self stopRefreshAtDirection:direction animated:NO completion:completion];
}

- (void)stopRefreshAtDirection:(JYRefreshDirection)direction animated:(BOOL)flag completion:(void (^)())completion
{
  [self _setRefreshState:kJYRefreshStateStop atDirection:direction];
  NSTimeInterval duration = flag ? JY_ANIMATION_DURATION : 0.0f;
  [UIView animateWithDuration:duration animations:^{
    if (direction == kJYRefreshableDirectionTop) {
      UIEdgeInsets contentInset = self.scrollView.contentInset;
      contentInset.top -= kJYRefreshViewDefaultHeight;
      _scrollView.contentInset = contentInset;
    }
    self.refreshingDirection &= ~direction;
  } completion:^(BOOL finished) {
    if (finished) {
      if (completion) {
        completion();
      }
    }
  }];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"contentOffset"]) {
    // for each direction, check to see if refresh sequence needs to be updated.
    for (NSInteger index = 0; index < 2; index++) {
      JYRefreshDirection direction = 1 << index;
      BOOL canRefresh = (self.canRefreshDirection & direction);
      if (canRefresh) {
        [self _checkOffsetsForDirection:direction change:change];
      }
    }

  } else if ([keyPath isEqualToString:@"contentSize"]) {
    for (NSInteger index = 0; index < 2; index++) {
      JYRefreshDirection direction = 1 << index;
      [self _layoutRefreshViewForDirection:direction];
    }
  }
}

#pragma mark - Private Methods
- (void)_checkOffsetsForDirection:(JYRefreshDirection)direction change:(NSDictionary *)change {

  CGPoint contentOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
//  NSLog(@"contentOffset : %.2f", contentOffset.y);

  UIView *refreshView = [self refreshViewAtDirection:direction];

  JYRefreshDirection refreshingDirection = direction;
  JYRefreshableDirection currentRefreshableDirection = kJYRefreshableDirectionNone;
  BOOL canEngage = NO;
  
  UIEdgeInsets contentInset = _scrollView.contentInset;

  CGFloat refreshViewHeight = refreshView.frame.size.height;
  CGFloat refreshableInset = refreshViewHeight;

  if ([self.delegate respondsToSelector:@selector(refreshControl:refreshableInsetForDirection:)]) {
    refreshableInset = [self.delegate refreshControl:self refreshableInsetForDirection:direction];
  }

  CGFloat refreshingInset = refreshViewHeight;
  if ([self.delegate respondsToSelector:@selector(refreshControl:refreshingInsetForDirection:)]) {
    refreshingInset = [self.delegate refreshControl:self refreshingInsetForDirection:direction];
  }
  CGFloat didShowHeight = 0.0f;
  CGFloat threshold = 0.0f;
  switch (direction) {
    case kJYRefreshDirectionTop:
      currentRefreshableDirection = kJYRefreshableDirectionTop;
      didShowHeight = -contentOffset.y - contentInset.top;
      threshold = -contentInset.top - kJYRefreshViewDefaultHeight;
      contentInset = UIEdgeInsetsMake(refreshingInset + contentInset.top,
                                      contentInset.left,
                                      contentInset.bottom,
                                      contentInset.right);
      if ([self.delegate respondsToSelector:@selector(needAdjustInsets)]) {
        if ([self.delegate needAdjustInsets]) {
          contentInset.top += JY_ADJUST_OFFSET;
          didShowHeight -= JY_ADJUST_OFFSET;
          threshold -= JY_ADJUST_OFFSET;
        }
      }
      NSLog(@"didShowHeight: %.2f", didShowHeight);
      canEngage = contentOffset.y <= threshold;
      break;
    case kJYRefreshDirectionBottom: {
      currentRefreshableDirection = kJYRefreshableDirectionBottom;
      didShowHeight = contentOffset.y + self.scrollView.bounds.size.height
                      - self.scrollView.contentSize.height - self.originContentInsets.bottom;
      threshold = self.scrollView.contentSize.height - self.scrollView.bounds.size.height;
      canEngage = contentOffset.y >= threshold;
      break;
    }
    default:
      break;
  }

  if ([self.delegate respondsToSelector:@selector(refreshControl:didShowRefreshViewHeight:atDirection:)]
      && !canEngage) {
    [self.delegate refreshControl:self didShowRefreshViewHeight:didShowHeight atDirection:direction];
  }

  if (!(self.refreshingDirection & refreshingDirection)) {

    if (direction & self.canRefreshDirection) {

      if (!self.scrollView.isDragging && (self.refreshableDirection & currentRefreshableDirection)) {

        self.refreshingDirection |= refreshingDirection;
        self.refreshableDirection &= ~currentRefreshableDirection;
        [self _setRefreshState:kJYRefreshStateLoading atDirection:direction];

        [UIView animateWithDuration:JY_ANIMATION_DURATION
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                           _scrollView.contentInset = contentInset;
                         } completion:^(BOOL finished) {
                           if (self.refreshHandleAction) {
                             self.refreshHandleAction(direction);
                           }
                         }];
        
      } else if (canEngage && !(self.refreshableDirection & currentRefreshableDirection) && self.scrollView.isDragging) {
        self.refreshableDirection |= currentRefreshableDirection;
        [self _setRefreshState:kJYRefreshStateTrigger atDirection:direction];
        NSLog(@"triger");
      } else if (!canEngage && (self.refreshableDirection & currentRefreshableDirection)) {
        self.refreshableDirection &= ~currentRefreshableDirection;
        [self _setRefreshState:kJYRefreshStateStop atDirection:direction];
      }
    }
  }
}

#pragma mark - layout

- (void)_layoutRefreshViewForDirection:(JYRefreshDirection)direction
{
  UIView *refreshView = [self refreshViewAtDirection:direction];
  CGFloat originY = 0.0f;

  if (_canRefreshDirection & direction) {
    [refreshView setHidden:NO];
    switch (direction) {
      case kJYRefreshDirectionTop:
        originY = -CGRectGetHeight(refreshView.frame) - self.originContentInsets.top;
        if ([self.delegate respondsToSelector:@selector(needAdjustInsets)]) {
          if ([self.delegate needAdjustInsets]) {
            originY -= JY_ADJUST_OFFSET;
          }
        }
        break;

      case kJYRefreshDirectionBottom:
        originY = ((self.scrollView.contentSize.height > self.scrollView.frame.size.height)
                   ? self.scrollView.contentSize.height + self.originContentInsets.bottom
                   : self.scrollView.frame.size.height);
        break;

      default:
        break;
    }
    CGRect frame = refreshView.frame;
    frame.origin.y = originY;
    refreshView.frame = frame;
  } else {
    [refreshView setHidden:YES];
  }
}

#pragma mark - Util
- (UIView<JYRefreshView> *)_defaultRefreshViewForDirection:(JYRefreshDirection)direction
{
  CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), kJYRefreshViewDefaultHeight);
  UIView<JYRefreshView> *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
  [refreshView layoutSubviewsForRefreshState:kJYRefreshStateStop];
  return refreshView;
}

@end
