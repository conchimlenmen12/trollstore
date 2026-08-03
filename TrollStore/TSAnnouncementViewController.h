#import <UIKit/UIKit.h>

@interface TSAnnouncementViewController : UIViewController

@property (nonatomic, copy) NSString* announcementTitle;
@property (nonatomic, copy) NSString* announcementSubtitle;
@property (nonatomic, copy) NSString* linkText;
@property (nonatomic, copy) NSString* linkURLString;
@property (nonatomic, copy) NSString* closeButtonText;
@property (nonatomic) BOOL maintenanceMode;
@property (nonatomic, copy) NSString* maintenanceReason;

@end
