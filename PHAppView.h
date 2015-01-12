#import <UIKit/UIKit.h>

@interface PHAppView : UIView {
	UIImageView *iconView;
	UILabel *numberLabel;
	UIView *badgeView;
}

@property (nonatomic, readonly) NSString *appID;
@property (assign) id tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID;
- (void)updateNumNotifications;

@end