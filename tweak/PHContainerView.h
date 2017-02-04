#import "Headers.h"
#import "PHAppView.h"

extern CGSize appViewSize();
extern UIImage* iconForIdentifier(NSString* identifier);

@interface PHContainerView : UIScrollView {
	UIView *selectedView;
	NSUserDefaults *defaults;
	NSMutableDictionary *appViews;
}

@property (nonatomic, copy) NSString* selectedAppID;
@property (nonatomic, copy) void (^updateNotificationTableView)();
@property (nonatomic, copy) NSDictionary* (^getCurrentNotifications)();

- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif;
- (void)updateView;

@end