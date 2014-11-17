//
//  JYRefreshView.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshView.h"

#define JY_UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@interface JYRefreshView ()

@property (nonatomic, assign) JYRefreshState refreshState;
@property (nonatomic, assign) JYLoadMoreState loadMoreState;

@end

@implementation JYRefreshView
@synthesize refreshIndicator = _refreshIndicator;


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    _refreshState = kJYRefreshStateStop;
  }
  return self;
}

#pragma mark - layout
- (void)layoutSubviews
{
  [super layoutSubviews];
  CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  [self.refreshIndicator setCenter:boundsCenter];
}

#pragma mark - getter
- (JYRefreshIndicator *)refreshIndicator
{
  if (!_refreshIndicator) {
    JYRefreshIndicator *indicator = [[JYRefreshIndicator alloc] initWithColor:JY_UIColorFromRGB(0x007AFF)];
    indicator.hidden = NO;
    [self addSubview:indicator];
    _refreshIndicator = indicator;
  }
  return _refreshIndicator;
}

#pragma mark - JYRefreshView Protocol
- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
   didShowRefreshViewPercentage:(CGFloat)percentage
{
  [self.refreshIndicator setPercentage:percentage];
}

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
                   didSetEnable:(BOOL)enable
{
  if (!enable) {
    [self.refreshIndicator stopAnimating];
  }
}

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController
               didChangeToState:(JYRefreshState)refreshState;
{
  _refreshState = refreshState;
  switch (refreshState) {
    case kJYRefreshStateStop:
      NSLog(@"stop");
      [self.refreshIndicator stopAnimating];
      break;

    case kJYRefreshStateLoading:
      NSLog(@"start");
      [self.refreshIndicator startAnimating];
      break;

    default:
      break;
  }
  [self layoutIfNeeded];
}

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
                didChangeToState:(JYLoadMoreState)loadMoreState
{

  _loadMoreState = loadMoreState;
  switch (loadMoreState) {
    case kJYLoadMoreStateStop:
      [self.refreshIndicator stopAnimating];
      break;

    case kJYLoadMoreStateLoading:
      [self.refreshIndicator startAnimating];
      break;

    default:
      break;
  }
  [self layoutIfNeeded];
}

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
    didShowRefreshViewPercentage:(CGFloat)percentage
{
  [self.refreshIndicator setPercentage:percentage];
}

- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
                    didSetEnable:(BOOL)enable
{
  if (!enable) {
    [self.refreshIndicator stopAnimating];
  }
}

@end
