#import "PHPullToClearView.h"

@implementation PHPullToClearView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.contentsScale = [UIScreen mainScreen].scale;

        xPathView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pullToClearSize, pullToClearSize)];
        xPathView.center = self.center;
        [self addSubview:xPathView];

        CGFloat xPathWidth = CGRectGetWidth(xPathView.frame)/30;
        CGMutablePathRef xPath = CGPathCreateMutable();
        CGPathMoveToPoint(xPath, nil, CGRectGetWidth(xPathView.frame)/2 - xPathWidth/2, CGRectGetHeight(xPathView.frame)/4 + xPathWidth/2);
        CGPathAddArc(xPath, nil, CGRectGetWidth(xPathView.frame)/2, CGRectGetHeight(xPathView.frame)/4 + xPathWidth/2, xPathWidth/2, M_PI, 0, false);
        CGPathAddLineToPoint(xPath, nil, CGRectGetWidth(xPathView.frame)/2 + xPathWidth/2, 3*CGRectGetHeight(xPathView.frame)/4 - xPathWidth/2);
        CGPathAddArc(xPath, nil, CGRectGetWidth(xPathView.frame)/2, 3*CGRectGetHeight(xPathView.frame)/4 - xPathWidth/2, xPathWidth/2, 0, M_PI, false);
        CGPathAddLineToPoint(xPath, nil, CGRectGetWidth(xPathView.frame)/2 - xPathWidth/2, CGRectGetHeight(xPathView.frame)/4 + xPathWidth/2);
        CGPathCloseSubpath(xPath);

        leftXLine = [[CAShapeLayer alloc] init];
        leftXLine.path = xPath;
        leftXLine.transform = CATransform3DMakeRotation(-M_PI/4, 0.0, 0.0, 1.0);
        leftXLine.fillColor = [UIColor whiteColor].CGColor;
        leftXLine.bounds = CGPathGetBoundingBox(leftXLine.path);
        leftXLine.position = CGPointMake(CGRectGetMidX(xPathView.bounds), CGRectGetMidY(xPathView.bounds));
        leftXLine.hidden = YES;
        [xPathView.layer addSublayer:leftXLine];
        
        rightXLine = [[CAShapeLayer alloc] init];
        rightXLine.path = xPath;
        rightXLine.transform = CATransform3DMakeRotation(M_PI/4, 0.0, 0.0, 1.0);
        rightXLine.fillColor = [UIColor whiteColor].CGColor;
        rightXLine.bounds = CGPathGetBoundingBox(rightXLine.path);
        rightXLine.position = CGPointMake(CGRectGetMidX(xPathView.bounds), CGRectGetMidY(xPathView.bounds));
        rightXLine.hidden = YES;
        [xPathView.layer addSublayer:rightXLine];

        CAShapeLayer *circleLayer = [[CAShapeLayer alloc] init];
        circleLayer.fillColor = [UIColor clearColor].CGColor;
        circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        circleLayer.lineWidth = 1.0;
        circleLayer.path = CGPathCreateWithEllipseInRect(CGRectInset(xPathView.bounds, xPathView.bounds.size.width * 0.05, xPathView.bounds.size.height * 0.05), nil);
        [xPathView.layer addSublayer:circleLayer];

    }
    return self;
}

- (void)layoutSubviews {
    xPathView.center = self.center;
    xPathView.frame = CGRectMake(xPathView.frame.origin.x, 0, pullToClearSize, pullToClearSize);
}

- (void)setXVisible:(BOOL)visible {
    leftXLine.hidden = !visible;
    rightXLine.hidden = !visible;
}

@end
