//
//  DemoViewController.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "DemoViewController.h"
#import "JYPullToRefreshController.h"
#import "JYPullToLoadMoreController.h"

@interface DemoViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic ,strong) JYPullToRefreshController *refreshController;
@property (nonatomic ,strong) JYPullToLoadMoreController *loadMoreController;
@end

@implementation DemoViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self configureDataSource];
  [self configureScollView];
  [self configureNavigationItems];
  [self configureRefreshController];
}

#pragma mark - Property
- (NSMutableArray *)dataSource
{
  if (!_dataSource) {
    _dataSource = [NSMutableArray array];
  }
  return _dataSource;
}

#pragma mark - Configure
- (void)configureScollView
{
  self.tableView.delegate = self;
  self.tableView.dataSource = self;

  /**
   * // For testing custom contentInset to uncommon the below line
   * self.scrollView.contentInset = UIEdgeInsetsMake(100, 0, 100, 0);
   */
}

- (void)configureRefreshController
{
  __weak typeof(self) weakSelf = self;
  self.refreshController = [[JYPullToRefreshController alloc] initWithScrollView:self.tableView];
  self.refreshController.pullToRefreshHandleAction = ^{
    [weakSelf insertRowAtTop];
  };

  self.loadMoreController = [[JYPullToLoadMoreController alloc] initWithScrollView:self.tableView];
  self.loadMoreController.pullToLoadMoreHandleAction = ^{
    [weakSelf insertRowAtBottom];
  };
}

- (void)configureNavigationItems
{
  UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithTitle:@"Refresh"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(startRefresh:)];


  self.navigationItem.leftBarButtonItem = refreshItem;

  UIBarButtonItem *loadMoreItem = [[UIBarButtonItem alloc] initWithTitle:@"LoadMore"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(startLoadMore:)];

  self.navigationItem.rightBarButtonItem = loadMoreItem;

  /**
   * // For testing hidden navigationBar to uncommon the below line
   * self.navigationController.navigationBarHidden = YES;
   */
}

- (void)configureDataSource
{
  for(int i = 0; i < 15; i++) {
    [self.dataSource addObject:[NSDate dateWithTimeIntervalSinceNow:-(i * 90)]];
  }
}

#pragma mark - Refresh methods
- (void)startRefresh:(id)sender
{
  [self.refreshController triggerRefreshWithAnimated:YES];
}

- (void)startLoadMore:(id)sender
{

  [self.loadMoreController triggerLoadMoreWithAnimated:YES];
}

#pragma mark - Actions
- (void)insertRowAtTop
{
  __weak typeof(self) weakSelf = self;

  int64_t delayInSeconds = 1.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [weakSelf.tableView beginUpdates];
    [weakSelf.dataSource insertObject:[NSDate date] atIndex:0];
    [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationBottom];
    [weakSelf.tableView endUpdates];

    [weakSelf.refreshController stopRefreshWithAnimated:YES completion:NULL];
  });
}


- (void)insertRowAtBottom {
  __weak typeof(self) weakSelf = self;

  int64_t delayInSeconds = 1.0;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [weakSelf.tableView beginUpdates];
    [weakSelf.dataSource addObject:[weakSelf.dataSource.lastObject dateByAddingTimeInterval:-90]];
    [weakSelf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.dataSource.count - 1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationTop];
    [weakSelf.tableView endUpdates];

    [weakSelf.loadMoreController stopLoadMoreCompletion:NULL];
  });
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *identifier = @"Cell";
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];

  if (cell == nil)
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];

  NSDate *date = [self.dataSource objectAtIndex:indexPath.row];
  cell.textLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
  return cell;
}

@end
