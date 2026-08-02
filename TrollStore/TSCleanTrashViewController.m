#import "TSCleanTrashViewController.h"
#import "TSFileCleanerManager.h"
#import <TSPresentationDelegate.h>

@interface TSCleanTrashViewController ()
{
	NSString* _path;
	NSArray<NSDictionary*>* _entries;
}
@end

@implementation TSCleanTrashViewController

- (instancetype)initWithPath:(NSString*)path
{
	self = [super initWithStyle:UITableViewStyleInsetGrouped];
	if(self)
	{
		_path = path ?: @"/var";
		_entries = @[];
		self.title = [_path isEqualToString:@"/var"] ? @"Clean Up Trash" : _path.lastPathComponent;
	}
	return self;
}

- (instancetype)init
{
	return [self initWithPath:@"/var"];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

	UIBarButtonItem* scanButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"] style:UIBarButtonItemStylePlain target:self action:@selector(scanJunkPressed)];
	self.navigationItem.rightBarButtonItem = scanButton;

	[self reloadEntries];
}

- (void)reloadEntries
{
	NSString* path = _path;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		NSArray* entries = [[TSFileCleanerManager sharedInstance] listDirectoryAtPath:path];
		dispatch_async(dispatch_get_main_queue(), ^
		{
			if(![path isEqualToString:self->_path]) return;
			self->_entries = entries;
			[self.tableView reloadData];
		});
	});
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _entries.count;
}

- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	return 60.0f;
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"FileCell"];
	if(!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FileCell"];
	}

	NSDictionary* entry = _entries[indexPath.row];
	BOOL isDirectory = [entry[@"isDirectory"] boolValue];

	cell.textLabel.text = entry[@"name"];
	cell.imageView.image = [UIImage systemImageNamed:isDirectory ? @"folder.fill" : @"doc.fill"];
	cell.imageView.tintColor = isDirectory ? UIColor.systemYellowColor : UIColor.secondaryLabelColor;

	if(isDirectory)
	{
		cell.detailTextLabel.text = @"Thư mục";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else
	{
		long long size = [entry[@"size"] longLongValue];
		cell.detailTextLabel.text = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	return cell;
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	NSDictionary* entry = _entries[indexPath.row];
	if([entry[@"isDirectory"] boolValue])
	{
		TSCleanTrashViewController* nextVC = [[TSCleanTrashViewController alloc] initWithPath:entry[@"path"]];
		[self.navigationController pushViewController:nextVC animated:YES];
	}
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
	return YES;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self confirmDeleteEntryAtIndexPath:indexPath];
	}
}

- (void)confirmDeleteEntryAtIndexPath:(NSIndexPath*)indexPath
{
	NSDictionary* entry = _entries[indexPath.row];
	NSString* name = entry[@"name"];
	NSString* path = entry[@"path"];

	UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"Xác nhận xoá" message:[NSString stringWithFormat:@"Xoá \"%@\"? Hành động này không thể hoàn tác.", name] preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:@"Xoá" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			[[TSFileCleanerManager sharedInstance] deleteItemAtPath:path];
			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self reloadEntries];
			});
		});
	}];
	[confirmAlert addAction:deleteAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil];
	[confirmAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}

#pragma mark - Junk scan

- (void)scanJunkPressed
{
	[TSPresentationDelegate startActivity:@"Đang quét rác"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		NSArray* junkResults = [[TSFileCleanerManager sharedInstance] scanJunk];
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:^
			{
				[self presentJunkResults:junkResults];
			}];
		});
	});
}

- (void)presentJunkResults:(NSArray<NSDictionary*>*)junkResults
{
	NSArray* nonEmpty = [junkResults filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary* entry, NSDictionary* bindings)
	{
		return [entry[@"size"] longLongValue] > 0;
	}]];

	if(nonEmpty.count == 0)
	{
		UIAlertController* cleanAlert = [UIAlertController alertControllerWithTitle:@"Không có rác" message:@"Không tìm thấy tệp rác hoặc tệp nguy hiểm nào cần dọn." preferredStyle:UIAlertControllerStyleAlert];
		[cleanAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[TSPresentationDelegate presentViewController:cleanAlert animated:YES completion:nil];
		return;
	}

	long long totalSize = 0;
	NSMutableString* message = [NSMutableString new];
	for(NSDictionary* entry in nonEmpty)
	{
		long long size = [entry[@"size"] longLongValue];
		totalSize += size;
		[message appendFormat:@"%@ — %@\n", entry[@"path"], [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile]];
	}
	[message appendFormat:@"\nTổng cộng: %@", [NSByteCountFormatter stringFromByteCount:totalSize countStyle:NSByteCountFormatterCountStyleFile]];

	UIAlertController* resultsAlert = [UIAlertController alertControllerWithTitle:@"Rác & tệp nguy hiểm tìm thấy" message:message preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* deleteAllAction = [UIAlertAction actionWithTitle:@"Xoá tất cả" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		[self deleteJunkResults:nonEmpty];
	}];
	[resultsAlert addAction:deleteAllAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil];
	[resultsAlert addAction:cancelAction];

	[TSPresentationDelegate presentViewController:resultsAlert animated:YES completion:nil];
}

- (void)deleteJunkResults:(NSArray<NSDictionary*>*)junkResults
{
	[TSPresentationDelegate startActivity:@"Đang dọn rác"];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		for(NSDictionary* entry in junkResults)
		{
			[[TSFileCleanerManager sharedInstance] emptyDirectoryAtPath:entry[@"path"]];
		}
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[TSPresentationDelegate stopActivityWithCompletion:^
			{
				[self reloadEntries];
			}];
		});
	});
}

@end
