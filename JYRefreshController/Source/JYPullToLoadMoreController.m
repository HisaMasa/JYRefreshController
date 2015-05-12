//
//  JYPullToLoadMoreController.m
//  JYRefreshController
//
//  Created by Alvin on 14/11/17.
//
//

#import "JYPullToLoadMoreController.h"
#import "JYRefreshView.h"

#define JYLoadMoreViewDefaultHeight 44.0f
#define JYLoadMoreViewAnimationDuration 0.3f

@interface JYPullToLoadMoreController ()

@property (nonatomic, readwrite, strong) UIScrollView *scrollView;

@property (nonatomic, readwrite, assign) CGFloat originalContentInsetBottom;

@property (nonatomic, readwrite, strong) UIView <JYRefreshView> *loadMoreView;

@property (nonatomic, readwrite, assign) JYLoadMoreState loadMoreState;

- (void)layoutLoadMoreView;

- (UIView <JYRefreshView> *)defalutRefreshView;

- (void)checkOffsetsWithChange:(NSDictionary *)change;

@end

@implementation JYPullToLoadMoreController
@synthesize loadMoreView = _loadMoreView;

#pragma mark - life cycle
- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  self = [super init];
  if (self) {
    _scrollView = scrollView;
    _autoLoadMore = YES;
    _originalContentInsetBottom = scrollView.contentInset.bottom;

    [self.scrollView addObserver:self
                  forKeyPath:@"contentOffset"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    [_scrollView addObserver:self
                  forKeyPath:@"contentSize"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];

    [self setCustomView:[self defalutRefreshView]];
    self.enable = YES;
  }
  return self;
}

- (void)dealloc
{
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
}

#pragma mark- Property
- (void)setLoadMoreState:(JYLoadMoreState)loadMoreState
{
  _loadMoreState = loadMoreState;
  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didChangeToState:)]) {
    [self.loadMoreView pullToLoadMoreController:self didChangeToState:loadMoreState];
  }
}

- (void)setEnable:(BOOL)enable
{
  if (_enable == enable) { // no change
    return;
  }
  _enable = enable;
  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didSetEnable:)]) {
    [self.loadMoreView pullToLoadMoreController:self didSetEnable:enable];
  }
  [self layoutLoadMoreView];

  UIEdgeInsets contentInset = self.scrollView.contentInset;
  if (_enable && self.autoLoadMore) {
    contentInset.bottom += self.loadMoreView.frame.size.height;
  } else {
    contentInset.bottom = self.originalContentInsetBottom;
  }

  [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;
                   } completion:NULL];
}

- (void)setAutoLoadMore:(BOOL)autoLoadMore
{
  if (_autoLoadMore == autoLoadMore) {
    return;
  }
  _autoLoadMore = autoLoadMore;
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  if (_enable && _autoLoadMore) {
    contentInset.bottom += self.loadMoreView.frame.size.height;
  } else {
    contentInset.bottom = self.originalContentInsetBottom;
  }
  self.scrollView.contentInset = contentInset;
}

#pragma mark - Action
- (void)triggerLoadMoreWithAnimated:(BOOL)animated
{
  if (!self.enable || self.loadMoreState == JYLoadMoreStateLoading) {
    return;
  }
  CGFloat refreshViewHeight = self.loadMoreView.frame.size.height;
  CGPoint contentOffset = CGPointMake(0, self.scrollView.contentSize.height
                                      - self.scrollView.bounds.size.height
                                      + refreshViewHeight);

  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didShowhLoadMoreViewPercentage:)]){
    [self.loadMoreView pullToLoadMoreController:self didShowhLoadMoreViewPercentage:1.0];
  }
  self.loadMoreState = JYLoadMoreStateLoading;
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  contentInset.bottom += refreshViewHeight;

  NSTimeInterval duration = animated ? JYLoadMoreViewAnimationDuration : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentOffset = contentOffset;
                     if (!self.autoLoadMore) {
                       self.scrollView.contentInset = contentInset;
                     }
                   } completion:^(BOOL finished) {
                     if (self.pullToLoadMoreHandleAction) {
                       self.pullToLoadMoreHandleAction();
                     }
                   }];
}

