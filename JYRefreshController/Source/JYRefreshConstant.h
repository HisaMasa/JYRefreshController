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
  kJYRefreshStateStop = 0,
  kJYRefreshStateTrigger = 1,
  kJYRefreshStateLoading = 2,
};
