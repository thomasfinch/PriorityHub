#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCallCenter.h>

@interface PHController : NSObject
{
    NSMutableDictionary *appViewsDict;
    UIView *selectedView;
    UITableView* notificationsTableView;
    CTCallCenter *callCenter;
}

@property (nonatomic, readonly) BOOL enableBlurs;
@property (nonatomic, readonly) BOOL appSelected;
@property (nonatomic, readonly) BOOL showSeparators;
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
- (void)selectAppID:(NSString*)appID;
- (void)addNotificationForAppID:(NSString *)appID;
- (void)removeNotificationForAppID:(NSString *)appID;
- (void)removeAllNotificationsForAppID:(NSString *)appID;
- (void)removeAllNotifications;

@end
