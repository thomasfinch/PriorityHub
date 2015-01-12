#import "PHPullToClearView.h"

@implementation PHPullToClearView

@synthesize clearing;

- (void)layoutSubviews {
    clearing = NO;
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
}

- (void)setXVisible:(BOOL)visible {
    leftXLine.hidden = !visible;
    rightXLine.hidden = !visible;
}

- (void)drawRect:(CGRect)rect
{
    CGFloat radius = (CGRectGetWidth(self.frame)*0.9)/2, offset = (CGRectGetWidth(self.frame)*0.1)/2;

    CGContextRef ctx= UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextStrokeEllipseInRect(ctx, CGRectMake(offset, offset, 2*radius, 2*radius));
}

@end
