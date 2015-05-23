#import "PHView.h"
#import "substrate.h"

#ifdef DEBUG
	#define PHLog(fmt, ...) NSLog((@"PRIORITY HUB [Line %d]: " fmt), __LINE__, ##__VA_ARGS__)
#else
	#define PHLog(...)
#endif

@implementation PHView

@synthesize selectedAppID;

- (id)init {
	if (self = [super init]) {
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
	PHLog(@"PHVIEW UPDATE VIEW");
	NSMutableDictionary *bulletinCountDict = [[NSMutableDictionary alloc] init], *iconDict = [[NSMutableDictionary alloc] init];
	if (!_listController)
		return;

	//Count the number of bulletins for each app ID
	for (SBAwayListItem *listItem in MSHookIvar<NSMutableArray*>(_listController, "_listItems")) {
		NSString *bulletinID = [self identifierForListItem:listItem];

		//Add count and icon to dictionaries
		if ([bulletinCountDict objectForKey:bulletinID])
			[bulletinCountDict setObject:[NSNumber numberWithInt:[[bulletinCountDict objectForKey:bulletinID] intValue] + 1] forKey:bulletinID];
		else {
			[bulletinCountDict setObject:[NSNumber numberWithInt:1] forKey:bulletinID];
			[iconDict setObject:[self iconForListItem:listItem] forKey:bulletinID];
		}
	}

    //Create or update app views from the current bulletin list
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [appViews removeAllObjects];
    [self addSubview:selectedView];
    for (NSString *appID in [bulletinCountDict allKeys]) {
    	PHAppView *appView = [[PHAppView alloc] initWithFrame:CGRectMake(0,0,[self appViewSize].width,[self appViewSize].height) appID:appID icon:[iconDict objectForKey:appID]];
    	[appView updateNumNotifications:[[bulletinCountDict objectForKey:appID] unsignedIntegerValue]];
    	[appViews setObject:appView forKey:appID];
    	[self addSubview:appView];
    }

    //Layout all app views
	CGFloat totalWidth = [[appViews allKeys] count] * [self appViewSize].width;
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

	PHLog(@"PHVIEW SELECT APP ID");
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
}

- (NSString*)identifierForListItem:(SBAwayListItem*)listItem {
	if ([listItem isKindOfClass:%c(SBAwayBulletinListItem)])
		return [[(SBAwayBulletinListItem*)listItem activeBulletin] sectionID];
	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)])
		return [[(SBAwayCardListItem*)listItem cardItem] identifier];
	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)])
		return [(SBAwaySystemAlertItem*)listItem title];
	else
		return @"noIdentifier";
}

- (UIImage*)iconForListItem:(SBAwayListItem*)listItem {
	if ([listItem isKindOfClass:%c(SBAwayBulletinListItem)]) {
		//Get custom priority hub icon if it exists
		NSBundle *iconsBundle = [NSBundle  bundleWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
	    UIImage *img = [[UIImage class] performSelector:@selector(imageNamed:inBundle:) withObject:[NSString stringWithFormat:@"%@.png",[self identifierForListItem:listItem]] withObject:iconsBundle]; //[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];

	    if (img)
	        return img;
	    else
	        return [UIImage _applicationIconImageForBundleIdentifier:[self identifierForListItem:listItem] format:0 scale:[UIScreen mainScreen].scale];
	}
	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)])
		return [(SBAwayCardListItem*)listItem iconImage];
	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)])
		return [(SBAwaySystemAlertItem*)listItem iconImage];
	else
		return [UIImage imageWithData:[NSData data]];
}

- (CGSize)appViewSize {
	CGFloat width = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 56.0 : 42.0;
	if ([defaults boolForKey:@"showNumbers"] && [defaults integerForKey:@"numberStyle"] == 0) //If numbers are enabled and below icon
		return CGSizeMake(width, width * 1.3);
	else
		return CGSizeMake(width, width);
}

@end