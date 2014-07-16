#import "PHController.h"
#import "UIImage+AverageColor.h"
#import "Headers.h"
#import <objc/runtime.h>
#import <UIKit/UIImage+Private.h>

#define kPrefsPath @"/var/mobile/Library/Preferences/com.thomasfinch.priorityhub.plist"

//#define DEBUG

#ifndef DEBUG
#define NSLog
#endif

@implementation PHController

@synthesize prefsDict;
@synthesize appListView;
@synthesize curAppID;
@synthesize appSelected;

/*

TO DO

Reminders & calendar for lockscreen compatibility
Passbook compatibility
iPad support

*/

void resetIdleTimer();
void resetTableViewFadeTimers();
void removeBulletinsForAppID(NSString* appID);
int numNotificationsForAppID(NSString* appID);

- (id)init
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M INIT");
    self = [super init];
    if (self)
    {
        appViewsDict = [[NSMutableDictionary alloc] init];
        curAppID = nil;
        appListView = [[UIScrollView alloc] init];
        callCenter = [[CTCallCenter alloc] init];

        selectedView = [[UIView alloc] init];
        selectedView.backgroundColor = [UIColor colorWithWhite:0.75 alpha:0.3];
        selectedView.layer.cornerRadius = 10.0;
        selectedView.layer.masksToBounds = YES;
    }
    return self;
}

- (CGFloat)iconSize
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) //if device is an ipad
        return 40.0;
    else
        return 30.0;
}

- (CGFloat)viewWidth
{
    return [self iconSize] * 1.55;
}

- (CGFloat)viewHeight
{
    if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        return [self iconSize] * 1.85;
    else
        return [self viewWidth];
}

- (void)updatePrefsDict
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M UPDATE PREFS DICT");
    prefsDict = [[NSMutableDictionary alloc] init];
    if ([NSDictionary dictionaryWithContentsOfFile:kPrefsPath]) {
        [prefsDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPath]];
    }

    //Add preferences if they don't already exist
    if (![prefsDict objectForKey:@"showNumbers"])
        [prefsDict setObject:[NSNumber numberWithBool:YES] forKey:@"showNumbers"];
    if (![prefsDict objectForKey:@"showSeparators"]) {
        [prefsDict setObject:[NSNumber numberWithBool:NO] forKey:@"showSeparators"];
    }
    if (![prefsDict objectForKey:@"colorizeSelected"])
        [prefsDict setObject:[NSNumber numberWithBool:YES] forKey:@"colorizeSelected"];
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
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M ICON FOR APP ID");
    NSBundle *iconsBundle = [NSBundle  bundleWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];

    if (img)
        return img;
    else
        return [[[objc_getClass("SBApplicationIcon") alloc] initWithApplication:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:appID]] getIconImage:1];
}

- (void)layoutSubviews
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M LAYOUT SUBVIEWS");
    //Remove all subviews and start fresh
    for (UIView *v in [appListView subviews])
        [v removeFromSuperview];

    [appListView addSubview:selectedView];
    selectedView.hidden = YES;

    //Put all app views in scroll view
    appListView.contentSize = CGSizeMake(0, [self viewHeight]);
    CGFloat totalViewWidth = [[appViewsDict allKeys] count] * [self viewWidth];
    CGFloat startX = (appListView.frame.size.width - totalViewWidth)/2;
    if (startX < 0)
        startX = 0;
    for (UIView *appView in [appViewsDict allValues])
    {
        selectedView.hidden = NO;
        appView.frame = CGRectMake(startX + appListView.contentSize.width, 0, [self viewWidth], [self viewHeight]);
        appListView.contentSize = CGSizeMake(appListView.contentSize.width + [self viewWidth], [self viewHeight]);
        [appListView addSubview:appView];
    }

    NSLog(@"PRIORITYHUB - PHCONTROLLER.M LAYOUT SUBVIEWS DONE");
}

