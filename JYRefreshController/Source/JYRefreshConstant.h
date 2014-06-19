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
  kJYRefreshStateStop = 1 << 0,
  kJYRefreshStateTrigger = 1 << 1,
  kJYRefreshStateLoading = 1 << 2,
};

typedef NS_ENUM(NSUInteger, JYRefreshDirection)
{
  kJYRefreshDirectionNone = 0,
  kJYRefreshDirectionTop = 1 << 0,
  kJYRefreshDirectionBottom = 1 << 1,
};

typedef NS_ENUM(NSUInteger, JYRefreshableDirection)
{
  kJYRefreshableDirectionNone = 0,
  kJYRefreshableDirectionTop = 1 << 0,
  kJYRefreshableDirectionBottom = 1 << 1,
};

