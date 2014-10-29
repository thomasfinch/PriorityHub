#import <UIKit/UIKit.h>

@interface PHAppsScrollView : UIScrollView {
	UIView *selectedView;
	NSMutableDictionary *appViews;
	CGFloat appViewHeight, appViewWidth, iconSize;
}

@property (readonly) NSString *selectedAppID;

- (id)init;
- (void)addNotificationForAppID:(NSString*)appID;
- (void)removeNotificationForAppID:(NSString*)appID;
- (void)removeAllAppViews;

@end