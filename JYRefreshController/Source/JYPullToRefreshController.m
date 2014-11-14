//
//  JYPullToRefreshController.m
//  JYRefreshController
//
//  Created by Alvin on 14/11/13.
//
//

#import "JYPullToRefreshController.h"

#define kJYRefreshViewDefaultHeight 44.0f

@interface JYPullToRefreshController ()

@property (nonatomic, readwrite, strong) UIScrollView *scrollView;

@property (nonatomic, readwrite, assign) CGFloat originalContentInsetTop;

@property (nonatomic, readwrite, strong) UIView <JYRefreshView> *refreshView;

@property (nonatomic, readwrite, assign) JYRefreshState refreshState;

- (void)layoutRefreshView;

@end

@implementation JYPullToRefreshController
@synthesize refreshView = _refreshView;

#pragma mark - life cycle
- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  self = [super init];
  if (self) {
      // set ivars
    _scrollView = scrollView;
    _originalContentInsetTop = scrollView.contentInset.top;
    _enable = YES;

    [_scrollView addObserver:self
                  forKeyPath:@"contentOffset"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    [_scrollView addObserver:self
                  forKeyPath:@"contentSize"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];

    [self setRefreshView:self.refreshView];
  }
  return self;
}

- (void)dealloc
{
  [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [_scrollView removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark- Property
- (UIView<JYRefreshView> *)refreshView
{
  if (!_refreshView) {
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), kJYRefreshViewDefaultHeight);
    JYRefreshView *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
    [self.scrollView addSubview:refreshView];
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.refreshState = kJYRefreshStateStop;
    _refreshView = refreshView;
  }
  return _refreshView;
}

- (void)setRefreshState:(JYRefreshState)refreshState
{
  _refreshState = refreshState;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didChangeToState:)]) {
    [self.refreshView pullToRefreshController:self didChangeToState:refreshState];
  }
}

- (void)setEnable:(BOOL)enable
{
  _enable = enable;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didSetEnable:)]) {
    [self.refreshView pullToRefreshController:self didSetEnable:enable];
  }
  [self layoutRefreshView];
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  contentInset.top = self.originalContentInsetTop;

  [UIView animateWithDuration:.2f
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;
                   } completion:NULL];
}

#pragma mark - Action
- (void)triggerRefreshWithAnimated:(BOOL)animated
{
  if (!self.enable || self.refreshState == kJYRefreshStateLoading) {
    return;
  }
  UIEdgeInsets contentInset = _scrollView.contentInset;
  CGPoint contentOffset = CGPointZero;

  CGFloat refreshingInset = self.refreshView.frame.size.height;

  contentInset = UIEdgeInsetsMake(refreshingInset + contentInset.top,
                                  contentInset.left,
                                  contentInset.bottom,
                                  contentInset.right);

  contentOffset = CGPointMake(0, -contentInset.top);
    //  NSLog(@"contentOffset : %.2f", contentOffset.y);

  self.refreshState = kJYRefreshStateLoading;
  NSTimeInterval duration = animated ? 0.2f : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     _scrollView.contentInset = contentInset;
                     _scrollView.contentOffset = contentOffset;
                   } completion:^(BOOL finished) {
                     if (self.pullToRefreshHandleAction) {
                       self.pullToRefreshHandleAction();
                     }
                   }];
}

- (void)stopRefreshWithAnimated:(BOOL)animated completion:(void(^)())completion
{
  if (!self.enable || self.refreshState != kJYRefreshStateStop) {
    return;
  }
  self.refreshState = kJYRefreshStateStop;
  NSTimeInterval duration = animated ? 0.2f : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                       UIEdgeInsets contentInset = self.scrollView.contentInset;
                       contentInset.top = self.originalContentInsetTop;
                       self.scrollView.contentInset = contentInset;
                   } completion:^(BOOL finished) {
                     if (finished) {
                       if (completion) {
                         completion();
                       }
                     }
                   }];
}

- (void)setRefreshView:(UIView <JYRefreshView> *)customView
{
  if (_refreshView.superview) {
    [_refreshView removeFromSuperview];
  }
  _refreshView = customView;
  [self.scrollView addSubview:_refreshView];
  [self layoutRefreshView];
}

- (void)layoutRefreshView
{
  if (self.enable) {
    [self.refreshView setHidden:NO];
    CGFloat originY = -CGRectGetHeight(self.refreshView.frame) - self.originalContentInsetTop;
    CGRect frame = self.refreshView.frame;
    frame.origin.y = originY;
    self.refreshView.frame = frame;
  } else {
    [self.refreshView setHidden:YES];
  }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"contentOffset"]) {
    [self checkOffsetsWithChange:change];
  } else if ([keyPath isEqualToString:@"contentSize"]) {
    [self layoutRefreshView];
  }
}

#pragma mark - Private Methods
- (void)checkOffsetsWithChange:(NSDictionary *)change {
  if (!self.enable) {
    return;
  }
  CGPoint contentOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];

  BOOL isTriggered = NO;

  UIEdgeInsets contentInset = _scrollView.contentInset;

  CGFloat refreshViewHeight = self.refreshView.frame.size.height;
  CGFloat refreshingInset = refreshViewHeight;
  CGFloat didShowHeight = 0.0f;
  CGFloat threshold = 0.0f;

  didShowHeight = -contentOffset.y - contentInset.top;
  threshold = -contentInset.top - refreshingInset;
  contentInset = UIEdgeInsetsMake(refreshingInset + contentInset.top,
                                  contentInset.left,
                                  contentInset.bottom,
                                  contentInset.right);

  didShowHeight += refreshingInset;
    //      NSLog(@"didShowHeight: %.2f", didShowHeight);
  isTriggered = contentOffset.y <= threshold;

  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didShowRefreshViewPercentage:)]
      && !isTriggered) {
    [self.refreshView pullToRefreshController:self didShowRefreshViewPercentage:didShowHeight];
  }

  if (!self.scrollView.isDragging) {

    self.refreshState = kJYRefreshStateLoading;

    [UIView animateWithDuration:.2f
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       _scrollView.contentInset = contentInset;
                     } completion:^(BOOL finished) {
                       if (self.pullToRefreshHandleAction) {
                         self.pullToRefreshHandleAction();
                       }
                     }];

  } else if (isTriggered && self.scrollView.isDragging) {
    self.refreshState = kJYRefreshStateTrigger;
  } else if (!isTriggered) {
    self.refreshState = kJYRefreshStateStop;
  }
}

@end
