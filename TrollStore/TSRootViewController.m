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

	appTableVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	cleanTrashVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	settingsListVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

	// broom(.fill) was only added in SF Symbols 4 / iOS 16, fall back to the trash icon on older versions
	UIImage* cleanTrashIcon = [UIImage systemImageNamed:@"broom.fill"] ?: [UIImage systemImageNamed:@"trash.circle.fill"];

	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.grid.2x2.fill"];
	cleanTrashNavigationController.tabBarItem.image = cleanTrashIcon;
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
