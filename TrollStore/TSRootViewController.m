#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#import "TSCleanTrashViewController.h"
#import "TSSettingsListController.h"
#import <TSPresentationDelegate.h>

@implementation TSRootViewController

- (void)loadView {
	[super loadView];

	TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
	appTableVC.title = @"Apps";

	TSCleanTrashViewController* cleanTrashVC = [[TSCleanTrashViewController alloc] init];

	TSSettingsListController* settingsListVC = [[TSSettingsListController alloc] init];
	settingsListVC.title = @"Settings";

	UINavigationController* appNavigationController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
	UINavigationController* cleanTrashNavigationController = [[UINavigationController alloc] initWithRootViewController:cleanTrashVC];
	UINavigationController* settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsListVC];

	appNavigationController.navigationBar.prefersLargeTitles = YES;
	appTableVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

	cleanTrashNavigationController.navigationBar.prefersLargeTitles = YES;
	cleanTrashVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

	settingsNavigationController.navigationBar.prefersLargeTitles = YES;
	settingsListVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;

	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.grid.2x2.fill"];
	cleanTrashNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"trash.fill"];
	settingsNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"gear"];

	self.title = @"Root View Controller";
	self.viewControllers = @[appNavigationController, cleanTrashNavigationController, settingsNavigationController];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	TSPresentationDelegate.presentationViewController = self;
}

@end
