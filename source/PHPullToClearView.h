#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

const CGFloat pullToClearSize = 30;

@interface PHPullToClearView : UIView {
	UIView *xPathView;
    CAShapeLayer *leftXLine, *rightXLine;
}

- (void)setXVisible:(BOOL)visible;

@end
