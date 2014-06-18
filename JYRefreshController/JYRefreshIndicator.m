//
//  JYRefreshIndicator.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshIndicator.h"

@interface JYRefreshIndicator ()
@property (nonatomic, assign) BOOL loading;
// Start angle of the cycle, never changed
@property (nonatomic, assign) CGFloat startAngle;
// End angle of the cyclen
@property (nonatomic, assign) CGFloat endAngle;
@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, strong) NSTimer *indicatorTimer;

@end

@implementation JYRefreshIndicator

#pragma mark - init
- (id)init
{
  static CGFloat const defalutSize = 26.0f;
  return [self initWithFrame:CGRectMake(0, 0, defalutSize, defalutSize)];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    [self setBackgroundColor:[UIColor clearColor]];
    [self setIndicatorColor:[UIColor blueColor]];
    self.hidesWhenStop = YES;
    self.loading = NO;
  }
  return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
  if (self.superview
      && newSuperview == nil) {
    [self stopLoading];
  }
}

#pragma mark - Prop

- (void)setLoading:(BOOL)loading
{
  if (self.hidesWhenStop) [self setHidden:!loading];

  _loading = loading;

  _startAngle = -90;
  _endAngle = loading ? 230 : -90;

  [_indicatorTimer invalidate];
  _indicatorTimer = nil;

  if (loading) {
    _indicatorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 33.0f
                                                       target:self
                                                     selector:@selector(_didScrollRefreshIndicator)
                                                     userInfo:nil
                                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_indicatorTimer forMode:NSRunLoopCommonModes];
  }
}

- (void)setIndicatorColor:(UIColor *)color
{
  _indicatorColor = color;
}

- (void)didLoaded:(float)present
{
  present = MAX(present, 0.0f);
  present = MIN(present, 1.0f);

  if (self.hidesWhenStop) [self setHidden:!(present > 0.0f)];

  _startAngle = -90;
  _endAngle = -90 + 320.0f * present;

  [self setNeedsDisplay];
}

#pragma mark - start & stop

- (void)startLoading
{
  if (!self.loading) {
    self.loading = YES;
  }
}

- (void)stopLoading
{
  if (self.loading) {
    self.loading = NO;
  }
}

#pragma mark - draw

- (void)drawRect:(CGRect)rect
{
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  CGContextSaveGState(ctx);

  CGContextSetShouldAntialias(ctx, YES);
  CGContextSetAllowsAntialiasing(ctx, YES);

  CGContextBeginPath(ctx);

  CGContextSetStrokeColorWithColor(ctx, _indicatorColor.CGColor);
  CGContextSetLineWidth(ctx, 1);
  CGContextAddArc(ctx,
                  CGRectGetMidX(self.bounds),
                  CGRectGetMidY(self.bounds),
                  [self _indicatorRadius],
                  Degree2Radian(_startAngle),
                  Degree2Radian(_endAngle),
                  NO);
  CGContextDrawPath(ctx, kCGPathStroke);

  CGContextRestoreGState(ctx);
}

#pragma mark - Util

- (void)_didScrollRefreshIndicator
{
  float deltaAngle = Radian2Degree(1 / [self _indicatorRadius]);
  _endAngle += deltaAngle;

  if (_endAngle >= 230) {
    _startAngle = _endAngle - 230 - 90;
  }

  [self setNeedsDisplay];
}

- (CGFloat)_indicatorRadius
{
  return MIN(self.bounds.size.height - 10, self.bounds.size.width - 10) / 2.0;
}

float Radian2Degree(float radian) {
  return ((radian / M_PI) * 180.0f);
}

float Degree2Radian(float degree) {
  return ((degree / 180.0f) * M_PI);
}

@end
