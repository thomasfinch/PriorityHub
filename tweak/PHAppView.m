#import "PHAppView.h"
#import "PHContainerView.h"
#import "colorbadges_api.h"
#import <dlfcn.h>
#import <objc/runtime.h>

@implementation PHAppView

- (PHAppView*)initWithFrame:(CGRect)frame icon:(UIImage*)icon identifier:(NSString*)appID numberStyle:(NSInteger)style {
	if (self = [super initWithFrame:frame]) {
		self.identifier = appID;

		// Convenience variables
		CGFloat viewSize = CGRectGetWidth(frame);
		CGFloat padding = viewSize * 0.13;
		CGFloat appViewSize = viewSize - 2 * padding;
		CGFloat badgeViewSize = appViewSize / 2.5;
		CGFloat fontSize = (style == 2) ? viewSize / 5 : viewSize / 2.5; // 2 == badge style
		
		appIconView = [[UIImageView alloc] initWithImage:icon];
		appIconView.frame = CGRectMake(padding, padding, appViewSize, appViewSize);
		[self addSubview:appIconView];
		NSLog(@"ICON: %@", icon);
		
		numberLabel = [UILabel new];
		// numberLabel.textColor = [UIColor whiteColor];
		numberLabel.textColor = [UIColor blackColor]; // TEMPORARY
		numberLabel.textAlignment = NSTextAlignmentCenter;
		numberLabel.font = [UIFont systemFontOfSize:fontSize];

		badgeView = [UIView new];
		
		// Layout badge and number labels
		switch (style) {
			case 1: // Below app icon
				[self addSubview:numberLabel];
				numberLabel.frame = CGRectMake(0, CGRectGetMaxY(appIconView.frame), CGRectGetWidth(frame), CGRectGetHeight(frame) - CGRectGetMaxX(appIconView.frame));
				break;
				
			case 2: { // Badge
				badgeView.backgroundColor = [UIColor redColor];
				badgeView.layer.cornerRadius = badgeViewSize/2;
				badgeView.layer.masksToBounds = YES;
				[badgeView addSubview:numberLabel];
				[self addSubview:badgeView];

				CGFloat badgeViewPadding = padding / 2;
				badgeView.frame = CGRectMake(CGRectGetWidth(frame) - badgeViewSize - badgeViewPadding, badgeViewPadding, badgeViewSize, badgeViewSize);
				numberLabel.frame = badgeView.bounds;
				
				// ColorBadges support
				dlopen("/Library/MobileSubstrate/DynamicLibraries/ColorBadges.dylib", RTLD_LAZY);
				Class cb = objc_getClass("ColorBadges");
				if (cb && [cb isEnabled]) {
					int badgeColor = [[cb sharedInstance] colorForImage:icon];
					badgeView.backgroundColor = UIColorFromRGB(badgeColor);
					BOOL isDark = [cb isDarkColor:badgeColor];
					if ([cb areBordersEnabled])
						badgeView.layer.borderWidth = 1.0f;
					
					if (isDark) {
						badgeView.layer.borderColor = [UIColor whiteColor].CGColor;
						numberLabel.textColor = [UIColor whiteColor];
					}
					else {
						badgeView.layer.borderColor = [UIColor blackColor].CGColor;
						numberLabel.textColor = [UIColor blackColor];
					}
				}

				break;
			}
				
			default:
			case 0: // No numbers
				break;
		}
	}
	return self;
}

- (void)setNumNotifications:(NSInteger)numNotifications {
	numberLabel.text = [NSString stringWithFormat:@"%ld", (long)numNotifications];
}

- (void)dealloc {
	[super dealloc];
	NSLog(@"DEALLOC CALLED IN PH APP VIEW");
	[appIconView release];
	[numberLabel release];
	[badgeView release];
}

@end
