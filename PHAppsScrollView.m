#import "PHAppsScrollView.h"
#import "PHAppView.h"
#import "PHController.h"

@implementation PHAppsScrollView

@synthesize selectedAppID;

- (id)init {
	if (self = [super init]) {
		NSLog(@"SCROLL VIEW INIT");
		selectedView = [[UIView alloc] init];
		selectedView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.3];
        selectedView.layer.cornerRadius = 10.0;
        selectedView.layer.masksToBounds = YES;
        selectedView.alpha = 0.0;
        [self addSubview:selectedView];

        appViews = [[NSMutableDictionary alloc] init];

        appViewWidth = 46.5; //[[PHController sharedInstance] iconSize] * 1.55;
        appViewHeight = 55.5;
     // 	if ([[[PHController sharedInstance].prefsDict objectForKey:@"showNumbers"] boolValue])
	    //     appViewHeight = [[PHController sharedInstance] iconSize] * 1.85;
	    // else
	    //     appViewHeight = appViewWidth;

	    selectedAppID = nil;

	    NSLog(@"SCROLL VIEW DONE INITTING");
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
	}
	else
		[[appViews objectForKey:appID] updateNumNotifications];

	if ([[appViews allKeys] count] == 0)
		selectedView.alpha = 0.0;
}

- (void)selectApp:(NSString*)appID {
	//Animate selected view moving

	if (!appID) {
		[UIView animateWithDuration:0.15 animations:^{
            selectedView.alpha = 0.0;
        } completion:nil];
	}
	else {
		//Prevent the selected view from animating its position
		if (!selectedAppID)
			selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;

		[UIView animateWithDuration:0.15 animations:^{
			if ([appID isEqualToString:selectedAppID]) {
				selectedView.alpha = 1.0;
			}
			else
            	selectedView.alpha = 1.0;

            selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;
        } completion:nil];
	}

	selectedAppID = appID;
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
}

- (void)handleAppViewTapped:(PHAppView*)appView {
	NSLog(@"APP VIEW TAPPED: %@",appView.appID);
	if ([appView.appID isEqualToString:selectedAppID])
		[self selectApp:nil];
	else
		[self selectApp:appView.appID];
}

@end