//
//  JYRefreshIndicator.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshIndicator.h"
#include <tgmath.h>

static NSString *const JY_ANIMATION_KEY = @"wave-anim";

@interface JYRefreshIndicator ()
@property (nonatomic, assign, getter = isStopped) BOOL stopped;
@end

@implementation JYRefreshIndicator

- (instancetype)initWithColor:(UIColor*)color
{
  self = [super init];

  if (self) {
    _color = color;
    _hidesWhenStopped = YES;

    [self sizeToFit];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    CGFloat barWidth = CGRectGetWidth(self.bounds) / 5.0;
    for (NSInteger i=0; i < 5; i+=1) {
      CALayer *layer = [CALayer layer];
      layer.backgroundColor = _color.CGColor;
      layer.frame = CGRectMake(barWidth * i, 0.0, barWidth - 3.0, CGRectGetHeight(self.bounds));
      layer.transform = CATransform3DMakeScale(1.0, 0.4, 0.0);
      [self.layer addSublayer:layer];
    }
  }
  return self;
}

- (void)applicationWillEnterForeground
{
  if (self.stopped) {
    [self pauseLayers];
  } else {
    [self resumeLayers];
  }
}

- (void)applicationDidEnterBackground
{
  [self pauseLayers];
}

- (BOOL)isAnimating
{
  return !self.isStopped;
}

- (void)startAnimating
{
  if (self.isStopped) {
    self.hidden = NO;
    self.stopped = NO;
    [self resumeLayers];
  }
}

- (void)stopAnimating
{
  if ([self isAnimating]) {
    if (self.hidesWhenStopped) {
      self.hidden = YES;
    }
    [self pauseLayers];
    self.stopped = YES;
  }
}

- (void)pauseLayers
{
  [self.layer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CALayer *layer = obj;
    [layer removeAnimationForKey:JY_ANIMATION_KEY];
  }];
}

- (void)resumeLayers
{
  NSTimeInterval beginTime = CACurrentMediaTime() + 1.2;
  [self.layer.sublayers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CALayer *layer = obj;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    anim.removedOnCompletion = NO;
    anim.beginTime = beginTime - (1.2 - (0.1 * idx));
    anim.duration = 1.2;
    anim.repeatCount = HUGE_VALF;

    anim.keyTimes = @[@(0.0), @(0.2), @(0.4), @(1.0)];

    anim.timingFunctions = @[
                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                             [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                             ];

    anim.values = @[
                    [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 0.4, 0.0)],
                    [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 0.0)],
                    [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 0.4, 0.0)],
                    [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 0.4, 0.0)]
                    ];

    [layer addAnimation:anim forKey:JY_ANIMATION_KEY];
  }];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  return CGSizeMake(30, 30);
}

- (void)setColor:(UIColor *)color
{
  _color = color;

  for (CALayer *layer in self.layer.sublayers) {
    layer.backgroundColor = color.CGColor;
  }
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
