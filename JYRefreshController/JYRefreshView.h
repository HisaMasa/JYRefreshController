//
//  JYRefreshView.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <UIKit/UIKit.h>
#import "JYRefresh.h"
#import "JYRefreshIndicator.h"
#import "RTSpinKitView.h"


@protocol JYRefreshView <NSObject>

@property (nonatomic, assign) BOOL visible;

- (void)layoutSubviewsForRefreshState:(JYRefreshState)state;

@end

@interface JYRefreshView : UIView <JYRefreshView>

@property (nonatomic, weak, readonly) RTSpinKitView *refreshIndicator;
@property (nonatomic, weak, readonly) UILabel *titleLabel;
@property (nonatomic, weak, readonly) UILabel *subTitleLabel;

- (void)setTitle:(NSString *)title forRefreshState:(JYRefreshState)refreshState;
- (void)setSubTitle:(NSString *)subTitle forRefreshState:(JYRefreshState)refreshState;

@end
