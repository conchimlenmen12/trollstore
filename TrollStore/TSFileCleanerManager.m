#import "TSFileCleanerManager.h"
#import <TSUtil.h>

@implementation TSFileCleanerManager

+ (instancetype)sharedInstance
{
	static TSFileCleanerManager* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[TSFileCleanerManager alloc] init];
	});
	return sharedInstance;
}

- (NSArray<NSDictionary*>*)listDirectoryAtPath:(NSString*)path
{
	NSString* output = nil;
	spawnRoot(rootHelperPath(), @[@"list-dir", path], &output, nil);

	NSMutableArray* entries = [NSMutableArray new];
	if(!output) return entries;

	for(NSString* line in [output componentsSeparatedByString:@"\n"])
	{
		if(line.length == 0) continue;
		NSArray* parts = [line componentsSeparatedByString:@"\t"];
		if(parts.count < 3) continue;

		BOOL isDirectory = [parts[0] isEqualToString:@"D"];
		long long size = [parts[1] longLongValue];
		NSString* name = parts[2];

		[entries addObject:@{
			@"name": name,
			@"isDirectory": @(isDirectory),
			@"size": @(size),
			@"path": [path stringByAppendingPathComponent:name]
		}];
	}

	[entries sortUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b)
	{
		BOOL aDir = [a[@"isDirectory"] boolValue];
		BOOL bDir = [b[@"isDirectory"] boolValue];
		if(aDir != bDir) return aDir ? NSOrderedAscending : NSOrderedDescending;
		return [a[@"name"] localizedStandardCompare:b[@"name"]];
	}];

	return entries;
}

- (int)deleteItemAtPath:(NSString*)path
{
	return spawnRoot(rootHelperPath(), @[@"delete-path", path], nil, nil);
}

- (int)emptyDirectoryAtPath:(NSString*)path
{
	return spawnRoot(rootHelperPath(), @[@"empty-dir", path], nil, nil);
}

- (NSArray<NSDictionary*>*)scanJunk
{
	NSString* output = nil;
	spawnRoot(rootHelperPath(), @[@"scan-junk"], &output, nil);

	NSMutableArray* results = [NSMutableArray new];
	if(!output) return results;

	for(NSString* line in [output componentsSeparatedByString:@"\n"])
	{
		if(line.length == 0) continue;
		NSArray* parts = [line componentsSeparatedByString:@"\t"];
		if(parts.count < 2) continue;

		long long size = [parts[0] longLongValue];
		NSString* path = parts[1];

		[results addObject:@{ @"path": path, @"size": @(size) }];
	}

	[results sortUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b)
	{
		return [b[@"size"] compare:a[@"size"]];
	}];

	return results;
}

@end
