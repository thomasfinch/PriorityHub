#import <UIKit/UIKit.h>

@interface PHAppsScrollView : UIScrollView {
	UIView *selectedView;
	NSMutableDictionary *appViews;
	CGFloat appViewHeight, appViewWidth;
}

@property (readonly) NSString *selectedAppID;

- (id)init;
- (void)addNotificationForAppID:(NSString*)appID;
- (void)removeNotificationForAppID:(NSString*)appID;

@end