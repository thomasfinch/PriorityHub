#import <Foundation/Foundation.h>
#import "Headers.h"
#import <CoreGraphics/CoreGraphics.h>

@interface PHController : NSObject
{
    NSMutableDictionary *appViewsDict;
    UIView *selectedView;
}

@property (nonatomic, strong) CTCallCenter *callCenter;
@property (nonatomic, strong) UITableView* notificationsTableView;
@property (nonatomic) BOOL appSelected;
@property (nonatomic, strong) NSMutableDictionary *prefsDict;
@property (nonatomic, strong) UIScrollView *appListView;
@property (nonatomic, strong) NSString *curAppID;

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
