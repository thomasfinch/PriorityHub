#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreGraphics/CoreGraphics.h>

@interface PHController : NSObject
{
    NSMutableDictionary *appViewsDict;
    UIView *selectedView;
    UITableView* notificationsTableView;
    CTCallCenter *callCenter;
}

@property (nonatomic, readonly) BOOL appSelected;
@property (nonatomic, readonly) NSMutableDictionary *prefsDict;
@property (nonatomic, readonly) UIScrollView *appListView;
@property (nonatomic, readonly) NSString *curAppID;

- (id)init;

- (CGFloat)iconSize;
- (CGFloat)viewWidth;
- (CGFloat)viewHeight;

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
