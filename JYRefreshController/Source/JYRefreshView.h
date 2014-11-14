//
//  JYRefreshView.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <UIKit/UIKit.h>
#import "JYRefreshConstant.h"
#import "JYRefreshIndicator.h"


@class JYPullToRefreshController;

@protocol JYRefreshView

@optional

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
               didChangeToState:(JYRefreshState)refreshState;

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
   didShowRefreshViewPercentage:(CGFloat)percentage;

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
                   didSetEnable:(BOOL)enable;
@end

@interface JYRefreshView : UIView <JYRefreshView>

@property (nonatomic, weak, readonly) JYRefreshIndicator *refreshIndicator;

@end
