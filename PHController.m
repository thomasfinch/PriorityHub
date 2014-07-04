#import "PHController.h"

#define kPrefsPath @"/var/mobile/Library/Preferences/com.thomasfinch.priorityhub.plist"

#ifndef DEBUG
#define NSLog
#endif

@implementation PHController

@synthesize prefsDict;
@synthesize appListView;
@synthesize curAppID;


/*

TO DO

Reminders & calendar for lockscreen compatibility
Passbook compatibility

*/

void resetIdleTimer();
void resetTableViewFadeTimers();
void removeBulletinsForAppID(NSString* appID);
int numNotificationsForAppID(NSString* appID);

- (id)init
{
    NSLog(@"CONTROLLER INIT");
    self = [super init];
    if (self)
    {
        appViewsDict = [[NSMutableDictionary alloc] init];
        curAppID = nil;
        appListView = [[UIScrollView alloc] init];
        callCenter = [[CTCallCenter alloc] init];

        selectedView = [[UIView alloc] init];
        selectedView.backgroundColor = [UIColor colorWithWhite:0.75f alpha:0.3f];
        selectedView.layer.cornerRadius = 10.0f;
        selectedView.layer.masksToBounds = YES;
    }
    return self;
}

- (float)iconSize
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) //if device is an ipad
        return 40.0f;
    else
        return 30.0f;
}

- (float)viewWidth
{
    return [self iconSize] * 1.55;
}

- (float)viewHeight
{
    if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        return [self iconSize] * 1.85;
    else
        return [self viewWidth];
}

- (void)updatePrefsDict
{
    NSLog(@"CONTROLLER UPDATE PREFS DICT");
    if (prefsDict)
        [prefsDict release];
    prefsDict = [[NSMutableDictionary alloc] init];
    if ([NSDictionary dictionaryWithContentsOfFile:kPrefsPath]) {
        [prefsDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPath]];
    }

    //Add preferences if they don't already exist
    if (![prefsDict objectForKey:@"showNumbers"])
        [prefsDict setObject:[NSNumber numberWithBool:YES] forKey:@"showNumbers"];
    if (![prefsDict objectForKey:@"iconLocation"])
        [prefsDict setObject:[NSNumber numberWithInt:0] forKey:@"iconLocation"];

    [prefsDict writeToFile:kPrefsPath atomically:YES];
}

- (BOOL)isTweakInstalled:(NSString *)name
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/MobileSubstrate/DynamicLibraries/%@.dylib",name]];
}

- (UIImage *)iconForAppID:(NSString *)appID
{
    NSLog(@"CONTROLLER ICON FOR APP ID");
    NSBundle *iconsBundle = [NSBundle  bundleWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];

    if (img)
        return img;
    else
        return [[[objc_getClass("SBApplicationIcon") alloc] initWithApplication:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:appID]] getIconImage:1];
}

- (void)layoutSubviews
{
    NSLog(@"CONTROLLER LAYOUT SUBVIEWS");
    //Remove all subviews and start fresh
    for (UIView *v in [appListView subviews])
        [v removeFromSuperview];

    [appListView addSubview:selectedView];
    selectedView.hidden = YES;

    //Put all app views in scroll view
    appListView.contentSize = CGSizeMake(0, [self viewHeight]);
    float totalViewWidth = [[appViewsDict allKeys] count] * [self viewWidth];
    float startX = (appListView.frame.size.width - totalViewWidth)/2;
    if (startX < 0)
        startX = 0;
    for (UIView *appView in [appViewsDict allValues])
    {
        selectedView.hidden = NO;
        appView.frame = CGRectMake(startX + appListView.contentSize.width, 0, [self viewWidth], [self viewHeight]);
        appListView.contentSize = CGSizeMake(appListView.contentSize.width + [self viewWidth], [self viewHeight]);
        [appListView addSubview:appView];
    }

    NSLog(@"CONTROLLER LAYOUT SUBVIEWS DONE");
}

