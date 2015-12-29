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

@property (nonatomic, readwrite, assign) CGFloat originalContentInset;

@property (nonatomic, readwrite, strong) UIView <JYRefreshView> *refreshView;

@property (nonatomic, readwrite, assign) JYRefreshState refreshState;

- (void)layoutRefreshView;

- (UIView <JYRefreshView> *)defalutRefreshView;

- (void)checkOffsetsWithChange:(NSDictionary *)change;

@end

@implementation JYPullToRefreshController
@synthesize refreshView = _refreshView;

#pragma mark - life cycle
- (instancetype)initWithScrollView:(UIScrollView *)scrollView direction:(JYRefreshDirection)direction
{
  self = [super init];
  if (self) {
    _scrollView = scrollView;
    _enable = YES;
    
    if (direction == JYRefreshDirectionTop) {
      _originalContentInset = scrollView.contentInset.top;
    } else if (direction == JYRefreshDirectionLeft) {
      _originalContentInset = scrollView.contentInset.left;
    }
    _direction = direction;
    [self.scrollView addObserver:self
                      forKeyPath:@"contentOffset"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self.scrollView addObserver:self
                      forKeyPath:@"contentInset"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self setCustomView:[self defalutRefreshView]];
  }
  return self;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  return [self initWithScrollView:scrollView direction:JYRefreshDirectionTop];
}

- (void)dealloc
{
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [self.scrollView removeObserver:self forKeyPath:@"contentInset"];
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
  self.refreshState = JYRefreshStateLoading;
  UIEdgeInsets contentInset = [self adjustedContentInset];
  CGPoint contentOffset = [self triggeredContentOffset];
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didShowRefreshViewPercentage:)]) {
    [self.refreshView pullToRefreshController:self didShowRefreshViewPercentage:1.0];
  }

  NSTimeInterval duration = animated ? JYRefreshViewAnimationDuration : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentInset = contentInset;
                     self.scrollView.contentOffset = contentOffset;
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
  UIEdgeInsets contentInset = [self adjustedContentInset];
  
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
  else if ([keyPath isEqualToString:@"contentInset"]) {
    UIEdgeInsets insets = [[change objectForKey:NSKeyValueChangeNewKey] UIEdgeInsetsValue];
    if (_originalContentInset != insets.top) {
      _originalContentInset = insets.top;
    }
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
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  CGFloat refreshViewOffset = 0;
  CGFloat threshold = 0;
  CGFloat checkOffset = 0;
  
  if (_direction == JYRefreshDirectionTop) {
    refreshViewOffset = self.refreshView.frame.size.height;
    threshold = -contentInset.top - refreshViewOffset;
    checkOffset = contentOffset.y;
  } else if (_direction == JYRefreshDirectionLeft) {
    refreshViewOffset = self.refreshView.frame.size.width;
    threshold = -contentInset.left - refreshViewOffset;
    checkOffset = contentOffset.x;
  }
  
  isTriggered = checkOffset <= threshold;
  if ([self.refreshView respondsToSelector:@selector(pullToRefreshController:didShowRefreshViewPercentage:)]
      && self.refreshState == JYRefreshStateStop) {

    CGFloat refreshViewVisibleOffset = 0;
    if (_direction == JYRefreshDirectionTop) {
       refreshViewVisibleOffset = -checkOffset - contentInset.top;
    } else if (_direction == JYRefreshDirectionLeft) {
       refreshViewVisibleOffset = -checkOffset - contentInset.left;
    }
    CGFloat percentage = refreshViewVisibleOffset / refreshViewOffset;
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

      contentInset = [self adjustedContentInset];

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
  CGRect frame = CGRectZero;
  if (_direction == JYRefreshDirectionTop) {
    frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), JYRefreshViewDefaultHeight);
  } else if (_direction == JYRefreshDirectionLeft) {
    frame = CGRectMake(0, 0, JYRefreshViewDefaultHeight, CGRectGetHeight(self.scrollView.bounds));
  }
  
  JYRefreshView *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
  refreshView.autoresizingMask = _direction == JYRefreshDirectionTop ? UIViewAutoresizingFlexibleWidth : UIViewAutoresizingFlexibleHeight;
  return refreshView;
}

- (void)layoutRefreshView
{
  if (self.refreshState != JYRefreshStateStop) {
    return;
  }

  if (self.enable) {
    [self.refreshView setHidden:NO];
    CGFloat offset = 0.0;
    CGRect frame = self.refreshView.frame;

    if (_direction == JYRefreshDirectionTop) {
      if (self.showRefreshControllerAboveContent) {
        offset = -CGRectGetHeight(self.refreshView.frame);
      } else {
        offset = -CGRectGetHeight(self.refreshView.frame) - self.originalContentInset;
      }
      frame.origin.y = offset;
    } else if (_direction == JYRefreshDirectionLeft) {
      if (self.showRefreshControllerAboveContent) {
        offset = -CGRectGetWidth(self.refreshView.frame);
      } else {
        offset = -CGRectGetWidth(self.refreshView.frame) - self.originalContentInset;
      }
      frame.origin.x = offset;
    }
    self.refreshView.frame = frame;
  } else {
    [self.refreshView setHidden:YES];
  }
}

- (UIEdgeInsets)adjustedContentInset
{
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  CGFloat refreshingOffset = 0;
  
  if (self.refreshState == JYRefreshStateStop) {
    if (_direction == JYRefreshDirectionTop) {
      refreshingOffset = self.refreshView.frame.size.height;
      contentInset.top -= refreshingOffset;
    } else if (_direction == JYRefreshDirectionLeft) {
      refreshingOffset = self.refreshView.frame.size.width;
      contentInset.left -= refreshingOffset;
    }
  } else {
    if (_direction == JYRefreshDirectionTop) {
      refreshingOffset = self.refreshView.frame.size.height;
      contentInset.top += refreshingOffset;
    } else if (_direction == JYRefreshDirectionLeft) {
      refreshingOffset = self.refreshView.frame.size.width;
      contentInset.left += refreshingOffset;
    }
  }
  return contentInset;
}

- (CGPoint)triggeredContentOffset
{
  CGPoint contentOffset = CGPointZero;
  UIEdgeInsets contentInset = [self adjustedContentInset];
  if (_direction == JYRefreshDirectionTop) {
    contentOffset = CGPointMake(0, -contentInset.top);
  } else if (_direction == JYRefreshDirectionLeft) {
    contentOffset = CGPointMake(-contentInset.left, 0);
  }
  return contentOffset;
}

@end
