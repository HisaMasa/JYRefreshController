//
//  JYRefreshView.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <UIKit/UIKit.h>
#import "JYRefreshIndicator.h"
#import "JYRefreshController.h"

@protocol JYRefreshView

@optional

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
               didChangeToState:(JYRefreshState)refreshState;

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
   didShowRefreshViewPercentage:(CGFloat)percentage;

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
     didScrolllVisableOffset:(CGFloat)visableOffset;

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
                   didSetEnable:(BOOL)enable;

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
                didChangeToState:(JYLoadMoreState)loadMoreState;

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
  didShowhLoadMoreViewPercentage:(CGFloat)percentage;

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
     didScrolllVisableOffset:(CGFloat)visableOffset;

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
                    didSetEnable:(BOOL)enable;

@end

@interface JYRefreshView : UIView <JYRefreshView>

@property (nonatomic, weak, readonly) JYRefreshIndicator *refreshIndicator;

@end
