#import "PHContainerView.h"
#import "substrate.h"

@implementation PHContainerView

@synthesize selectedAppID;

- (id)init {
	if (self = [super init]) {
		self.directionalLockEnabled = YES;
		
		//Create the selected view
		selectedView = [[UIView alloc] init];
		selectedView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.3];
	    selectedView.layer.cornerRadius = 10.0;
	    selectedView.layer.masksToBounds = YES;
	    [self addSubview:selectedView];

	    //Initialize other instance variables
	    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
	    appViews = [[NSMutableDictionary alloc] init];
	    _listController = nil;
	    self.userInteractionEnabled = YES;
	}
	return self;
}

- (void)updateView {
	NSMutableDictionary *bulletinCountDict = [[NSMutableDictionary alloc] init], *iconDict = [[NSMutableDictionary alloc] init];
	if (!_listController)
		return;

	//Count the number of bulletins for each app ID
	for (SBAwayListItem *listItem in MSHookIvar<NSMutableArray*>(_listController, "_listItems")) {
		NSString *bulletinID = identifierForListItem(listItem);

		//Add count and icon to dictionaries
		if ([[bulletinCountDict objectForKey:bulletinID] intValue])
			[bulletinCountDict setObject:[NSNumber numberWithInt:[[bulletinCountDict objectForKey:bulletinID] intValue] + 1] forKey:bulletinID];
		else {
			[bulletinCountDict setObject:[NSNumber numberWithInt:1] forKey:bulletinID];
			[iconDict setObject:[self iconForListItem:listItem] forKey:bulletinID]; //This seems to be causing crashes, object seems to be nil
		}
	}

    //Create or update app views from the current bulletin list
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [appViews removeAllObjects];
    [self addSubview:selectedView];
    for (NSString *appID in [bulletinCountDict allKeys]) {
    	PHAppView *appView = [[PHAppView alloc] initWithFrame:CGRectMake(0,0,[self appViewSize].width,[self appViewSize].height) appID:appID iconSize:[self appIconSize] icon:[iconDict objectForKey:appID]];
    	[appView updateNumNotifications:[[bulletinCountDict objectForKey:appID] unsignedIntegerValue]];
    	[appViews setObject:appView forKey:appID];
    	[self addSubview:appView];
    }

    //Layout all app views
	CGFloat totalWidth = [[appViews allKeys] count] * [self appViewSize].width;
	self.contentSize = CGSizeMake(totalWidth, [self appViewSize].height);
	CGFloat startX = (CGRectGetWidth(self.frame) - totalWidth)/2;
	if (startX < 0)
		startX = 0;

	for (PHAppView *appView in [appViews allValues]) {
		appView.frame = CGRectMake(startX, 0, [self appViewSize].width, [self appViewSize].height);
		startX += [self appViewSize].width;
	}

	//Update selected view location
	if (selectedView.alpha == 1 && selectedAppID && [appViews objectForKey:selectedAppID])
		selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
	else if (![appViews objectForKey:selectedAppID]) {
		selectedAppID = nil;
		selectedView.alpha = 0;
	}
}

- (void)selectAppID:(NSString*)appID newNotification:(BOOL)newNotif {
	if (newNotif) {
		selectedView.alpha = 1;
		selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;
		selectedAppID = appID;
	}
	else {
		if ([selectedAppID isEqualToString:appID]) {
			[UIView animateWithDuration:0.15 animations:^(){
				if (selectedView.alpha == 1) {
					selectedView.alpha = 0;
					selectedAppID = nil;
				}
				else {
					selectedView.alpha = 1;
					selectedAppID = appID;
				}
			}];
		}
		else {
			selectedAppID = appID;

			if (selectedView.alpha == 0)
				selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;

			[UIView animateWithDuration:0.15 animations:^(){
				selectedView.alpha = 1;
				selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
			}];
		}
	}

	updateNotificationTableView();
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (UIImage*)iconForListItem:(SBAwayListItem*)listItem {
	UIImage *icon = nil;
	NSString *identifier = identifierForListItem(listItem);

	if (!identifier) {
		return [[UIImage alloc] init];
	}

	if ([listItem isKindOfClass:%c(SBSnoozedAlarmListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmBulletinListItem)])
		icon = [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
	if ([listItem isKindOfClass:%c(SBAwayBulletinListItem)]) {
	    if ([identifier isEqualToString:@"com.apple.mobilecal"])
	    	icon = [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
	    else if (![identifier isEqualToString:@"noIdentifier"]) {
	    	int iconImageNumber = 2;
	    	if ([self appIconSize] >= 60)
	    		iconImageNumber = 2;
	    	else if ([self appIconSize] >= 40)
	    		iconImageNumber = 1;
	    	else
	    		iconImageNumber = 0;

			SBApplication *app = nil;
			if ([[%c(SBApplicationController) sharedInstance] respondsToSelector:@selector(applicationWithBundleIdentifier:)])
				app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:identifier];
			else if ([[%c(SBApplicationController) sharedInstance] respondsToSelector:@selector(applicationWithDisplayIdentifier:)])
				app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:identifier];

			icon = [[[%c(SBApplicationIcon) alloc] initWithApplication:app] generateIconImage:iconImageNumber]; //0 = 29x29, 1 = 40x40, 2 = 60x60, 3 = ???
		}
	    else if ([(SBAwayBulletinListItem*)listItem iconImage])
	    	icon = [(SBAwayBulletinListItem*)listItem iconImage];
	}
	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)])
		icon = [(SBAwayCardListItem*)listItem cardThumbnail];
	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)])
		icon = [(SBAwaySystemAlertItem*)listItem iconImage];

	if (icon)
		return icon;

	//Handle the case where somehow an icon still hasn't been found yet
	if (!icon)
		icon = [[UIImage alloc] init];

	return icon;
}

- (CGFloat)appIconSize {
	switch([defaults integerForKey:@"iconSize"]) {
		case 0:
			return 29;
		case 1:
			return 38;
		case 2:
			return 45;
		case 3:
			return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 76 : 60;
		default:
			return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 38 : 29;
	}
}

- (CGSize)appViewSize {
	CGFloat width = [self appIconSize];
	if ([defaults boolForKey:@"showNumbers"] && [defaults integerForKey:@"numberStyle"] == 0) //If numbers are enabled and below icon
		return CGSizeMake(width * 1.3, width * 1.7);
	else
		return CGSizeMake(width * 1.3, width * 1.3);
}

@end