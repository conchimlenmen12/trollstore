#import "TSRemoteAppInfo.h"

@implementation TSRemoteAppInfo

+ (instancetype)infoWithDictionary:(NSDictionary*)dict
{
	if(![dict isKindOfClass:NSDictionary.class]) return nil;

	NSString* name = [dict[@"name"] isKindOfClass:NSString.class] ? dict[@"name"] : nil;
	NSString* downloadURLString = [dict[@"downloadURL"] isKindOfClass:NSString.class] ? dict[@"downloadURL"] : nil;
	if(name.length == 0 || downloadURLString.length == 0) return nil;

	TSRemoteAppInfo* info = [TSRemoteAppInfo new];
	info->_remoteId = [dict[@"id"] isKindOfClass:NSString.class] ? dict[@"id"] : @"";
	info->_name = name;
	info->_version = [dict[@"version"] isKindOfClass:NSString.class] ? dict[@"version"] : @"";
	info->_bundleId = [dict[@"bundleId"] isKindOfClass:NSString.class] ? dict[@"bundleId"] : @"";
	info->_iconURLString = [dict[@"iconURL"] isKindOfClass:NSString.class] ? dict[@"iconURL"] : @"";
	info->_downloadURLString = downloadURLString;
	info->_updatedAtString = [dict[@"updatedAt"] isKindOfClass:NSString.class] ? dict[@"updatedAt"] : @"";
	return info;
}

@end
