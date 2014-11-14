//
//  JYRefreshIndicator.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshIndicator.h"
#include <tgmath.h>

static NSString *const JY_ANIMATION_KEY = @"spinkit-anim";

@interface JYRefreshIndicator ()
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, strong) CALayer *cycleLayer;
@end

@implementation JYRefreshIndicator

- (instancetype)initWithColor:(UIColor*)color
{
  self = [super init];

  if (self) {
    _color = color;
    _hidesWhenStopped = YES;
    _stopped = YES;

    [self sizeToFit];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
  }
  return self;
}

#pragma mark - Property
- (CALayer *)cycleLayer
{
  if (!_cycleLayer) {
    _cycleLayer= [CALayer layer];
    _cycleLayer.frame = CGRectInset(self.bounds, 2.0, 2.0);
    _cycleLayer.backgroundColor = _color.CGColor;
    _cycleLayer.anchorPoint = CGPointMake(0.5, 0.5);
    _cycleLayer.opacity = 1;
    _cycleLayer.cornerRadius = CGRectGetHeight(_cycleLayer.bounds) * 0.5;
    _cycleLayer.transform = CATransform3DMakeScale(0.2, 0.2, 0.0);
    [self.layer addSublayer:_cycleLayer];
  }
  return _cycleLayer;
}

#pragma mark - Notification
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
  return !self.stopped;
}

- (void)startAnimating
{
  if (self.stopped) {
    self.stopped = NO;
    [self resumeLayers];
  }
}

- (void)stopAnimating
{
  if ([self isAnimating]) {
    if (self.hidesWhenStopped) {
    }
    [self pauseLayers];
    self.stopped = YES;
  }
}

- (void)setPercentage:(CGFloat)percentage
{
  if (![self isAnimating]) {
    self.cycleLayer.transform = CATransform3DMakeScale(percentage, percentage, 0.0);
  }
}

- (void)pauseLayers
{
  [self.cycleLayer removeAnimationForKey:JY_ANIMATION_KEY];
}

- (void)resumeLayers
{
  NSTimeInterval beginTime = CACurrentMediaTime();

  self.cycleLayer.opacity = 1;
  self.cycleLayer.transform = CATransform3DMakeScale(1.0, 1.0, 0.0);

  CAKeyframeAnimation *scaleAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
  scaleAnim.values = @[
                       [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 0.0)],
                       [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.2, 0.2, 0.0)],
                       [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 0.0)],
                       ];

  CAKeyframeAnimation *opacityAnim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
  opacityAnim.values = @[@(1.0), @(0.0), @(1.0)];

  CAAnimationGroup *animGroup = [CAAnimationGroup animation];
  animGroup.removedOnCompletion = NO;
  animGroup.beginTime = beginTime;
  animGroup.repeatCount = HUGE_VALF;
  animGroup.duration = 1.0;
  animGroup.animations = @[scaleAnim, opacityAnim];
  animGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

  [self.cycleLayer addAnimation:animGroup forKey:JY_ANIMATION_KEY];
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
