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

@property (nonatomic, readwrite, assign) CGFloat originalContentInset;

@property (nonatomic, readwrite, strong) UIView <JYRefreshView> *loadMoreView;

@property (nonatomic, readwrite, assign) JYLoadMoreState loadMoreState;


- (void)layoutLoadMoreView;

- (UIView <JYRefreshView> *)defalutRefreshView;

- (void)checkOffsetsWithChange:(CGPoint)change;

@end

@implementation JYPullToLoadMoreController
@synthesize panGesture = _panGesture;
@synthesize loadMoreView = _loadMoreView;

#pragma mark - life cycle

- (instancetype)initWithScrollView:(UIScrollView *)scrollView direction:(JYLoadMoreDirection)direction
{
  self = [super init];
  if (self) {
    _scrollView = scrollView;
    _autoLoadMore = YES;
    _direction = direction;
    CGFloat inset = 0;
    if (direction == JYLoadMoreDirectionBottom) {
      inset = scrollView.contentInset.bottom;
    } else if (direction == JYLoadMoreDirectionRight) {
      inset = scrollView.contentInset.right;
    }
    _originalContentInset = inset;
    [_scrollView addObserver:self
                  forKeyPath:@"contentOffset"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    [_scrollView addObserver:self
                  forKeyPath:@"contentSize"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    [self.panGesture addObserver:self
                      forKeyPath:@"state"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
    
    [self setCustomView:[self defalutRefreshView]];
    [self setEnable:YES withAnimation:NO];
  }
  return self;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView
{
  return [self initWithScrollView:scrollView direction:JYLoadMoreDirectionBottom];
}

- (void)dealloc
{
  [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
  [self.scrollView removeObserver:self forKeyPath:@"contentSize"];
  [self.panGesture removeObserver:self forKeyPath:@"state"];
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
  [self setEnable:enable withAnimation:YES];
}

- (void)setEnable:(BOOL)enable withAnimation:(BOOL)animated
{
  if (_enable == enable) { // no change
    return;
  }
  _enable = enable;
  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didSetEnable:)]) {
    [self.loadMoreView pullToLoadMoreController:self didSetEnable:enable];
  }
  [self layoutLoadMoreView];
  
  UIEdgeInsets contentInset = [self initalContentInset];
  
  if (animated) {
    [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
  } else {
    self.scrollView.contentInset = contentInset;
  }
}

- (void)setAutoLoadMore:(BOOL)autoLoadMore
{
  if (_autoLoadMore == autoLoadMore) {
    return;
  }
  _autoLoadMore = autoLoadMore;
  UIEdgeInsets contentInset = [self initalContentInset];
  self.scrollView.contentInset = contentInset;
}

#pragma mark - Action
- (void)triggerLoadMoreWithAnimated:(BOOL)animated
{
  if (!self.enable || self.loadMoreState == JYLoadMoreStateLoading) {
    return;
  }
  
  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didShowhLoadMoreViewPercentage:)]){
    [self.loadMoreView pullToLoadMoreController:self didShowhLoadMoreViewPercentage:1.0];
  }
  self.loadMoreState = JYLoadMoreStateLoading;
  CGPoint contentOffset = [self triggeredContentOffset];
  
  NSTimeInterval duration = animated ? JYLoadMoreViewAnimationDuration : 0.0f;
  [UIView animateWithDuration:duration
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     self.scrollView.contentOffset = contentOffset;
                     if (!self.autoLoadMore) {
                       UIEdgeInsets contentInset = [self adjustedContentInset];
                       self.scrollView.contentInset = contentInset;
                     }
                   } completion:^(BOOL finished) {
                     if (self.pullToLoadMoreHandleAction) {
                       self.pullToLoadMoreHandleAction();
                     }
                   }];
}

- (void)stopLoadMoreCompletion:(void(^)(void))completion
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
    UIEdgeInsets contentInset = [self adjustedContentInset];
    [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
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
  if ([keyPath isEqualToString:@"contentOffset"] || [keyPath isEqualToString:@"state"]) {
    CGPoint contentOffset = self.scrollView.contentOffset;
    [self checkOffsetsWithChange:contentOffset];
    if (self.attachedEdge) {
      [self layoutLoadMoreView];
    }
  } else if ([keyPath isEqualToString:@"contentSize"]) {
    [self layoutLoadMoreView];
  }
}