- (void)selectAppID:(NSString*)appID
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M SELECT APP ID: %@",appID);
    if (!appID)
    {
        curAppID = nil;
        [notificationsTableView reloadData];
        [UIView animateWithDuration:0.15 animations:^{
            selectedView.alpha = 0.0;
            notificationsTableView.alpha = 0.0;
        } completion:nil];
    }
    else
    {
        BOOL wasAppSelected = (curAppID != nil);
        curAppID = appID;
        [selectedView setBackgroundColor:[[self iconForAppID:appID] averageColor]];
        [notificationsTableView reloadData];
        if (!wasAppSelected) {
            selectedView.frame = ((UIView*)[appViewsDict objectForKey:appID]).frame;
            appSelected = NO;
        }

        [UIView animateWithDuration:0.15 animations:^{
            selectedView.alpha = 1.0;
            notificationsTableView.alpha = 1.0;
            if (wasAppSelected) {
                appSelected = YES;
                selectedView.frame = ((UIView*)[appViewsDict objectForKey:appID]).frame;
                if ([[prefsDict objectForKey:@"colorizeSelected"] boolValue] == YES) {
                  [selectedView setBackgroundColor:[((UIImageView*)[[appViewsDict objectForKey:appID] subviews][0]).image averageColor]];
                }
            }
        } completion:nil];
    }

    NSLog(@"PRIORITYHUB - PHCONTROLLER.M SELECT APP ID DONE");
}

- (void)addNotificationForAppID:(NSString *)appID
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M ADD NOTIFICATION FOR APP ID: %@",appID);

    //Needed for compatibility with GroupQuiet
    if (numNotificationsForAppID(appID) == 0)
        return;

    if (![appViewsDict objectForKey:appID])
    {
        NSLog(@"PRIORITYHUB - PHCONTROLLER.M NO INFO FOR APP ID, CREATING VIEWS");
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
            numberLabel.textAlignment = NSTextAlignmentCenter;
            [containerView addSubview:numberLabel];
        }
        else
            iconImageView.frame = CGRectMake(([self viewHeight] - [self iconSize])/2, ([self viewWidth] - [self iconSize])/2, [self iconSize], [self iconSize]);

        NSLog(@"PRIORITYHUB - PHCONTROLLER.M DONE CREATING VIEWS");
        [appViewsDict setObject:containerView forKey:appID];
        [self layoutSubviews];
    }
    else
    {
      NSLog(@"PRIORITYHUB - PHCONTROLLER.M NOTIFICATIONS VIEW FOR APP: %@ EXISTS",appID);
      int notificationCount = numNotificationsForAppID(appID);
      if ([[prefsDict objectForKey:@"showNumbers"] boolValue]) {
        NSLog(@"PRIORITYHUB - PHCONTROLLER.M ADD NUMBER");
        ((UILabel*)[[appViewsDict objectForKey:appID] subviews][1]).text = [NSString stringWithFormat:@"%i", notificationCount];
      }
    }

    NSLog(@"PRIORITYHUB - PHCONTROLLER.M ADD NOTIFICATION DONE");
}

- (void)handleSingleTap:(UITapGestureRecognizer*)recognizer
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M HANDLE SINGLE TAP");
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
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M REMOVE NOTIFICATION FOR APP ID: %@",appID);
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
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M REMOVE NOTIFICATIONS FOR APP ID");
    removeBulletinsForAppID(appID);
}

- (void)removeAllNotifications
{
    NSLog(@"PRIORITYHUB - PHCONTROLLER.M REMOVE ALL NOTIFICATIONS");
    for (UIView *appView in [appViewsDict allValues])
        [appView removeFromSuperview];

    [appViewsDict removeAllObjects];
    [self layoutSubviews];
}

-(void)dealloc {
  [super dealloc];
  appViewsDict = nil;
  curAppID = nil;
  appListView = nil;
  callCenter = nil;
  selectedView = nil;
}

@end
