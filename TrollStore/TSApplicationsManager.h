#import <Foundation/Foundation.h>

#define TROLLSTORE_ROOT_PATH @"/var/containers/Bundle/TrollStore"
#define TROLLSTORE_MAIN_PATH [TROLLSTORE_ROOT_PATH stringByAppendingPathComponent:@"Main"]
#define TROLLSTORE_APPLICATIONS_PATH [TROLLSTORE_ROOT_PATH stringByAppendingPathComponent:@"Applications"]

// NSUserDefaults key for a dictionary mapping bundle identifier -> "ipa"/"tipa",
// recording which kind of file each installed app was installed from.
extern NSString* const TSAppInstallSourceTypesDefaultsKey;

@interface TSApplicationsManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray*)installedAppPaths;

- (NSError*)errorForCode:(int)code;
- (int)installIpa:(NSString*)pathToIpa force:(BOOL)force log:(NSString**)logOut;
- (int)installIpa:(NSString*)pathToIpa;
- (int)uninstallApp:(NSString*)appId;
- (int)uninstallAppByPath:(NSString*)path;
- (BOOL)openApplicationWithBundleID:(NSString *)appID;
- (int)enableJITForBundleID:(NSString *)appID;
- (int)changeAppRegistration:(NSString*)appPath toState:(NSString*)newState;

@end