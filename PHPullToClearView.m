#import "PHPullToClearView.h"

@implementation PHPullToClearView

@synthesize clearing;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        percentDone = 0;
    }
    return self;
}

- (void)layoutSubviews {
    clearing = NO;

    circleLayer = [[CAShapeLayer alloc] init];
    circleLayer.fillColor = [UIColor whiteColor].CGColor;
    CGMutablePathRef circlePath = CGPathCreateMutable();
    CGFloat radius = (CGRectGetWidth(self.frame)*0.9)/2, lineWidth = CGRectGetWidth(self.frame)/30;
    CGPathAddArc(circlePath, nil, 0, 0, radius, 0, 2*M_PI, true);
    circlePath = CGPathCreateCopyByStrokingPath(circlePath, nil, lineWidth, kCGLineCapRound, kCGLineJoinRound, 1.0);
    circleLayer.path = circlePath;
    circleLayer.rasterizationScale = 2.0*[UIScreen mainScreen].scale;
    circleLayer.shouldRasterize = YES;
    [self.layer addSublayer:circleLayer];
    
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
    leftXLine.hidden = YES;
    [self.layer addSublayer:leftXLine];
    
    rightXLine = [[CAShapeLayer alloc] init];
    rightXLine.path = xPath;
    rightXLine.transform = CATransform3DMakeRotation(M_PI/4, 0.0, 0.0, 1.0);
    rightXLine.fillColor = [UIColor whiteColor].CGColor;
    rightXLine.bounds = CGPathGetBoundingBox(rightXLine.path);
    rightXLine.hidden = YES;
    [self.layer addSublayer:rightXLine];
}

- (void)setPercentDone:(float)percent {
    
}

- (void)setXVisible:(BOOL)visible {
    leftXLine.hidden = !visible;
    rightXLine.hidden = !visible;
}

@end
