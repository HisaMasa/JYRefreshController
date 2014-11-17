//
//  JYRefreshIndicator.h
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import <UIKit/UIKit.h>

@interface JYRefreshIndicator : UIView

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) BOOL hidesWhenStopped;

- (instancetype)initWithColor:(UIColor*)color;

- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;
- (void)setPercentage:(CGFloat)percentage;

@end
