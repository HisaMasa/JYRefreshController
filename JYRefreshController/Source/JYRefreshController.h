//
//  JYRefreshController.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <Foundation/Foundation.h>
#import "JYRefreshView.h"
#import "JYRefreshConstant.h"


@protocol JYRefreshControlDelegate;
@protocol JYRefreshView;

@interface JYRefreshController : NSObject

@property (nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nonatomic, assign) UIEdgeInsets originContentInsets;
@property (nonatomic, assign) JYRefreshableDirection canRefreshDirection;
@property (nonatomic, readonly, assign) JYRefreshDirection refreshingDirection;
@property (nonatomic, strong) UIColor *defaultIndicatorColor;

@property (nonatomic, weak) id<JYRefreshControlDelegate> delegate;
@property (nonatomic, copy) void(^refreshHandleAction)(JYRefreshDirection loadingDirection);

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

- (void)triggerRefreshAtDirection:(JYRefreshDirection)direction;
- (void)triggerRefreshAtDirection:(JYRefreshDirection)direction animated:(BOOL)flag;

- (void)stopRefreshAtDirection:(JYRefreshDirection)direction completion:(void(^)())completion;
- (void)stopRefreshAtDirection:(JYRefreshDirection)direction animated:(BOOL)flag completion:(void(^)())completion;

- (UIView<JYRefreshView> *)refreshViewAtDirection:(JYRefreshDirection)direction;
- (void)setRefreshView:(UIView *)customView forDirection:(JYRefreshDirection)direction;

@end

@protocol JYRefreshControlDelegate <NSObject>

@optional

- (BOOL)needAdjustInsets;

- (void)refreshControl:(JYRefreshController *)refreshControl
didShowRefreshViewHeight:(CGFloat)progress
           atDirection:(JYRefreshDirection)direction;

- (void)refreshControl:(JYRefreshController *)refreshControl
didRefreshStateChanged:(JYRefreshState)refreshState
           atDirection:(JYRefreshDirection)direction;


@end

