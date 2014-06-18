//
//  JYRefreshView.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "JYRefreshView.h"

@interface JYRefreshView ()

@property (nonatomic, assign) JYRefreshState refreshState;
@property (nonatomic, strong) NSMutableDictionary *titles;
@property (nonatomic, strong) NSMutableDictionary *subTitles;

@end

@implementation JYRefreshView
@synthesize refreshIndicator = _refreshIndicator;
@synthesize titleLabel = _titleLabel;
@synthesize subTitleLabel = _subTitleLabel;
@synthesize visible = _visible;


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    _refreshState = kJYRefreshStateStop;
    _titles = [NSMutableDictionary dictionary];
    _subTitles = [NSMutableDictionary dictionary];
  }
  return self;
}

#pragma mark - layout

- (void)layoutSubviews
{
  [super layoutSubviews];
//  CGSize titleSize = [self.titleLabel sizeThatFits:self.bounds.size];
//  CGSize subTitleSize = [self.subTitleLabel sizeThatFits:self.bounds.size];
//
//  [self.titleLabel setFrameSize:titleSize];
//  [self.subTitleLabel setFrameSize:subTitleSize];
  [self.titleLabel sizeToFit];
  [self.subTitleLabel sizeToFit];

  CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  [self.titleLabel setCenter:CGPointMake(boundsCenter.x,
                                         boundsCenter.y - CGRectGetMidY(self.subTitleLabel.bounds))];
  [self.subTitleLabel setCenter:CGPointMake(boundsCenter.x,
                                            boundsCenter.y - CGRectGetMidY(self.titleLabel.bounds))];

  CGFloat titleMaxWidth = MAX(self.titleLabel.frame.size.width, self.subTitleLabel.frame.size.width);
  CGFloat indicatorOffsetX =  (titleMaxWidth > 0) ? titleMaxWidth / 2  + CGRectGetMidX(self.refreshIndicator.bounds) + 8 : 0.0f;
  [self.refreshIndicator setCenter:CGPointMake(boundsCenter.x - indicatorOffsetX,
                                               boundsCenter.y)];
}

- (void)layoutSubviewsForRefreshState:(JYRefreshState)refreshState
{
  _refreshState = refreshState;
  [self.titleLabel setText:[_titles objectForKey:@(refreshState)]];
  [self.subTitleLabel setText:[_subTitles objectForKey:@(refreshState)]];
  switch (refreshState) {
    case kJYRefreshStateStop:
      [self.refreshIndicator stopAnimating];
      break;

    case kJYRefreshStateLoading:
      [self.refreshIndicator startAnimating];
      break;

    default:
      break;
  }
  [self setNeedsLayout];
}

#pragma mark - getter

- (RTSpinKitView *)refreshIndicator
{
  if (!_refreshIndicator) {
    RTSpinKitView *indicator = [[RTSpinKitView alloc] initWithStyle:RTSpinKitViewStyleWave
                                                              color:[UIColor whiteColor]];
    indicator.hidden = NO;
    [self addSubview:indicator];
    _refreshIndicator = indicator;
  }
  return _refreshIndicator;
}

- (UILabel *)titleLabel
{
  if (!_titleLabel) {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:titleLabel];
    _titleLabel = titleLabel;
  }
  return _titleLabel;
}

- (UILabel *)subTitleLabel
{
  if (!_subTitleLabel) {
    UILabel *subTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [subTitleLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [subTitleLabel setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:subTitleLabel];
    _subTitleLabel = subTitleLabel;
  }
  return _subTitleLabel;
}

#pragma mark - setter
- (void)setVisible:(BOOL)visible
{
  _visible = visible;
  if (visible) {
    self.hidden = NO;
    self.refreshIndicator.hidden = NO;
  } else {
    self.hidden = YES;
    self.refreshIndicator.hidden = YES;
  }
}

- (void)setTitle:(NSString *)title forRefreshState:(JYRefreshState)refreshState
{
  [_titles setObject:title forKey:@(refreshState)];
  if (_refreshState == refreshState) {
    [self.titleLabel setText:title];
    [self setNeedsLayout];
  }
}

- (void)setSubTitle:(NSString *)subTitle forRefreshState:(JYRefreshState)refreshState
{
  [_subTitles setObject:subTitle forKey:@(refreshState)];
  if (_refreshState == refreshState) {
    [self.subTitleLabel setText:subTitle];
    [self setNeedsLayout];
  }
}

@end
