//
//  JYRefresh.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, JYRefreshState)
{
  JYRefreshStateStop = 0,
  JYRefreshStateTrigger = 1,
  JYRefreshStateLoading = 2,
};

typedef NS_ENUM(NSUInteger, JYLoadMoreState)
{
  JYLoadMoreStateStop = 0,
  JYLoadMoreStateTrigger = 1,
  JYLoadMoreStateLoading = 2,
};
