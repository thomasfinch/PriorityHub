//
//  PHController.h
//  
//
//  Created by Thomas Finch on 4/28/14.
//
//

#import <Foundation/Foundation.h>

@interface PHController : NSObject
{
    NSBundle *iconsBundle;
    NSMutableDictionary *appViewsDict;
    UIView *selectedView;
}

@property (nonatomic) NSMutableDictionary *prefsDict;
@property (nonatomic) UIScrollView *appListView;
@property (nonatomic) NSString *curAppID;

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
