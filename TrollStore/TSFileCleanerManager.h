#import <Foundation/Foundation.h>

@interface TSFileCleanerManager : NSObject

+ (instancetype)sharedInstance;

// Each entry: { "name": NSString, "path": NSString, "isDirectory": NSNumber, "size": NSNumber (bytes, 0 for directories) }
- (NSArray<NSDictionary*>*)listDirectoryAtPath:(NSString*)path;

- (int)deleteItemAtPath:(NSString*)path;
- (int)emptyDirectoryAtPath:(NSString*)path;

// Each entry: { "path": NSString, "size": NSNumber (bytes) }
- (NSArray<NSDictionary*>*)scanJunk;

@end