- (void)stopLoadMoreCompletion:(void(^)())completion
{
  if (!self.enable || self.loadMoreState == JYLoadMoreStateStop) {
    return;
  }
  self.loadMoreState = JYLoadMoreStateStop;

  if (self.autoLoadMore) {
    if (completion) {
      completion();
    }
  }
  else {
    CGFloat refreshViewHeight = self.loadMoreView.frame.size.height;
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    contentInset.bottom -= refreshViewHeight;
    CGPoint contentOffset = CGPointMake(0, self.scrollView.contentSize.height
                                           - self.scrollView.bounds.size.height
                                           + refreshViewHeight);
    [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       self.scrollView.contentInset = contentInset;
                       self.scrollView.contentOffset = contentOffset;
                     } completion:^(BOOL finished) {
                       if (finished) {
                         if (completion) {
                           completion();
                         }
                       }
                     }];
  }
}

- (void)setCustomView:(UIView<JYRefreshView> *)customView
{
  if (_loadMoreView.superview) {
    [_loadMoreView removeFromSuperview];
  }
  _loadMoreView = customView;
  [self.scrollView addSubview:_loadMoreView];
  [self layoutLoadMoreView];
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
    [self layoutLoadMoreView];
  }
}

#pragma mark - Private Methods
- (void)checkOffsetsWithChange:(NSDictionary *)change {
  if (!self.enable) {
    return;
  }
  CGPoint contentOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
  BOOL isTriggered = NO;
  CGFloat refreshViewHeight = self.loadMoreView.frame.size.height;
  CGFloat threshold = self.scrollView.contentSize.height
                    + refreshViewHeight
                    - self.scrollView.bounds.size.height;

  isTriggered = contentOffset.y >= threshold;
  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didShowhLoadMoreViewPercentage:)]
      && self.loadMoreState == JYLoadMoreStateStop) {

    CGFloat refreshViewVisibleHeight = contentOffset.y - threshold + refreshViewHeight;
    CGFloat percentage = refreshViewVisibleHeight / refreshViewHeight;
    percentage = percentage <= 0 ? 0 : percentage;
    percentage = percentage >= 1 ? 1 : percentage;
    [self.loadMoreView pullToLoadMoreController:self didShowhLoadMoreViewPercentage:percentage];
  }

  if (self.scrollView.isDragging) {
    if (isTriggered && self.loadMoreState == JYLoadMoreStateStop) {
      self.loadMoreState = JYLoadMoreStateTrigger;
    } else if (!isTriggered && self.loadMoreState == JYLoadMoreStateTrigger) {
      self.loadMoreState = JYLoadMoreStateStop;
    }
  }
  else {
    if (self.loadMoreState == JYLoadMoreStateTrigger) {
      self.loadMoreState = JYLoadMoreStateLoading;

      if (self.autoLoadMore) {
        if (self.pullToLoadMoreHandleAction) {
          self.pullToLoadMoreHandleAction();
        }
      }
      else {
        UIEdgeInsets contentInset = self.scrollView.contentInset;
        contentInset.bottom += refreshViewHeight;
        [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                           self.scrollView.contentInset = contentInset;
                         } completion:^(BOOL finished) {
                           if (self.pullToLoadMoreHandleAction) {
                             self.pullToLoadMoreHandleAction();
                           }
                         }];
      }
    }
  }
}

- (UIView <JYRefreshView> *)defalutRefreshView
{
  CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), JYLoadMoreViewDefaultHeight);
  JYRefreshView *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
  refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  return refreshView;
}

- (void)layoutLoadMoreView
{
  if (self.enable) {
    [self.loadMoreView setHidden:NO];
    CGFloat originY = self.scrollView.contentSize.height + self.originalContentInsetBottom;
    CGRect frame = self.loadMoreView.frame;
    frame.origin.y = originY;
    self.loadMoreView.frame = frame;
  } else {
    [self.loadMoreView setHidden:YES];
  }
}

@end
