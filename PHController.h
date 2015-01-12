#import <UIKit/UIKit.h>
#import "PHAppsScrollView.h"
#import "Headers.h"

@interface PHController : NSObject

@property NSUserDefaults *prefsDict;
@property PHAppsScrollView *appsScrollView;
@property (weak) BBObserver *bulletinObserver;
@property (weak) SBLockScreenNotificationListController *listController;
@property (weak) SBLockScreenNotificationListView *listView;
@property (weak) UITableView *notificationsTableView;

+ (PHController*)sharedInstance;
- (id)init;

- (void)addNotificationForAppID:(NSString*)appID;
- (void)removeNotificationForAppID:(NSString*)appID;
- (void)clearAllNotificationsForUnlock;
- (void)pullToClearTriggered;

- (NSInteger)numNotificationsForAppID:(NSString*)appID;
- (void)updatePrefsDict;
+ (UIImage*)iconForAppID:(NSString*)appID;
+ (CGFloat)iconSize;
+ (BOOL)isTweakInstalled:(NSString*)name;

@end