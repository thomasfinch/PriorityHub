#import "Headers.h"
#import "PHAppView.h"

extern CGSize appViewSize(BOOL lockscreen);
extern UIImage* iconForIdentifier(NSString* identifier);

@interface PHContainerView : UIScrollView {
	BOOL lockscreen;
	UIView *selectedView;
	NSUserDefaults *defaults;
	NSMutableDictionary *appViews;
}

@property (nonatomic, copy) NSString* selectedAppID;
@property (nonatomic, copy) void (^updateNotificationTableView)();
@property (nonatomic, copy) NSDictionary* (^getCurrentNotifications)();

- (id)init:(BOOL)onLockscreen;
- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif;
- (void)updateView;

@end