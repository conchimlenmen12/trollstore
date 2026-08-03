#import "TSPrivateAppTableViewController.h"
#import "TSRemoteAppInfo.h"
#import "TSInstallationController.h"
#import "TSHahaSticker.h"
#import <TSPresentationDelegate.h>
#import <TSUtil.h>

static NSString* const kTSPrivateAppsAPIURLString = @"https://apps.cheatiosvip.net/api/private-apps";
// Per bundle id, the downloadURL that was actually installed last time — lets us tell
// "server entry changed since I installed it" apart from "nothing changed" without
// relying on the admin remembering to bump a version field.
static NSString* const kTSPrivateAppInstalledSourcesDefaultsKey = @"PrivateAppInstalledSourceURLs";

extern NSUserDefaults* trollStoreUserDefaults(void);

// "Cập nhật: dd/MM/yyyy HH:mm" from the server's updatedAt (falls back to addedAt) —
// a fixed point in time, not a running counter, since it's about the catalog entry
// on the server rather than anything happening on this device.
static NSString* updatedAtDisplayStringForISOString(NSString* isoString)
{
	if(isoString.length == 0) return nil;

	static NSISO8601DateFormatter* isoFormatter;
	static NSDateFormatter* displayFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		isoFormatter = [NSISO8601DateFormatter new];
		displayFormatter = [NSDateFormatter new];
		displayFormatter.dateFormat = @"dd/MM/yyyy HH:mm";
	});

	NSDate* date = [isoFormatter dateFromString:isoString];
	if(!date) return nil;

	return [NSString stringWithFormat:@"Cập nhật: %@", [displayFormatter stringFromDate:date]];
}

// Same visual language as TSAppTableViewController's card cell, duplicated under a
// distinct class name since Objective-C classes are linked globally even when the
// @interface is private to a .m file.
@interface TSPrivateAppCardCell : UITableViewCell
- (void)setUpdatedAtText:(NSString*)text;
@end

@implementation TSPrivateAppCardCell
{
	CAShapeLayer* _dashedBorderLayer;
	UILabel* _updatedAtLabel;
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

		_updatedAtLabel = [[UILabel alloc] init];
		_updatedAtLabel.font = [UIFont systemFontOfSize:12];
		_updatedAtLabel.textColor = [UIColor.secondaryLabelColor colorWithAlphaComponent:0.85];
		[self.contentView addSubview:_updatedAtLabel];
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	_dashedBorderLayer.frame = self.bounds;
	_dashedBorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:10].CGPath;

	CGRect detailFrame = self.detailTextLabel.frame;
	CGFloat labelX = self.textLabel.frame.origin.x;
	CGFloat maxWidth = self.contentView.bounds.size.width - labelX - 12;
	_updatedAtLabel.frame = CGRectMake(labelX, CGRectGetMaxY(detailFrame) + 2, MAX(maxWidth, 0), 15);
}

