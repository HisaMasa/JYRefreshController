//
//  JYRefreshIndicator.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <UIKit/UIKit.h>

@interface JYRefreshIndicator : UIView

@property (nonatomic, readonly) BOOL loading;
@property (nonatomic, assign) BOOL hidesWhenStop;

- (void)setIndicatorColor:(UIColor *)color;

- (void)startLoading;
- (void)stopLoading;

- (void)didLoaded:(float)present;

@end