- (void)selectAppID:(NSString*)appID
{
    NSLog(@"CONTROLLER SELECT APP ID: %@",appID);
    if (!appID)
    {
        curAppID = nil;
        [notificationsTableView reloadData];

        [UIView animateWithDuration:0.15f animations:^{
            selectedView.alpha = 0.0f;
            notificationsTableView.alpha = 0.0f;
        }completion:^(BOOL completed){}];
    }
    else
    {
        BOOL wasAppSelected = (curAppID != nil);
        curAppID = appID;
        [notificationsTableView reloadData];
        if (!wasAppSelected)
            selectedView.frame = ((UIView*)[appViewsDict objectForKey:appID]).frame;

        [UIView animateWithDuration:0.15f animations:^{
            selectedView.alpha = 1.0f;
            notificationsTableView.alpha = 1.0f;
            if (wasAppSelected)
                selectedView.frame = ((UIView*)[appViewsDict objectForKey:appID]).frame;
        }completion:^(BOOL completed){}];
    }

    NSLog(@"CONTOLLER SELECT APP ID DONE");
}

- (void)addNotificationForAppID:(NSString *)appID
{
    NSLog(@"CONTROLLER ADD NOTIFICATION FOR APP ID: %@",appID);

    //Needed for compatibility with GroupQuiet
    if (numNotificationsForAppID(appID) == 0)
        return;

    if (![appViewsDict objectForKey:appID])
    {
        NSLog(@"NO INFO FOR APP ID, CREATING VIEWS");
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(appListView.contentSize.width, 0, [self viewWidth], [self viewHeight])];
        containerView.tag = 1;

        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [containerView addGestureRecognizer:singleFingerTap];

        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[self iconForAppID:appID]];
        iconImageView.frame = CGRectMake(([self viewWidth] - [self iconSize])/2, 5, [self iconSize], [self iconSize]);
        [containerView addSubview:iconImageView];

        if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        {
            UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, iconImageView.frame.origin.y + iconImageView.frame.size.height + ((containerView.frame.size.height - (iconImageView.frame.origin.y + iconImageView.frame.size.height)) - 15) / 2, [self viewWidth], 15)];
            numberLabel.text = @"1";
            numberLabel.textColor = [UIColor whiteColor];
            numberLabel.textAlignment = UITextAlignmentCenter;
            [containerView addSubview:numberLabel];
        }
        else
            iconImageView.frame = CGRectMake(([self viewHeight] - [self iconSize])/2, ([self viewWidth] - [self iconSize])/2, [self iconSize], [self iconSize]);

        NSLog(@"DONE CREATING VIEWS");
        [appViewsDict setObject:containerView forKey:appID];
        [self layoutSubviews];
    }
    else
    {
        int notificationCount = numNotificationsForAppID(appID);
        if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
            ((UILabel*)[[appViewsDict objectForKey:appID] subviews][1]).text = [NSString stringWithFormat:@"%i", notificationCount];
    }

    if (!callCenter.currentCalls && ![[objc_getClass("IMAVCallManager") sharedInstance] hasActiveCall]) //If there are no active phone or facetime calls (causes crashes otherwise)
        [self selectAppID:appID];

    NSLog(@"CONTROLLER ADD NOTIFICATION DONE");
}

- (void)handleSingleTap:(UITapGestureRecognizer*)recognizer
{
    NSLog(@"CONTROLLER HANDLE SINGLE TAP");
    resetTableViewFadeTimers();
    resetIdleTimer();
    NSString *appID = [appViewsDict allKeysForObject:recognizer.view][0];
    if ([appID isEqualToString:curAppID])
        [self selectAppID:nil];
    else
        [self selectAppID:appID];
}

- (void)removeNotificationForAppID:(NSString *)appID
{
    NSLog(@"CONTROLLER REMOVE NOTIFICATION FOR APP ID: %@",appID);
    int notificationCount = numNotificationsForAppID(appID);
    if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        ((UILabel*)[[appViewsDict objectForKey:appID] subviews][1]).text = [NSString stringWithFormat:@"%i", notificationCount];

    if (notificationCount == 0)
    {
        [[appViewsDict objectForKey:appID] removeFromSuperview];
        [appViewsDict removeObjectForKey:appID];
        if ([curAppID isEqualToString:appID])
            [self selectAppID:nil];
        [self layoutSubviews];
    }
}

- (void)removeAllNotificationsForAppID:(NSString *)appID
{
    NSLog(@"CONTROLLER REMOVE NOTIFICATIONS FOR APP ID");
    removeBulletinsForAppID(appID);
}

- (void)removeAllNotifications
{
    NSLog(@"CONTROLLER REMOVE ALL NOTIFICATIONS");
    for (UIView *appView in [appViewsDict allValues])
        [appView removeFromSuperview];

    [appViewsDict removeAllObjects];
    [self layoutSubviews];
}

@end
