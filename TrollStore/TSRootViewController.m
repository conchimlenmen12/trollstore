#import "TSRootViewController.h"
#import "TSAppTableViewController.h"
#import "TSCleanTrashViewController.h"
#import "TSSettingsListController.h"
#import "TSPrivateAppTableViewController.h"
#import "TSAnnouncementViewController.h"
#import <TSPresentationDelegate.h>

static NSString* const kTSAnnouncementConfigURLString = @"https://apps.cheatiosvip.net/api/announcement";

@implementation TSRootViewController
{
	BOOL _hasShownAnnouncement;
}

- (void)loadView {
	[super loadView];

	TSAppTableViewController* appTableVC = [[TSAppTableViewController alloc] init];
	appTableVC.title = @"Apps";

	TSCleanTrashViewController* cleanTrashVC = [[TSCleanTrashViewController alloc] init];

	TSSettingsListController* settingsListVC = [[TSSettingsListController alloc] init];
	settingsListVC.title = @"Settings";

	TSPrivateAppTableViewController* privateAppVC = [[TSPrivateAppTableViewController alloc] init];
	privateAppVC.title = @"Private App";

	UINavigationController* appNavigationController = [[UINavigationController alloc] initWithRootViewController:appTableVC];
	UINavigationController* cleanTrashNavigationController = [[UINavigationController alloc] initWithRootViewController:cleanTrashVC];
	UINavigationController* privateAppNavigationController = [[UINavigationController alloc] initWithRootViewController:privateAppVC];
	UINavigationController* settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsListVC];

	appTableVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	cleanTrashVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	privateAppVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
	settingsListVC.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

	UIImage* cleanTrashIcon = [UIImage systemImageNamed:@"archivebox.fill"];

	appNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"square.grid.2x2.fill"];
	cleanTrashNavigationController.tabBarItem.image = cleanTrashIcon;
	privateAppNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"lock.shield.fill"];
	settingsNavigationController.tabBarItem.image = [UIImage systemImageNamed:@"gear"];

	self.title = @"Root View Controller";
	self.viewControllers = @[appNavigationController, cleanTrashNavigationController, privateAppNavigationController, settingsNavigationController];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	TSPresentationDelegate.presentationViewController = self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	if(!_hasShownAnnouncement)
	{
		_hasShownAnnouncement = YES;
		[self fetchAnnouncementConfigAndPresent];
	}
}

- (void)fetchAnnouncementConfigAndPresent
{
	NSURL* configURL = [NSURL URLWithString:kTSAnnouncementConfigURLString];

	NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	sessionConfig.timeoutIntervalForRequest = 6.0;
	sessionConfig.timeoutIntervalForResource = 6.0;
	NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig];

	__weak typeof(self) weakSelf = self;
	NSURLSessionDataTask* task = [session dataTaskWithURL:configURL completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		NSDictionary* config = nil;
		if(data && !error)
		{
			id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			if([parsed isKindOfClass:NSDictionary.class])
			{
				config = (NSDictionary*)parsed;
			}
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf presentAnnouncementWithConfig:config];
		});
	}];
	[task resume];
}

// config is nil when the server couldn't be reached in time; TSAnnouncementViewController
// falls back to its own baked-in defaults for any property left unset.
- (void)presentAnnouncementWithConfig:(NSDictionary*)config
{
	if([config[@"enabled"] isKindOfClass:NSNumber.class] && ![config[@"enabled"] boolValue])
	{
		return;
	}

	TSAnnouncementViewController* announcementVC = [[TSAnnouncementViewController alloc] init];

	if([config[@"title"] isKindOfClass:NSString.class]) announcementVC.announcementTitle = config[@"title"];
	if([config[@"subtitle"] isKindOfClass:NSString.class]) announcementVC.announcementSubtitle = config[@"subtitle"];
	if([config[@"linkText"] isKindOfClass:NSString.class]) announcementVC.linkText = config[@"linkText"];
	if([config[@"linkURL"] isKindOfClass:NSString.class]) announcementVC.linkURLString = config[@"linkURL"];
	if([config[@"closeText"] isKindOfClass:NSString.class]) announcementVC.closeButtonText = config[@"closeText"];
	if([config[@"maintenance"] isKindOfClass:NSNumber.class]) announcementVC.maintenanceMode = [config[@"maintenance"] boolValue];
	if([config[@"maintenanceReason"] isKindOfClass:NSString.class]) announcementVC.maintenanceReason = config[@"maintenanceReason"];

	announcementVC.modalPresentationStyle = UIModalPresentationPageSheet;
	[self presentViewController:announcementVC animated:YES completion:nil];
}

@end
