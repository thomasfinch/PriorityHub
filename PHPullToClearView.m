#import "PHPullToClearView.h"

@implementation PHPullToClearView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.contentsScale = [UIScreen mainScreen].scale;
        
        CGFloat xPathWidth = CGRectGetWidth(self.frame)/30;
        CGMutablePathRef xPath = CGPathCreateMutable();
        CGPathMoveToPoint(xPath, nil, CGRectGetWidth(self.frame)/2 - xPathWidth/2, CGRectGetHeight(self.frame)/4 + xPathWidth/2);
        CGPathAddArc(xPath, nil, CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/4 + xPathWidth/2, xPathWidth/2, M_PI, 0, false);
        CGPathAddLineToPoint(xPath, nil, CGRectGetWidth(self.frame)/2 + xPathWidth/2, 3*CGRectGetHeight(self.frame)/4 - xPathWidth/2);
        CGPathAddArc(xPath, nil, CGRectGetWidth(self.frame)/2, 3*CGRectGetHeight(self.frame)/4 - xPathWidth/2, xPathWidth/2, 0, M_PI, false);
        CGPathAddLineToPoint(xPath, nil, CGRectGetWidth(self.frame)/2 - xPathWidth/2, CGRectGetHeight(self.frame)/4 + xPathWidth/2);
        CGPathCloseSubpath(xPath);
        
        leftXLine = [[CAShapeLayer alloc] init];
        leftXLine.path = xPath;
        leftXLine.transform = CATransform3DMakeRotation(-M_PI/4, 0.0, 0.0, 1.0);
        leftXLine.fillColor = [UIColor whiteColor].CGColor;
        leftXLine.bounds = CGPathGetBoundingBox(leftXLine.path);
        leftXLine.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        leftXLine.hidden = YES;
        [self.layer addSublayer:leftXLine];
        
        rightXLine = [[CAShapeLayer alloc] init];
        rightXLine.path = xPath;
        rightXLine.transform = CATransform3DMakeRotation(M_PI/4, 0.0, 0.0, 1.0);
        rightXLine.fillColor = [UIColor whiteColor].CGColor;
        rightXLine.bounds = CGPathGetBoundingBox(rightXLine.path);
        rightXLine.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        rightXLine.hidden = YES;
        [self.layer addSublayer:rightXLine];

        CAShapeLayer *circleLayer = [[CAShapeLayer alloc] init];
        circleLayer.fillColor = [UIColor clearColor].CGColor;
        circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        circleLayer.lineWidth = 1.0;
        circleLayer.path = CGPathCreateWithEllipseInRect(CGRectInset(self.bounds, self.bounds.size.width * 0.05, self.bounds.size.height * 0.05), nil);
        [self.layer addSublayer:circleLayer];
    }
    return self;
}

- (void)setXVisible:(BOOL)visible {
    leftXLine.hidden = !visible;
    rightXLine.hidden = !visible;
}

@end
