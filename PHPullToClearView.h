#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PHPullToClearView : UIView {
    CAShapeLayer *leftXLine, *rightXLine;
}

- (void)setXVisible:(BOOL)visible;

@end
