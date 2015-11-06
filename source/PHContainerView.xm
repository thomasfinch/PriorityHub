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
	    selectedView.layer.cornerRadius = 8.0;
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
	if (!_listController)
		return;

	NSMutableDictionary *notificationCountDict = [[NSMutableDictionary alloc] init], *iconDict = [[NSMutableDictionary alloc] init];

	//Count the number of notifications for each app ID
	for (unsigned long long i = 0; i < [_listController count]; i++) {
		SBAwayListItem *listItem = [_listController listItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		NSString *identifier = identifierForListItem(listItem);

		//Add count and icon to dictionaries
		int prevCount = [[notificationCountDict objectForKey:identifier] intValue];
		[notificationCountDict setObject:[NSNumber numberWithInt:prevCount + 1] forKey:identifier];
		[iconDict setObject:[self iconForListItem:listItem] forKey:identifier];
	}

    //Create or update app views from the current bulletin list
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [appViews removeAllObjects];
    [self addSubview:selectedView];
    for (NSString *appID in [notificationCountDict allKeys]) {
    	PHAppView *appView = [[PHAppView alloc] initWithFrame:CGRectMake(0,0,[self appViewSize].width,[self appViewSize].height) appID:appID iconSize:[self appIconSize] icon:[iconDict objectForKey:appID]];
    	[appView updateNumNotifications:[[notificationCountDict objectForKey:appID] unsignedIntegerValue]];
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
	NSTimeInterval animationDuration = newNotif ? 0 : 0.15;

	//Move the selected view before animating if it's reselecting
	if (!selectedAppID && appID)
		selectedView.frame = ((PHAppView*)[appViews objectForKey:appID]).frame;

	[UIView animateWithDuration:animationDuration animations:^(){
		if ([selectedAppID isEqualToString:appID]) {
			selectedAppID = nil;
			selectedView.alpha = 0;
		}
		else {
			selectedAppID = appID;
			selectedView.alpha = 1;
			selectedView.frame = ((PHAppView*)[appViews objectForKey:selectedAppID]).frame;
		}
	}];

	updateNotificationTableView();
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (UIImage*)iconForListItem:(SBAwayListItem*)listItem {
	NSString *identifier = identifierForListItem(listItem);
	UIImage *icon = nil;

	if (!identifier) {
		return [[UIImage alloc] init];
	}

	if ([listItem isKindOfClass:%c(SBSnoozedAlarmListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmBulletinListItem)] || [listItem isKindOfClass:%c(SBAwayBulletinListItem)]) {
		int iconImageNumber = 0;
		if ([self appIconSize] >= 60)
			iconImageNumber = 2;
		else if ([self appIconSize] >= 40)
			iconImageNumber = 1;
		else
			iconImageNumber = 0;

		icon = [UIImage _applicationIconImageForBundleIdentifier:identifier format:iconImageNumber scale:[UIScreen mainScreen].scale];
	}
	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)])
		icon = [(SBAwayCardListItem*)listItem cardThumbnail];
	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)])
		icon = [(SBAwaySystemAlertItem*)listItem iconImage];

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