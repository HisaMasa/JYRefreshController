//
//  JYPullToLoadMoreController.h
//  JYRefreshController
//
//  Created by Alvin on 14/11/17.
//
//

#import <Foundation/Foundation.h>
#import "JYRefreshView.h"

@interface JYPullToLoadMoreController : NSObject

@property (nonatomic, readonly, strong) UIScrollView *scrollView;

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, readonly, assign) JYLoadMoreState loadMoreState;

@property (nonatomic, copy) void(^pullToLoadMoreHandleAction)();

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

- (void)triggerLoadMoreWithAnimated:(BOOL)animated;

- (void)stopLoadMoreWithAnimated:(BOOL)animated completion:(void(^)())completion;

- (void)setCustomView:(UIView <JYRefreshView> *)customView;

@end
