#import <UIKit/UIKit.h>

@interface PHAppView : UIView {
	UIImageView *iconView;
	UILabel *numberLabel;
	UIView *badgeView;
	NSUserDefaults *defaults;
}

@property (nonatomic, readonly) NSString *appID;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID iconSize:(CGFloat)iconSize icon:(UIImage*)icon;
- (void)updateNumNotifications:(NSUInteger)numNotifications;

@end