#pragma mark - Private Methods
- (void)checkOffsetsWithChange:(CGPoint)change {
  if (!self.enable) {
    return;
  }
  CGPoint contentOffset = change;
  BOOL isTriggered = NO;
  CGFloat threshold = 0;
  CGFloat checkOffset = 0;
  CGFloat refreshViewOffset = 0;
  if (_direction == JYLoadMoreDirectionBottom) {
    refreshViewOffset = self.loadMoreView.frame.size.height;
    threshold = self.scrollView.contentSize.height
            + self.scrollView.contentInset.bottom
            - self.scrollView.bounds.size.height;
    checkOffset = contentOffset.y;
    
  } else if (_direction == JYLoadMoreDirectionRight) {
    refreshViewOffset = self.loadMoreView.frame.size.width;
    threshold = self.scrollView.contentSize.width
            + self.scrollView.contentInset.right
            - self.scrollView.bounds.size.width;
    checkOffset = contentOffset.x;
  }
  if (!self.autoLoadMore) {
    threshold += refreshViewOffset;
  }
  
  isTriggered = checkOffset >= threshold;
  CGFloat refreshViewVisibleOffset = checkOffset - threshold + refreshViewOffset;

  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didShowhLoadMoreViewPercentage:)]
      && self.loadMoreState == JYLoadMoreStateStop) {
    CGFloat percentage = refreshViewVisibleOffset / refreshViewOffset;
    percentage = percentage <= 0 ? 0 : percentage;
    percentage = percentage >= 1 ? 1 : percentage;
    [self.loadMoreView pullToLoadMoreController:self didShowhLoadMoreViewPercentage:percentage];
  }

  if ([self.loadMoreView respondsToSelector:@selector(pullToLoadMoreController:didScrolllVisableOffset:)]
      ) {
    [self.loadMoreView pullToLoadMoreController:self didScrolllVisableOffset:refreshViewVisibleOffset];
  }
  
  if (self.autoLoadMore) {
    if (isTriggered && self.loadMoreState == JYLoadMoreStateStop) {
      self.loadMoreState = JYLoadMoreStateTrigger;
    } else if (!isTriggered && self.loadMoreState == JYLoadMoreStateTrigger) {
      self.loadMoreState = JYLoadMoreStateStop;
    }
    if (!self.scrollView.dragging && !self.scrollView.tracking) {
      if (self.loadMoreState == JYLoadMoreStateTrigger) {
        self.loadMoreState = JYLoadMoreStateLoading;
        CGPoint contentOffset = [self triggeredContentOffset];
        [UIView animateWithDuration:JYLoadMoreViewAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                           self.scrollView.contentOffset = contentOffset;
                         } completion:^(BOOL finished) {
                           if (self.pullToLoadMoreHandleAction) {
                             self.pullToLoadMoreHandleAction();
                           }
                         }];
      }
    }
  } else {
    if (self.panGesture.state == UIGestureRecognizerStateBegan
        || self.panGesture.state == UIGestureRecognizerStateChanged) {
      if (isTriggered && self.loadMoreState == JYLoadMoreStateStop) {
        self.loadMoreState = JYLoadMoreStateTrigger;
      } else if (!isTriggered && self.loadMoreState == JYLoadMoreStateTrigger) {
        self.loadMoreState = JYLoadMoreStateStop;
      }
    }
    else {
      if (self.loadMoreState == JYLoadMoreStateTrigger) {
        self.loadMoreState = JYLoadMoreStateLoading;
        UIEdgeInsets contentInset = [self adjustedContentInset];
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
  CGRect frame = CGRectZero;
  if (_direction == JYLoadMoreDirectionBottom) {
    frame = CGRectMake(0, 0, CGRectGetWidth(self.scrollView.bounds), JYLoadMoreViewDefaultHeight);
  } else if (_direction == JYLoadMoreDirectionRight) {
    frame = CGRectMake(0, 0, JYLoadMoreViewDefaultHeight, CGRectGetHeight(self.scrollView.bounds));
  }
  JYRefreshView *refreshView = [[JYRefreshView alloc] initWithFrame:frame];
  refreshView.autoresizingMask = _direction == JYLoadMoreDirectionBottom ? UIViewAutoresizingFlexibleWidth : UIViewAutoresizingFlexibleHeight;
  return refreshView;
}

- (void)layoutLoadMoreView
{
  if (self.enable) {
    [self.loadMoreView setHidden:NO];
    
    CGRect frame = self.loadMoreView.frame;
    
    CGFloat offset = 0;
    if (_direction == JYLoadMoreDirectionBottom) {
      offset = self.scrollView.contentSize.height;
      if (self.attachedEdge) {
        offset += MAX(0, self.scrollView.contentOffset.y + self.scrollView.frame.size.height - self.scrollView.contentSize.height);
        offset -= self.loadMoreView.frame.size.height;
      }
      if (!self.showRefreshControllerBelowContent) {
        offset += self.originalContentInset;
      }
      frame.origin.y = offset;
    } else if (_direction == JYLoadMoreDirectionRight) {
      offset = self.scrollView.contentSize.width;
      if (self.attachedEdge) {
        offset += MAX(0, self.scrollView.contentOffset.x + self.scrollView.frame.size.width - self.scrollView.contentSize.width);
        offset -= self.loadMoreView.frame.size.width;
      }
      if (!self.showRefreshControllerBelowContent) {
        offset += self.originalContentInset;
      }
      frame.origin.x = offset;
    }
    
    self.loadMoreView.frame = frame;
  } else {
    [self.loadMoreView setHidden:YES];
  }
}

- (UIEdgeInsets)initalContentInset
{
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  if (_enable && _autoLoadMore) {
    if (_direction == JYLoadMoreDirectionBottom) {
      contentInset.bottom += self.loadMoreView.frame.size.height;
    } else if (_direction == JYLoadMoreDirectionRight) {
      contentInset.right += self.loadMoreView.frame.size.width;
    }
  } else {
    if (_direction == JYLoadMoreDirectionBottom) {
      contentInset.bottom = self.originalContentInset;
    } else if (_direction == JYLoadMoreDirectionRight) {
      contentInset.right = self.originalContentInset;
    }
  }
  return contentInset;
}

- (UIEdgeInsets)adjustedContentInset
{
  UIEdgeInsets contentInset = self.scrollView.contentInset;
  if (self.loadMoreState == JYLoadMoreStateStop) {
    if (_direction == JYLoadMoreDirectionBottom) {
      contentInset.bottom -= self.loadMoreView.frame.size.height;
    } else if (_direction == JYLoadMoreDirectionRight) {
      contentInset.right -= self.loadMoreView.frame.size.width;
    }
  } else {
    if (_direction == JYLoadMoreDirectionBottom) {
      contentInset.bottom += self.loadMoreView.frame.size.height;
    } else if (_direction == JYLoadMoreDirectionRight) {
      contentInset.right += self.loadMoreView.frame.size.width;
    }
  }
  return contentInset;
}

- (CGFloat)refreshViewOffset
{
  CGFloat offset = 0;
  if (_direction == JYLoadMoreDirectionBottom) {
    offset = self.loadMoreView.frame.size.height;
  } else if (_direction == JYLoadMoreDirectionRight) {
    offset = self.loadMoreView.frame.size.width;
  }
  return offset;
}

- (CGPoint)triggeredContentOffset
{
  CGFloat offset = 0;
  CGPoint contentOffset = CGPointZero;
  if (_direction == JYLoadMoreDirectionBottom) {
    offset = self.loadMoreView.frame.size.height;
    offset = self.scrollView.contentSize.height
          - self.scrollView.bounds.size.height
          + offset;
    contentOffset.y = offset;
  } else if (_direction == JYLoadMoreDirectionRight) {
    offset = self.loadMoreView.frame.size.width;
    offset = self.scrollView.contentSize.width
          - self.scrollView.bounds.size.width
          + offset;
    contentOffset.x = offset;
  }
  return contentOffset;
}

- (UIPanGestureRecognizer *)panGesture
{
    if (_panGesture) {
        return _panGesture;
    }
    return self.scrollView.panGestureRecognizer;
}

- (void)setPanGesture:(UIPanGestureRecognizer *)panGesture
{
    if (panGesture) {
        [self.panGesture removeObserver:self forKeyPath:@"state"];
    }
    _panGesture = panGesture;
    [self.panGesture addObserver:self
                      forKeyPath:@"state"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
}

@end

