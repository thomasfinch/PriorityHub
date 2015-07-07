#import "PHAppView.h"
#import "PHView.h"
#import "colorbadges_api.h"
#import "Headers.h"
#include <dlfcn.h>
#import <objc/runtime.h>

@implementation PHAppView

@synthesize appID;
@synthesize tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID icon:(UIImage*)icon {
	if (self = [super initWithFrame:frame]) {
		self.userInteractionEnabled = YES;
		[self setIsAccessibilityElement:YES];
		appID = applicationID;
		defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];

		BOOL showNumbers = [defaults boolForKey:@"showNumbers"];
		int numberStyle = [defaults integerForKey:@"numberStyle"];

		iconView = [[UIImageView alloc] initWithImage:icon];
		if (showNumbers && numberStyle == 0)
			iconView.frame = CGRectMake((frame.size.width - frame.size.width * 0.71)/2, 5, frame.size.width * 0.71, frame.size.width * 0.71);
		else
			iconView.frame = CGRectMake((frame.size.width - frame.size.width * 0.71)/2, (frame.size.width - frame.size.width * 0.71)/2, frame.size.width * 0.71, frame.size.width * 0.71);
		[self addSubview:iconView];

		if (showNumbers) {
			numberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
			numberLabel.textColor = [UIColor whiteColor];
			numberLabel.textAlignment = NSTextAlignmentCenter;

			if (numberStyle == 0) { //If the notification count is below the app icon
				numberLabel.frame = CGRectMake(0, iconView.frame.origin.y + CGRectGetHeight(iconView.frame) + ((CGRectGetHeight(frame) - (iconView.frame.origin.y + CGRectGetHeight(iconView.frame))) - 15) / 2, CGRectGetWidth(frame), 15);
				[self addSubview:numberLabel];
			}
			else { //If the notification count is shown as an app badge
				badgeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, iconView.frame.size.height/2, iconView.frame.size.height/2)];
				badgeView.backgroundColor = [UIColor redColor];
				badgeView.layer.cornerRadius = badgeView.frame.size.width/2;
				badgeView.center = CGPointMake(iconView.frame.origin.x + iconView.frame.size.width * 0.9, iconView.frame.origin.y + iconView.frame.size.height * 0.1);
				[self addSubview:badgeView];

				//ColorBadge support
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

				numberLabel.frame = badgeView.bounds;
				numberLabel.font = [UIFont systemFontOfSize:10];
				[badgeView addSubview:numberLabel];
			}
		}

		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [self addGestureRecognizer:tapGestureRecognizer];
	}

	return self;
}

- (void)viewTapped:(UITapGestureRecognizer*)recognizer {
	[(PHView*)[self superview] selectAppID:self.appID newNotification:NO];
}

- (void)updateNumNotifications:(NSUInteger)numNotifications {
	if (numberLabel)
		numberLabel.text = [NSString stringWithFormat:@"%ld",(long)numNotifications];

	//VoiceOver support
	NSString *notificationsString = (numNotifications == 1) ? @"notification" : @"notifications";
	NSString *appName = nil;
	if ([[%c(SBApplicationController) sharedInstance] respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
		appName = [[[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:self.appID] displayName];
	}
	else if ([[%c(SBApplicationController) sharedInstance] respondsToSelector:@selector(applicationWithBundleIdentifier:)]) {
		appName = [[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:self.appID] displayName];
	}
	self.accessibilityLabel = [NSString stringWithFormat:@"Priority hub, %@, %lu %@", appName, (unsigned long)numNotifications, notificationsString];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)gestureRecognizer {
	[tapDelegate performSelector:@selector(handleAppViewTapped:) withObject:self];
}

@end