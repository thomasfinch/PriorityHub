#import <UIKit/UIKit.h>
#import "PHAppsScrollView.h"
#import "Headers.h"

@interface PHController : NSObject {
	const NSString *kPrefsPath;

}

@property NSDictionary *prefsDict;
@property PHAppsScrollView *appsScrollView;
@property (weak) BBObserver *bulletinObserver;
@property (weak) SBLockScreenNotificationListController *listController;

+ (PHController*)sharedInstance;
- (id)init;
- (void)addNotificationForAppID:(NSString*)appID;
- (void)removeNotificationForAppID:(NSString*)appID;
- (void)clearNotificationsForAppID:(NSString*)appID;
- (NSInteger)numNotificationsForAppID:(NSString*)appID;
- (void)updatePrefsDict;
- (UIImage*)iconForAppID:(NSString*)appID;
- (CGFloat)iconSize;
- (BOOL)isTweakInstalled:(NSString*)name;

@end