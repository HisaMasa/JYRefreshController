//
//  JYPullToRefreshController.h
//  JYRefreshController
//
//  Created by Alvin on 14/11/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JYRefreshState)
{
  JYRefreshStateStop = 0,
  JYRefreshStateTrigger = 1,
  JYRefreshStateLoading = 2,
};

@protocol JYRefreshView;

@interface JYPullToRefreshController : NSObject

@property (nonatomic, readonly, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, readonly, assign) JYRefreshState refreshState;

@property (nonatomic, copy) void(^pullToRefreshHandleAction)();

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

- (void)triggerRefreshWithAnimated:(BOOL)animated;

- (void)stopRefreshWithAnimated:(BOOL)animated completion:(void(^)())completion;

- (void)setCustomView:(UIView <JYRefreshView> *)customView;

@end
