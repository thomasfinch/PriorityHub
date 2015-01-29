#import "PHAppView.h"
#import "PHController.h"
#import "colorbadges_api.h"
#include <dlfcn.h>
#import <objc/runtime.h>

@implementation PHAppView

@synthesize appID;
@synthesize tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID {
	if (self = [super initWithFrame:frame]) {
		appID = applicationID;

		BOOL showNumbers = [[PHController sharedInstance].prefsDict boolForKey:@"showNumbers"];
		int numberStyle = [[PHController sharedInstance].prefsDict integerForKey:@"numberStyle"];

		iconView = [[UIImageView alloc] initWithImage:[PHController iconForAppID:appID]];
		if (showNumbers && numberStyle == 0)
			iconView.frame = CGRectMake((frame.size.width - [PHController iconSize])/2, 5, [PHController iconSize], [PHController iconSize]);
		else
			iconView.frame = CGRectMake((frame.size.width - [PHController iconSize])/2, (frame.size.width - [PHController iconSize])/2, [PHController iconSize], [PHController iconSize]);
		[self addSubview:iconView];

		if (showNumbers) {
			numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
			numberLabel.textColor = [UIColor whiteColor];
			numberLabel.textAlignment = NSTextAlignmentCenter;

			if (numberStyle == 0) { //If the notification count is underneath the app icon
				numberLabel.frame = CGRectMake(0, iconView.frame.origin.y + CGRectGetHeight(iconView.frame) + ((CGRectGetHeight(frame) - (iconView.frame.origin.y + CGRectGetHeight(iconView.frame))) - 15) / 2, CGRectGetWidth(frame), 15);
				[self addSubview:numberLabel];
			}
			else { //If the notification count is shown as an app badge
				badgeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [PHController iconSize]/2, [PHController iconSize]/2)];
				badgeView.backgroundColor = [UIColor redColor];
				badgeView.layer.cornerRadius = badgeView.frame.size.width/2;
				badgeView.center = CGPointMake(iconView.frame.origin.x + iconView.frame.size.width*0.9, iconView.frame.origin.y + iconView.frame.size.height*0.1);
				[self addSubview:badgeView];

				//ColorBadge support
				dlopen("/Library/MobileSubstrate/DynamicLibraries/ColorBadges.dylib", RTLD_LAZY);
				Class cb = objc_getClass("ColorBadges");
				if (cb && [cb isEnabled]) {
					int badgeColor = [[cb sharedInstance] colorForImage:[PHController iconForAppID:appID]];
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

				numberLabel.frame = badgeView.bounds;
				numberLabel.font = [UIFont systemFontOfSize:10];
				[badgeView addSubview:numberLabel];
			}
		}

		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
	}
	return self;
}

- (void)updateNumNotifications {
	if (numberLabel)
		numberLabel.text = [NSString stringWithFormat:@"%ld",(long)[[PHController sharedInstance] numNotificationsForAppID:appID]];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)gestureRecognizer {
	[tapDelegate performSelector:@selector(handleAppViewTapped:) withObject:self];
}

// - (void)dealloc {
// 	[iconView release];
// 	[numberLabel release];
// 	[badgeView release];
// 	[super dealloc];
// }

@end