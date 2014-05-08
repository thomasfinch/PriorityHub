#import <Foundation/Foundation.h>

@interface PHController : NSObject
{
    NSBundle *iconsBundle;
    NSMutableDictionary *appViewsDict;
    UIView *selectedView;
    UITableView* notificationsTableView;
}

@property (nonatomic, readonly) NSMutableDictionary *prefsDict;
@property (nonatomic, readonly) UIScrollView *appListView;
@property (nonatomic, readonly) NSString *curAppID;

- (id)init;

- (float)iconSize;
- (float)viewWidth;
- (float)viewHeight;

- (void)updatePrefsDict;
- (BOOL)isTweakInstalled:(NSString *)name;
- (UIImage *)iconForAppID:(NSString *)appID;

- (void)layoutSubviews;
- (void)selectAppID:(NSString*)appId;
- (void)addNotificationForAppID:(NSString *)appId;
- (void)removeNotificationForAppID:(NSString *)appId;
- (void)removeAllNotificationsForAppID:(NSString *)appId;
- (void)removeAllNotifications;

@end