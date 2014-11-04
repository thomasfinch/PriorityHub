#import "PHAppsScrollView.h"
#import "PHAppView.h"
#import "PHController.h"
#import "UIImage+AverageColor.h"

@implementation PHAppsScrollView

@synthesize selectedAppID;

- (id)init {
	if (self = [super init]) {
		self.directionalLockEnabled = YES;

		selectedView = [[UIView alloc] init];
		selectedView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.3];
        selectedView.layer.cornerRadius = 8.0;
        selectedView.layer.masksToBounds = YES;
        [self addSubview:selectedView];

        appViews = [[NSMutableDictionary alloc] init];

        appViewWidth = [PHController iconSize] * 1.4;
     	if ([[[PHController sharedInstance].prefsDict objectForKey:@"showNumbers"] boolValue])
	        appViewHeight = [PHController iconSize] * 1.8;
	    else
	        appViewHeight = appViewWidth;

	    selectedAppID = nil;

	}
	return self;
}

- (void)addNotificationForAppID:(NSString*)appID {
	//Create a new app view if one doesn't already exist
	if (![appViews objectForKey:appID]) {
		PHAppView *newAppView = [[PHAppView alloc] initWithFrame:CGRectMake(0,0,appViewWidth,appViewHeight) appID:appID];
		newAppView.tapDelegate = self;
		[appViews setObject:newAppView forKey:appID];
		[self addSubview:newAppView];
		[self updateLayout];
	}

	//Update the number of notifications for this app and select it
	[[appViews objectForKey:appID] updateNumNotifications];
	[self selectApp:appID];
}

//When one or more notifications are cleared for an app
- (void)removeNotificationForAppID:(NSString*)appID {
	if ([[PHController sharedInstance] numNotificationsForAppID:appID] == 0) {
		[[appViews objectForKey:appID] removeFromSuperview];
		[appViews removeObjectForKey:appID];
		[self updateLayout];
		if ([selectedAppID isEqualToString:appID])
			[self selectApp:nil];
	}
	else
		[[appViews objectForKey:appID] updateNumNotifications];

	if ([[appViews allKeys] count] == 0)
		selectedView.alpha = 0.0;
}

- (void)removeAllAppViews {
	for (PHAppView *appView in [appViews allValues])
		[appView removeFromSuperview];
	[appViews removeAllObjects];
	[self updateLayout];
	[self selectApp:nil];
}

- (void)screenTurnedOff {
	if ([[[PHController sharedInstance].prefsDict objectForKey:@"collapseOnLock"] boolValue])
		[self selectApp:nil];
}

- (void)selectApp:(NSString*)appID {
	//Animate selected view moving

	if (!appID) {
		[UIView animateWithDuration:0.15 animations:^{
            selectedView.alpha = 0;
            [PHController sharedInstance].notificationsTableView.alpha = 0;
        } completion:nil];
	}
	else {
		//Prevent the selected view from animating its position
		if (!selectedAppID) {
			selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;
			selectedView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.3];
		}

		[UIView animateWithDuration:0.15 animations:^{
            selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;
            selectedView.alpha = 1;
            [PHController sharedInstance].notificationsTableView.alpha = 1;

            if ([[[PHController sharedInstance].prefsDict objectForKey:@"colorizeSelected"] boolValue])
				selectedView.backgroundColor = [[PHController iconForAppID:appID] averageColor];

        } completion:nil];
	}

	selectedAppID = appID;

	if ([PHController sharedInstance].notificationsTableView)
		[[PHController sharedInstance].notificationsTableView reloadData];
}

- (void)updateLayout {
	//Re-layout app views
	CGFloat totalWidth = [[appViews allKeys] count] * appViewWidth;
	CGFloat startX = (CGRectGetWidth(self.frame) - totalWidth)/2;
	if (startX < 0)
		startX = 0;
	self.contentSize = CGSizeMake(totalWidth, appViewHeight);

	for (PHAppView *appView in [appViews allValues]) {
		appView.frame = CGRectMake(startX, 0, appViewWidth, appViewHeight);
		startX += appViewWidth;
	}

	if (selectedView.alpha == 1)
		selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
}

- (void)handleAppViewTapped:(PHAppView*)appView {
	NSLog(@"APP VIEW TAPPED: %@",appView.appID);

	if ([PHController sharedInstance].listView)
        [[PHController sharedInstance].listView _resetAllFadeTimers];

	if ([appView.appID isEqualToString:selectedAppID])
		[self selectApp:nil];
	else
		[self selectApp:appView.appID];

	if ([PHController sharedInstance].listView) {
		[[PHController sharedInstance].listView _disableIdleTimer:YES];
		[[PHController sharedInstance].listView _disableIdleTimer:NO];
	}
}

@end