#import "PHAppView.h"
#import "PHContainerView.h"
#import "colorbadges_api.h"
#import <dlfcn.h>
#import <objc/runtime.h>

@implementation PHAppView

- (PHAppView*)initWithFrame:(CGRect)frame icon:(UIImage*)icon identifier:(NSString*)appID numberStyle:(NSInteger)style {
	if (self = [super initWithFrame:frame]) {
		self.identifier = appID;
		numberStyle = style;

		// Convenience variables
		CGFloat viewSize = CGRectGetWidth(frame);
		CGFloat padding = viewSize * 0.12;
		CGFloat appViewSize = round(viewSize - 2 * padding);
		CGFloat badgeViewSize = (style == 2) ? round(appViewSize / 2.5) : round(appViewSize / 1.75); // 2 == badge style
		CGFloat fontSize = (style == 2) ? round(viewSize / 5) : round(viewSize / 3.25); // 2 == badge style
		
		appIconView = [[UIImageView alloc] initWithImage:icon];
		appIconView.frame = CGRectMake(padding, padding, appViewSize, appViewSize);
		[self addSubview:appIconView];
		
		numberLabel = [UILabel new];
		numberLabel.textAlignment = NSTextAlignmentCenter;
		numberLabel.textColor = [UIColor blackColor];
		numberLabel.font = [UIFont systemFontOfSize:fontSize];

		// Layout badge and number labels

		if (style == 1) { // Below app icon
			if (%c(NCMaterialView)) {
				badgeView = [%c(NCMaterialView) materialViewWithStyleOptions:2]; // 0 = invisible, 1 = mostly see through (old PH style basically), 2 = more frosted
			}
			else {
				badgeView = [UIView new];
				badgeView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
			}
			badgeView.frame = CGRectMake(round(CGRectGetMidX(appIconView.frame) - badgeViewSize / 2), round((CGRectGetMaxY(appIconView.frame) + self.bounds.size.height) / 2 - badgeViewSize / 2), badgeViewSize, badgeViewSize);
			badgeView.layer.cornerRadius = badgeViewSize / 2.0;
			badgeView.layer.masksToBounds = YES;
			[badgeView addSubview:numberLabel];
			[self addSubview:badgeView];

			numberLabel.frame = badgeView.bounds;
			numberLabel.textColor = [UIColor colorWithWhite:0 alpha:0.7];
		}
		else if (style == 2) { // Badge
			badgeView = [UIView new];
			badgeView.backgroundColor = [UIColor redColor];
			badgeView.layer.cornerRadius = badgeViewSize / 2;
			badgeView.layer.masksToBounds = YES;
			[badgeView addSubview:numberLabel];
			[self addSubview:badgeView];

			CGFloat badgeViewPadding = padding / 2;
			badgeView.frame = CGRectMake(CGRectGetWidth(frame) - badgeViewSize - badgeViewPadding, badgeViewPadding, badgeViewSize, badgeViewSize);
			numberLabel.frame = badgeView.bounds;
			numberLabel.textColor = [UIColor whiteColor];
			
			// ColorBadges support
			dlopen("/Library/MobileSubstrate/DynamicLibraries/ColorBadges.dylib", RTLD_LAZY);
			Class cb = objc_getClass("ColorBadges");
			if (cb && [cb isEnabled]) {
				int badgeColor = [[cb sharedInstance] colorForImage:icon];
				badgeView.backgroundColor = UIColorFromRGB(badgeColor);
				BOOL isDark = [cb isDarkColor:badgeColor];
				if ([cb areBordersEnabled])
					badgeView.layer.borderWidth = 1.0;
				
				if (isDark) {
					badgeView.layer.borderColor = [UIColor whiteColor].CGColor;
					numberLabel.textColor = [UIColor whiteColor];
				}
				else {
					badgeView.layer.borderColor = [UIColor blackColor].CGColor;
					numberLabel.textColor = [UIColor blackColor];
				}
			}
		}
	}
	return self;
}

- (void)setNumNotifications:(NSInteger)numNotifications {
	numberLabel.text = [NSString stringWithFormat:@"%ld", (long)numNotifications];
}

- (void)animateBadge:(BOOL)selected duration:(NSTimeInterval)animationDuration {
	if (numberStyle == 2) // Only animate for below icon style
			return;

	// [UIView animateWithDuration:animationDuration animations:^(){
	// 	if (selected) {
	// 		badgeView.backgroundColor = [UIColor redColor];
	// 		[badgeView subviews][0].alpha = 0;
	// 		numberLabel.textColor = [UIColor whiteColor];
	// 	}
	// 	else {
	// 		badgeView.backgroundColor = [UIColor clearColor];
	// 		[badgeView subviews][0].alpha = 1;
	// 		numberLabel.textColor = [UIColor blackColor];
	// 	}
	// }];
}

- (void)dealloc {
	[super dealloc];
	// NSLog(@"DEALLOC CALLED IN PH APP VIEW");
	// [appIconView release];
	// [numberLabel release];
	// [badgeView release];
}

@end
