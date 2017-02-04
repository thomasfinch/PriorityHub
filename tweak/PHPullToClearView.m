#import "PHPullToClearView.h"

@implementation PHPullToClearView

- (id)init {
	if (self = [super init]) {
		self.backgroundColor = [UIColor clearColor];
		self.layer.contentsScale = [UIScreen mainScreen].scale;
		
		circleLayer = [CAShapeLayer layer];
		circleLayer.strokeColor = [UIColor whiteColor].CGColor;
		circleLayer.fillColor = [UIColor clearColor].CGColor;
		circleLayer.lineWidth = 1.0;
		[self.layer addSublayer:circleLayer];
		
		xLayer = [CAShapeLayer layer];
		xLayer.strokeColor = [UIColor whiteColor].CGColor;
		xLayer.lineWidth = 1.0;
		xLayer.lineCap = kCALineCapRound;
		xLayer.hidden = YES;
		[self.layer addSublayer:xLayer];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	circleLayer.path = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.bounds, pullToClearSize * 0.05, pullToClearSize * 0.05)].CGPath;
	xLayer.frame = CGRectInset(self.bounds, pullToClearSize * 0.32, pullToClearSize * 0.32);

	UIBezierPath *xPath = [UIBezierPath bezierPath];
	[xPath moveToPoint:CGPointMake(0, 0)];
	[xPath addLineToPoint:CGPointMake(CGRectGetWidth(xLayer.bounds), CGRectGetHeight(xLayer.bounds))];
	[xPath moveToPoint:CGPointMake(0, CGRectGetHeight(xLayer.bounds))];
	[xPath addLineToPoint:CGPointMake(CGRectGetWidth(xLayer.bounds), 0)];

	xLayer.path = xPath.CGPath;
}

- (void)didScroll:(UIScrollView*)scrollView {
	self.xVisible = (scrollView.contentOffset.y <= -pullToClearThreshold);
}

- (void)didEndDragging:(UIScrollView*)scrollView {
	if (scrollView.contentOffset.y <= -pullToClearThreshold &&  (scrollView.dragging || scrollView.tracking)) {
		if (self.clearBlock)
			self.clearBlock();
	}
}

- (void)setXVisible:(BOOL)visible {
	xLayer.hidden = !visible;
}

- (BOOL)xVisible {
	return !xLayer.hidden;
}

@end