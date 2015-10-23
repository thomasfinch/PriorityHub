#import "Headers.h"
#import "PHAppView.h"

extern void updateNotificationTableView();
extern NSString* identifierForListItem(SBAwayListItem *listItem);

@interface PHContainerView : UIScrollView {
	UIView *selectedView;
	NSUserDefaults *defaults;
	NSMutableDictionary *appViews;
}

@property (readonly) NSString* selectedAppID;
@property (assign) SBLockScreenNotificationListController *listController;

- (void)updateView;
- (CGFloat)appIconSize;
- (CGSize)appViewSize;
- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif;

@end