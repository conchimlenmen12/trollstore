#import "TSPrivateAppTableViewController.h"
#import "TSRemoteAppInfo.h"
#import "TSInstallationController.h"
#import <TSPresentationDelegate.h>

static NSString* const kTSPrivateAppsAPIURLString = @"https://apps.cheatiosvip.net/api/private-apps";

// Same visual language as TSAppTableViewController's card cell, duplicated under a
// distinct class name since Objective-C classes are linked globally even when the
// @interface is private to a .m file.
@interface TSPrivateAppCardCell : UITableViewCell
@end

@implementation TSPrivateAppCardCell
{
	CAShapeLayer* _dashedBorderLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if(self)
	{
		self.backgroundColor = UIColor.clearColor;
		self.contentView.backgroundColor = UIColor.clearColor;

		UIBlurEffect* glassEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
		UIVisualEffectView* glassView = [[UIVisualEffectView alloc] initWithEffect:glassEffect];
		glassView.layer.cornerRadius = 10;
		glassView.layer.cornerCurve = kCACornerCurveContinuous;
		glassView.layer.masksToBounds = YES;
		self.backgroundView = glassView;

		_dashedBorderLayer = [CAShapeLayer layer];
		_dashedBorderLayer.fillColor = UIColor.clearColor.CGColor;
		_dashedBorderLayer.strokeColor = [UIColor.labelColor colorWithAlphaComponent:0.3].CGColor;
		_dashedBorderLayer.lineWidth = 1.5;
		_dashedBorderLayer.lineDashPattern = @[@5, @4];
		[self.layer addSublayer:_dashedBorderLayer];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	_dashedBorderLayer.frame = self.bounds;
	_dashedBorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10].CGPath;
}

@end

@implementation TSPrivateAppTableViewController
{
	NSArray<TSRemoteAppInfo*>* _apps;
	NSMutableDictionary<NSString*, UIImage*>* _cachedIcons;
	UIImage* _placeholderIcon;
	UIRefreshControl* _refreshControl;
	BOOL _isLoading;
}

- (instancetype)init
{
	self = [super initWithStyle:UITableViewStyleInsetGrouped];
	if(self)
	{
		_apps = @[];
		_cachedIcons = [NSMutableDictionary new];
		_placeholderIcon = [UIImage systemImageNamed:@"shippingbox.fill"];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.title = @"Private App";

	_refreshControl = [[UIRefreshControl alloc] init];
	[_refreshControl addTarget:self action:@selector(refreshPulled) forControlEvents:UIControlEventValueChanged];
	self.tableView.refreshControl = _refreshControl;

	[self fetchApps];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	if(_apps.count == 0 && !_isLoading)
	{
		[self fetchApps];
	}
}

- (void)refreshPulled
{
	[self fetchApps];
}

- (void)fetchApps
{
	_isLoading = YES;

	NSURL* url = [NSURL URLWithString:kTSPrivateAppsAPIURLString];

	NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
	sessionConfig.timeoutIntervalForRequest = 10.0;
	sessionConfig.timeoutIntervalForResource = 10.0;
	NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig];

	__weak typeof(self) weakSelf = self;
	NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		NSMutableArray<TSRemoteAppInfo*>* apps = [NSMutableArray new];
		NSError* fetchError = error;

		if(data && !error)
		{
			id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			if([parsed isKindOfClass:NSArray.class])
			{
				for(id item in (NSArray*)parsed)
				{
					TSRemoteAppInfo* info = [TSRemoteAppInfo infoWithDictionary:item];
					if(info) [apps addObject:info];
				}
			}
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf handleFetchedApps:apps error:fetchError];
		});
	}];
	[task resume];
}

