//
//  DemoViewController.m
//  JYRefreshController
//
//  Created by Alvin on 14-6-16.
//
//

#import "DemoViewController.h"
#import "JYPullToRefreshController.h"

@interface DemoViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic ,strong) JYPullToRefreshController *refreshController;
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

  self.scrollView.delegate = self;
  self.scrollView.dataSource = self;
  [self.view addSubview:self.scrollView];
//  self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * 2);
//  self.scrollView.contentInset = UIEdgeInsetsMake(100, 0, 20, 0);
  self.refreshController = [[JYPullToRefreshController alloc] initWithScrollView:self.scrollView];

  UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopLoading:)];
  self.navigationItem.leftBarButtonItem = stopItem;
  UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(startLoading:)];
  self.navigationItem.rightBarButtonItem = refreshItem;

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

- (void)startLoading:(id)sender
{
  [self.refreshController triggerRefreshWithAnimated:YES];
}

- (void)stopLoading:(id)sender
{
  [self.refreshController stopRefreshWithAnimated:YES completion:^{

  }];
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
  cell.textLabel.text = @"test";
  return cell;
}


@end
