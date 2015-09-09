//
//  JYPullToRefreshController.m
//  JYRefreshController
//
//  Created by Alvin on 14/11/13.
//
//

#import "JYPullToRefreshController.h"
#import "JYRefreshView.h"

#define JYRefreshViewDefaultHeight 44.0f
#define JYRefreshViewAnimationDuration 0.3f

@interface JYPullToRefreshController ()

@property (nonatomic, readwrite, strong) UIScrollView *scrollView;

@property (nonatomic, readwrite, assign) CGFloat originalContentInsetTop;

@property (nonatomic, readwrite, strong) UIView <JYRefreshView> *refreshView;

@property (nonatomic, readwrite, assign) JYRefreshState refreshState;

- (void)layoutRefreshView;

- (UIView <JYRefreshView> *)defalutRefreshView;

- (void)checkOffsetsWithChange:(NSDictionary *)change;

@end

@implementation JYPullToRefreshController
@synthesize refreshView = _refreshView;

#pragma mark - life cycle
- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  self = [super init];
  if (self) {
    _scrollView = scrollView;
    _originalContentInsetTop = scrollView.contentInset.top;
    _enable = YES;

    [self.scrollView addObserver:self
                  forKeyPath:@"contentOffset"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];

    [self setCustomView:[self defalutRefreshView]];
  }
  return self;
}

- (void)dealloc
{
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark- Property
- (void)setRefreshState:(JYRefreshState)refreshState
{
  _refreshState = refreshState;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didChangeToState:)]) {
    [self.refreshView pullToRefreshController:self didChangeToState:refreshState];
  }
}

- (void)setEnable:(BOOL)enable
{
  if (_enable == enable) { // no change
    return;
  }

  // stop refreshing if disabled.
  if (!enable && _refreshState != JYRefreshStateStop) {
    [self stopRefreshWithAnimated:NO completion:nil];
  }

  _enable = enable;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didSetEnable:)]) {
    [self.refreshView pullToRefreshController:self didSetEnable:enable];
  }
  [self layoutRefreshView];
}

#pragma mark - Action
- (void)triggerRefreshWithAnimated:(BOOL)animated
{
  if (!self.enable || self.refreshState == JYRefreshStateLoading) {
    return;
  }
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  CGPoint contentOffset = CGPointZero;

  CGFloat refreshingInset = self.refreshView.frame.size.height;

  contentInset = UIEdgeInsetsMake(refreshingInset + contentInset.top,
                                  contentInset.left,
                                  contentInset.bottom,
                                  contentInset.right);

  contentOffset = CGPointMake(0, -contentInset.top);
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didShowRefreshViewPercentage:)]) {
    [self.refreshView pullToRefreshController:self didShowRefreshViewPercentage:1.0];
  }
  self.refreshState = JYRefreshStateLoading;
  NSTimeInterval duration = animated ? JYRefreshViewAnimationDuration : 0.0f;
  self.scrollView.contentOffset = contentOffset;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;
                   } completion:^(BOOL finished) {
                     if (self.pullToRefreshHandleAction) {
                       self.pullToRefreshHandleAction();
                     }
                   }];
}

- (void)stopRefreshWithAnimated:(BOOL)animated completion:(void(^)())completion
{
  if (!self.enable || self.refreshState == JYRefreshStateStop) {
    return;
  }
  self.refreshState = JYRefreshStateStop;

  UIEdgeInsets contentInset = self.scrollView.contentInset;
  contentInset.top -= self.refreshView.frame.size.height;

  NSTimeInterval duration = animated ? JYRefreshViewAnimationDuration : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                       self.scrollView.contentInset = contentInset;
                   } completion:^(BOOL finished) {
                     if (finished) {
                       if (completion) {
                         completion();
                       }
                     }
                   }];
}

- (void)setCustomView:(UIView <JYRefreshView> *)customView
{
  if (_refreshView.superview) {
    [_refreshView removeFromSuperview];
  }
  _refreshView = customView;
  [self.scrollView addSubview:_refreshView];
  [self layoutRefreshView];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if ([keyPath isEqualToString:@"contentOffset"]) {
    [self checkOffsetsWithChange:change];
  }
}

#pragma mark - Private Methods
- (void)checkOffsetsWithChange:(NSDictionary *)change {
  if (!self.enable) {
    return;
  }
  CGPoint contentOffset = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
  BOOL isTriggered = NO;
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  CGFloat refreshViewHeight = self.refreshView.frame.size.height;
  CGFloat threshold = -contentInset.top - refreshViewHeight;

  isTriggered = contentOffset.y <= threshold;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didShowRefreshViewPercentage:)]
      && self.refreshState == JYRefreshStateStop) {

    CGFloat refreshViewVisibleHeight = -contentOffset.y - contentInset.top;
    CGFloat percentage = refreshViewVisibleHeight / refreshViewHeight;
    percentage = percentage <= 0 ? 0 : percentage;
    percentage = percentage >= 1 ? 1 : percentage;
    [self.refreshView pullToRefreshController:self didShowRefreshViewPercentage:percentage];
  }

  if (self.scrollView.isDragging) {
    if (isTriggered && self.refreshState == JYRefreshStateStop) {
      self.refreshState = JYRefreshStateTrigger;
    } else if (!isTriggered && self.refreshState == JYRefreshStateTrigger) {
      self.refreshState = JYRefreshStateStop;
    }
  }
  else {
    if (self.refreshState == JYRefreshStateTrigger) {
      self.refreshState = JYRefreshStateLoading;

      contentInset = UIEdgeInsetsMake(refreshViewHeight + contentInset.top,
                                      contentInset.left,
                                      contentInset.bottom,
                                      contentInset.right);

      [UIView animateWithDuration:JYRefreshViewAnimationDuration
                            delay:0
                          options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                       animations:^{
                         self.scrollView.contentInset = contentInset;
                       } completion:^(BOOL finished) {
                         if (self.pullToRefreshHandleAction) {
                           self.pullToRefreshHandleAction();
                         }
                       }];
    }
  }
}

- (UIView <JYRefreshView> *)defalutRefreshView
{
  CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), JYRefreshViewDefaultHeight);
  JYRefreshView *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
  refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  return refreshView;
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

@end
