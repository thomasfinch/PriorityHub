#import <UIKit/UIKit.h>

@interface PHAppView : UIView {
	UIImageView *iconView;
	UILabel *numberLabel;
}

@property (nonatomic, readonly) NSString *appID;
@property id tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID;
- (void)updateNumNotifications;

@end