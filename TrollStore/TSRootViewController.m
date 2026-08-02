#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#import "TSSettingsListController.h"
#import <TSPresentationDelegate.h>

@implementation TSRootViewController

- (void)loadView {
	[super loadView];

	TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
	appTableVC.title = @"Apps";

	TSSettingsListController* settingsListVC = [[TSSettingsListController alloc] init];
	settingsListVC.title = @"Settings";

	UINavigationController* appNavigationController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
	UINavigationController* settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsListVC];

	appNavigationController.navigationBar.prefersLargeTitles = YES;
	appTableVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

	settingsNavigationController.navigationBar.prefersLargeTitles = YES;
	settingsListVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.grid.2x2.fill"];
	settingsNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"gear"];

	self.title = @"Root View Controller";
	self.viewControllers = @[appNavigationController, settingsNavigationController];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	TSPresentationDelegate.presentationViewController = self;
}

@end
