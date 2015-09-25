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

// 如果为 YES，则会紧贴 scrollView 正文的上部，否则会在 contentInsets 的上部显示
@property (nonatomic, assign) BOOL showRefreshControllerAboveContent;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

- (void)triggerRefreshWithAnimated:(BOOL)animated;

- (void)stopRefreshWithAnimated:(BOOL)animated completion:(void(^)())completion;

- (void)setCustomView:(UIView <JYRefreshView> *)customView;

@end
