#import "Headers.h"
#import "PHAppView.h"

extern void updateNotificationTableView();

@interface PHView : UIView {
	UIView *selectedView;
	NSUserDefaults *defaults;
	NSMutableDictionary *appViews;
}

@property (readonly) NSString* selectedAppID;
@property (assign) SBLockScreenNotificationListController *listController;

- (void)updateView;
- (CGSize)appViewSize;
- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif;

@end