#import <UIKit/UIKit.h>

@interface PHAppView : UIView {
	UIImageView *iconView;
	UILabel *numberLabel;
	UITapGestureRecognizer *tapGestureRecognizer;
}

@property (nonatomic, readonly) NSString *appID;
@property id tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID;
- (void)updateNumNotifications;

@end