- (void)handleFetchedApps:(NSArray<TSRemoteAppInfo*>*)apps error:(NSError*)error
{
	_isLoading = NO;
	[_refreshControl endRefreshing];

	_apps = apps;
	[self.tableView reloadData];

	if(apps.count == 0)
	{
		UILabel* emptyLabel = [[UILabel alloc] init];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.numberOfLines = 0;
		emptyLabel.textColor = UIColor.secondaryLabelColor;
		emptyLabel.font = [UIFont systemFontOfSize:15];
		emptyLabel.text = error ? @"Không tải được danh sách app.\nKéo xuống để thử lại." : @"Chưa có app nào.";
		self.tableView.backgroundView = emptyLabel;
	}
	else
	{
		self.tableView.backgroundView = nil;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return _apps.count;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return 80.0f;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	TSPrivateAppCardCell* cell = (TSPrivateAppCardCell*)[tableView dequeueReusableCellWithIdentifier:@"PrivateAppCell"];
	if(!cell)
	{
		cell = [[TSPrivateAppCardCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"PrivateAppCell"];
	}

	if(indexPath.section >= (NSInteger)_apps.count) return cell;

	TSRemoteAppInfo* app = _apps[indexPath.section];

	cell.textLabel.text = app.name;
	cell.detailTextLabel.text = app.bundleId.length ? [NSString stringWithFormat:@"%@ • %@", app.version, app.bundleId] : app.version;
	cell.imageView.layer.borderWidth = 1;
	cell.imageView.layer.borderColor = [UIColor.labelColor colorWithAlphaComponent:0.1].CGColor;
	cell.imageView.layer.cornerRadius = 13.5;
	cell.imageView.layer.masksToBounds = YES;
	cell.imageView.layer.cornerCurve = kCACornerCurveContinuous;

	[self loadIconForApp:app tableView:tableView];
	cell.imageView.image = (app.iconURLString.length && _cachedIcons[app.iconURLString]) ? _cachedIcons[app.iconURLString] : _placeholderIcon;

	UIButton* installButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[installButton setTitle:@"Cài đặt" forState:UIControlStateNormal];
	installButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	[installButton sizeToFit];
	CGRect buttonFrame = installButton.frame;
	buttonFrame.size.width += 16;
	installButton.frame = buttonFrame;
	installButton.tag = indexPath.section;
	[installButton addTarget:self action:@selector(installButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	cell.accessoryView = installButton;

	return cell;
}

- (void)loadIconForApp:(TSRemoteAppInfo*)app tableView:(UITableView*)tableView
{
	NSString* iconURLString = app.iconURLString;
	if(iconURLString.length == 0) return;
	if(_cachedIcons[iconURLString]) return;

	NSURL* iconURL = [NSURL URLWithString:iconURLString];
	if(!iconURL) return;

	__weak typeof(self) weakSelf = self;
	NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithURL:iconURL completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
		if(!data || error) return;
		UIImage* image = [UIImage imageWithData:data];
		if(!image) return;

		dispatch_async(dispatch_get_main_queue(), ^{
			typeof(self) strongSelf = weakSelf;
			if(!strongSelf) return;

			strongSelf->_cachedIcons[iconURLString] = image;

			NSUInteger section = [strongSelf->_apps indexOfObject:app];
			if(section == NSNotFound) return;
			NSIndexPath* currentIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
			UITableViewCell* currentCell = [tableView cellForRowAtIndexPath:currentIndexPath];
			if(currentCell)
			{
				currentCell.imageView.image = image;
				[currentCell setNeedsLayout];
			}
		});
	}];
	[task resume];
}

- (void)installButtonTapped:(UIButton*)sender
{
	[self installAppAtIndex:sender.tag];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self installAppAtIndex:indexPath.section];
}

- (void)installAppAtIndex:(NSInteger)index
{
	if(index < 0 || index >= (NSInteger)_apps.count) return;
	TSRemoteAppInfo* app = _apps[index];

	NSURL* downloadURL = [NSURL URLWithString:app.downloadURLString];
	if(!downloadURL)
	{
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Lỗi" message:@"Link tải app không hợp lệ." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[TSPresentationDelegate presentViewController:alert animated:YES completion:nil];
		return;
	}

	UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:app.name message:@"Tải và cài đặt app này?" preferredStyle:UIAlertControllerStyleAlert];
	[confirmAlert addAction:[UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil]];
	[confirmAlert addAction:[UIAlertAction actionWithTitle:@"Cài đặt" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		[TSInstallationController handleAppInstallFromRemoteURL:downloadURL completion:nil];
	}]];
	[TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}

@end
