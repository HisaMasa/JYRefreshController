//
//  DemoViewController.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "DemoViewController.h"
#import "JYRefreshController.h"

@interface DemoViewController () <JYRefreshControlDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic ,strong) JYRefreshController *refreshController;
@end

@implementation DemoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = YES;
//  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.scrollView = [[UITableView alloc] initWithFrame:self.view.bounds];


  self.scrollView.backgroundColor = [UIColor redColor];
  self.scrollView.delegate = self;
  self.scrollView.dataSource = self;
  [self.view addSubview:self.scrollView];
//  self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * 2);
//  self.scrollView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
  self.refreshController = [[JYRefreshController alloc] initWithScrollView:self.scrollView];
  [self.refreshController setCanRefreshDirection:kJYRefreshableDirectionTop | kJYRefreshableDirectionBottom];
  self.refreshController.delegate = self;

  UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopLoading:)];
  self.navigationItem.leftBarButtonItem = revealButtonItem;

//  self.navigationController.navigationBarHidden = YES;

//  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
//  view.backgroundColor = [UIColor whiteColor];
//  [self.scrollView addSubview:view];

  NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_scrollView);

  NSArray *constraints = [NSLayoutConstraint
                          constraintsWithVisualFormat:@"H:|[_scrollView]|"
                          options:0
                          metrics:nil
                          views:viewsDictionary];
  constraints = [constraints arrayByAddingObjectsFromArray:
                 [NSLayoutConstraint
                  constraintsWithVisualFormat:@"V:|[_scrollView]|"
                  options:0
                  metrics:nil
                  views:viewsDictionary]];
  [self.view addConstraints:constraints];

}

- (void)stopLoading:(id)sender
{
  [self.refreshController stopRefreshAtDirection:kJYRefreshDirectionBottom animated:YES completion:^{

  }];
}

- (void)refreshControl:(JYRefreshController *)refreshControl
didShowRefreshViewHeight:(CGFloat)progress
           atDirection:(JYRefreshDirection)direction
{

}

- (BOOL)needAdjustInsets
{
  return NO;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"123"];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"123"];
  }
  cell.textLabel.text = @"wocao";
  return cell;
}


@end
