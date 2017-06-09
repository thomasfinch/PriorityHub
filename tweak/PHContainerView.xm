#import "PHContainerView.h"
#import "substrate.h"

@implementation PHContainerView

@synthesize selectedAppID;

- (id)init:(BOOL)onLockscreen {
	if (self = [super init]) {
		self.directionalLockEnabled = YES;
		lockscreen = onLockscreen;

		//Create the selected view
		if (%c(NCMaterialView)) {
			selectedView = [%c(NCMaterialView) materialViewWithStyleOptions:2]; // 0 = invisible, 1 = mostly see through (old PH style basically), 2 = more frosted
		}
		else {
			selectedView = [UIView new];
			selectedView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
		}
		selectedView.layer.masksToBounds = YES;
		[self addSubview:selectedView];

		//Initialize other instance variables
		defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
		appViews = [NSMutableDictionary new];
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (void)updateView {
	NSDictionary *notificationDict = self.getCurrentNotifications();

	//Create or update app views from the current notification list
	for (PHAppView* appView in [appViews allValues]) {
		[appView removeFromSuperview];
		[appView release];
	}
	[appViews removeAllObjects];

	for (NSString *appID in [notificationDict allKeys]) {
		PHAppView *appView = [[PHAppView alloc] initWithFrame:CGRectMake(0, 0, appViewSize(lockscreen).width, appViewSize(lockscreen).height) icon:iconForIdentifier(appID) identifier:appID numberStyle:[defaults integerForKey:@"numberStyle"]];
		[appView addTarget:self action:@selector(appViewTapped:) forControlEvents:UIControlEventTouchUpInside];
		[appView setNumNotifications:[[notificationDict objectForKey:appID] unsignedIntegerValue]];
		[appViews setObject:appView forKey:appID];
		[self addSubview:appView];
	}

	//Layout all app views
	CGSize appViewSizeVar = appViewSize(lockscreen);
	CGFloat totalWidth = [[appViews allKeys] count] * appViewSizeVar.width;
	self.contentSize = CGSizeMake(totalWidth, appViewSizeVar.height);
	CGFloat startX = (CGRectGetWidth(self.frame) - totalWidth)/2;
	if (startX < 0)
		startX = 0;

	for (PHAppView *appView in [appViews allValues]) {
		appView.frame = CGRectMake(startX, 0, appViewSizeVar.width, appViewSizeVar.height);
		startX += appViewSizeVar.width;
	}

	//Update selected view location
	if (selectedView.alpha == 1 && selectedAppID && [appViews objectForKey:selectedAppID])
		selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
	else if (![appViews objectForKey:selectedAppID]) {
		selectedAppID = nil;
		selectedView.alpha = 0;
	}

	selectedView.layer.cornerRadius = appViewSize(lockscreen).width / 5; // Just in case settings have changed
}

- (void)appViewTapped:(PHAppView*)appView {
	[self selectAppID:appView.identifier newNotification:NO];
}

- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif {
	NSTimeInterval animationDuration = newNotif ? 0 : 0.15;

	//Move the selected view before animating if it's reselecting
	if (!selectedAppID && appID)
		selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;

	NSString *oldSelectedAppID = selectedAppID;

	if ([selectedAppID isEqualToString:appID] && !newNotif)
		selectedAppID = nil;
	else
		selectedAppID = appID;

	[UIView animateWithDuration:animationDuration animations:^(){
		if ([oldSelectedAppID isEqualToString:appID] && !newNotif) {
			[(PHAppView*)[appViews objectForKey:oldSelectedAppID] animateBadge:NO duration:animationDuration];
			selectedView.alpha = 0;
		}
		else {
			[(PHAppView*)[appViews objectForKey:oldSelectedAppID] animateBadge:NO duration:animationDuration];
			selectedView.alpha = 1;
			PHAppView *appView = (PHAppView*)[appViews objectForKey:selectedAppID];
			selectedView.frame = appView.frame;
			[appView animateBadge:YES duration:animationDuration];
		}
	}];

	if (self.updateNotificationView)
		self.updateNotificationView();
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

@end