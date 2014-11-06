#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface PHPullToClearView : UIView {
    float percentDone;
    
    CAShapeLayer *leftXLine, *rightXLine, *circleLayer;
}

@property BOOL clearing;

- (void)setXVisible:(BOOL)visible;

@end
