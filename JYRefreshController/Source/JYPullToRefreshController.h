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

typedef NS_ENUM(NSUInteger, JYRefreshDirection)
{
  JYRefreshDirectionTop = 0,
  JYRefreshDirectionLeft = 1,
};

@protocol JYRefreshView;

@interface JYPullToRefreshController : NSObject

@property (nonatomic, readonly, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, readonly, assign) JYRefreshState refreshState;

@property (nonatomic, readonly, assign) JYRefreshDirection direction;

@property (nonatomic, copy) void(^pullToRefreshHandleAction)(void);

// 如果为 YES，则会紧贴 scrollView 正文的上部，否则会在 contentInsets 的上部显示
@property (nonatomic, assign) BOOL showRefreshControllerAboveContent;

/**
 *  Set YES to make refresh view attach to the scrollView edge, default is NO
 */
@property (nonatomic, assign) BOOL attachedEdge;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

/**
 *  Set dragging direction to trigger refresh action. Default is JYRefreshDirectionTop.
 */
- (instancetype)initWithScrollView:(UIScrollView *)scrollView direction:(JYRefreshDirection)direction;

- (void)triggerRefreshWithAnimated:(BOOL)animated;

- (void)stopRefreshWithAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;

- (void)setCustomView:(UIView <JYRefreshView> *)customView;

@end

