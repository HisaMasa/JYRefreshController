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


@protocol JYRefreshView <NSObject>

@property (nonatomic, assign) BOOL visible;

- (void)layoutSubviewsForRefreshState:(JYRefreshState)state;

@end

@interface JYRefreshView : UIView <JYRefreshView>

@property (nonatomic, weak, readonly) JYRefreshIndicator *refreshIndicator;

@end
