#import "PHContainerView.h"
#import "substrate.h"

@implementation PHContainerView

@synthesize selectedAppID;

- (id)init {
	if (self = [super init]) {
		self.directionalLockEnabled = YES;

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
	// NSDictionary *notificationCountDict = [notificationDict objectForKey:@"notificationCountDict"];
	// NSDictionary *iconDict = [notificationDict objectForKey:@"iconDict"];

	//Create or update app views from the current bulletin list
	[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[appViews removeAllObjects];
	[self addSubview:selectedView];
	for (NSString *appID in [notificationDict allKeys]) {
		PHAppView *appView = [[PHAppView alloc] initWithFrame:CGRectMake(0, 0, appViewSize().width, appViewSize().height) icon:iconForIdentifier(appID) identifier:appID numberStyle:[defaults integerForKey:@"numberStyle"]];
		[appView addTarget:self action:@selector(appViewTapped:) forControlEvents:UIControlEventTouchUpInside];
		[appView setNumNotifications:[[notificationDict objectForKey:appID] unsignedIntegerValue]];
		[appViews setObject:appView forKey:appID];
		[self addSubview:appView];
	}

	//Layout all app views
	CGSize appViewSizeVar = appViewSize();
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

	selectedView.layer.cornerRadius = appViewSize().width / 5; // Just in case settings have changed
}

- (void)appViewTapped:(PHAppView*)appView {
	[self selectAppID:appView.identifier newNotification:NO];
}

- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif {
	NSTimeInterval animationDuration = newNotif ? 0 : 0.15;

	//Move the selected view before animating if it's reselecting
	if (!selectedAppID && appID)
		selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;

	[UIView animateWithDuration:animationDuration animations:^(){
		if ([selectedAppID isEqualToString:appID] && !newNotif) {
			selectedAppID = nil;
			selectedView.alpha = 0;
		}
		else {
			selectedAppID = appID;
			selectedView.alpha = 1;
			selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
		}
	}];

	if (self.updateNotificationTableView)
		self.updateNotificationTableView();
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

@end