- (void)setUpdatedAtText:(NSString*)text
{
	_updatedAtLabel.hidden = (text.length == 0);
	if(text.length == 0)
	{
		_updatedAtLabel.attributedText = nil;
		return;
	}

	UIImageSymbolConfiguration* symbolConfig = [UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightSemibold];
	UIImage* clockImage = [[UIImage systemImageNamed:@"clock.fill"] imageByApplyingSymbolConfiguration:symbolConfig];
	clockImage = [clockImage imageWithTintColor:UIColor.systemBlueColor renderingMode:UIImageRenderingModeAlwaysOriginal];

	NSTextAttachment* clockAttachment = [[NSTextAttachment alloc] init];
	clockAttachment.image = clockImage;
	CGFloat lineHeight = _updatedAtLabel.font.lineHeight;
	clockAttachment.bounds = CGRectMake(0, (lineHeight - clockImage.size.height) / 2.0 - 1, clockImage.size.width, clockImage.size.height);

	NSMutableAttributedString* result = [[NSAttributedString attributedStringWithAttachment:clockAttachment] mutableCopy];
	[result appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", text]]];
	[result addAttribute:NSFontAttributeName value:_updatedAtLabel.font range:NSMakeRange(0, result.length)];
	[result addAttribute:NSForegroundColorAttributeName value:_updatedAtLabel.textColor range:NSMakeRange(0, result.length)];

	_updatedAtLabel.attributedText = result;
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

	UIBarButtonItem* hahaButton = hahaStickerBarButtonItem(32);
	if(hahaButton) self.navigationItem.rightBarButtonItems = @[hahaButton];

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
	else
	{
		// Cheap local re-check (installed/update state can change while this tab wasn't visible).
		[self.tableView reloadData];
	}
}

// Returns the CFBundleVersion of the installed app with this bundle id, or nil if not installed.
- (NSString*)installedVersionForBundleId:(NSString*)bundleId
{
	if(bundleId.length == 0) return nil;

	LSApplicationProxy* proxy = [LSApplicationProxy applicationProxyForIdentifier:bundleId];
	if(!proxy || !proxy.installed || !proxy.bundleURL) return nil;

	NSBundle* bundle = [NSBundle bundleWithURL:proxy.bundleURL];
	return [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString*)recordedDownloadURLForBundleId:(NSString*)bundleId
{
	if(bundleId.length == 0) return nil;
	NSDictionary* sources = [trollStoreUserDefaults() objectForKey:kTSPrivateAppInstalledSourcesDefaultsKey];
	return [sources isKindOfClass:NSDictionary.class] ? sources[bundleId] : nil;
}

- (void)recordInstalledDownloadURL:(NSString*)downloadURLString forBundleId:(NSString*)bundleId
{
	if(bundleId.length == 0 || downloadURLString.length == 0) return;

	NSUserDefaults* defaults = trollStoreUserDefaults();
	NSMutableDictionary* sources = [([defaults objectForKey:kTSPrivateAppInstalledSourcesDefaultsKey] ?: @{}) mutableCopy];
	sources[bundleId] = downloadURLString;
	[defaults setObject:sources forKey:kTSPrivateAppInstalledSourcesDefaultsKey];
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
	return 94.0f;
}

// Each app is its own section (so the dashed card gets a gap around it); the default
// inset-grouped header/footer height leaves a much wider gap than that needs.
- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
	return section == 0 ? 0.01f : 10.0f;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section
{
	return 0.01f;
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
	[cell setUpdatedAtText:updatedAtDisplayStringForISOString(app.updatedAtString)];
	cell.imageView.layer.borderWidth = 1;
	cell.imageView.layer.borderColor = [UIColor.labelColor colorWithAlphaComponent:0.1].CGColor;
	cell.imageView.layer.cornerRadius = 13.5;
	cell.imageView.layer.masksToBounds = YES;
	cell.imageView.layer.cornerCurve = kCACornerCurveContinuous;

	[self loadIconForApp:app tableView:tableView];
	cell.imageView.image = (app.iconURLString.length && _cachedIcons[app.iconURLString]) ? _cachedIcons[app.iconURLString] : _placeholderIcon;

	UIButton* actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[actionButton setTitle:[self actionTitleForApp:app] forState:UIControlStateNormal];
	actionButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	[actionButton sizeToFit];
	CGRect buttonFrame = actionButton.frame;
	buttonFrame.size.width += 16;
	actionButton.frame = buttonFrame;
	actionButton.tag = indexPath.section;
	[actionButton addTarget:self action:@selector(actionButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	cell.accessoryView = actionButton;

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

// Not installed -> "Cài đặt". Installed and the recorded install source still matches
// the server entry (or we have no record of it, e.g. installed before this tracking
// existed) -> "Mở". Installed but the server's file/link changed since -> "Cập nhật".
- (BOOL)appHasUpdate:(TSRemoteAppInfo*)app
{
	NSString* recordedURL = [self recordedDownloadURLForBundleId:app.bundleId];
	if(recordedURL.length == 0) return NO;
	return ![recordedURL isEqualToString:app.downloadURLString];
}

- (NSString*)actionTitleForApp:(TSRemoteAppInfo*)app
{
	NSString* installedVersion = [self installedVersionForBundleId:app.bundleId];
	if(!installedVersion) return @"Cài đặt";
	if([self appHasUpdate:app]) return @"Cập nhật";
	return @"Mở";
}

- (void)actionButtonTapped:(UIButton*)sender
{
	[self performActionForAppAtIndex:sender.tag];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self performActionForAppAtIndex:indexPath.section];
}

- (void)performActionForAppAtIndex:(NSInteger)index
{
	if(index < 0 || index >= (NSInteger)_apps.count) return;
	TSRemoteAppInfo* app = _apps[index];

	NSString* installedVersion = [self installedVersionForBundleId:app.bundleId];
	if(installedVersion && ![self appHasUpdate:app])
	{
		if(app.bundleId.length)
		{
			[[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:app.bundleId];
		}
		return;
	}

	BOOL isUpdate = installedVersion != nil;

	NSURL* downloadURL = [NSURL URLWithString:app.downloadURLString];
	if(!downloadURL)
	{
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Lỗi" message:@"Link tải app không hợp lệ." preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[TSPresentationDelegate presentViewController:alert animated:YES completion:nil];
		return;
	}

	NSString* message = isUpdate ? @"Tải và cập nhật app này lên bản mới?" : @"Tải và cài đặt app này?";
	UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:app.name message:message preferredStyle:UIAlertControllerStyleAlert];
	[confirmAlert addAction:[UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil]];
	[confirmAlert addAction:[UIAlertAction actionWithTitle:(isUpdate ? @"Cập nhật" : @"Cài đặt") style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
		__weak typeof(self) weakSelf = self;
		[TSInstallationController handleAppInstallFromRemoteURL:downloadURL completion:^(BOOL success, NSError* error) {
			if(success)
			{
				[weakSelf recordInstalledDownloadURL:app.downloadURLString forBundleId:app.bundleId];
				dispatch_async(dispatch_get_main_queue(), ^{
					[weakSelf.tableView reloadData];
				});
			}
		}];
	}]];
	[TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}

@end
