#import <UIKit/UIKit.h>

@interface PHAppView : UIControl {
	UIImageView *appIconView;
	UILabel *numberLabel;
	UIView *badgeView;
	int numberStyle;
}

@property (copy) NSString *identifier;

- (PHAppView*)initWithFrame:(CGRect)frame icon:(UIImage*)icon identifier:(NSString*)appID numberStyle:(NSInteger)style;
- (void)setNumNotifications:(NSInteger)numNotifications;
- (void)animateBadge:(BOOL)selected duration:(NSTimeInterval)animationDuration;

@end
