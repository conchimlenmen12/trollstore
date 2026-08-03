@import Foundation;

@interface TSRemoteAppInfo : NSObject

@property (nonatomic, copy, readonly) NSString* remoteId;
@property (nonatomic, copy, readonly) NSString* name;
@property (nonatomic, copy, readonly) NSString* version;
@property (nonatomic, copy, readonly) NSString* bundleId;
@property (nonatomic, copy, readonly) NSString* iconURLString;
@property (nonatomic, copy, readonly) NSString* downloadURLString;
@property (nonatomic, copy, readonly) NSString* updatedAtString;

+ (instancetype)infoWithDictionary:(NSDictionary*)dict;

@end
