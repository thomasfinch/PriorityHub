#import <objc/runtime.h>
#import <substrate.h>
#import "PHController.h"
//#define DEBUG

#ifndef DEBUG
#define NSLog
#endif

static PHController *controller;
static id notificationListView, notificationListController;
static NSTimer *idleResetTimer;
static UIRefreshControl* refreshControl;
static BOOL isUnlocked = YES;

//Used to reset the idle timer when an app's view is tapped in priority hub.
//This prevents the phone from locking while you're tapping through your notifications.
extern "C" void resetIdleTimer()
{
    NSLog(@"PRIORITYHUB - TWEAK.XM RESET IDLE TIMER");

    if (![idleResetTimer isValid])
    {
        NSLog(@"PRIORITYHUB - TWEAK.XM SETTING TIMER");
        [notificationListView _disableIdleTimer:YES];

        //NSInvocation needed to send BOOL argument to notificationListView when the timer ends
        //So complicated and messy :(
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[[notificationListView class] instanceMethodSignatureForSelector:@selector(_disableIdleTimer:)]];
        [invocation setTarget:notificationListView];
        [invocation setSelector:@selector(_disableIdleTimer:)];
        BOOL no = NO;
        [invocation setArgument:&no atIndex:2];
        /*if (idleResetTimer)
            [idleResetTimer release];*/
        idleResetTimer = [[NSTimer scheduledTimerWithTimeInterval:3 invocation:invocation repeats:NO] retain];
    }
}

//When a new notification comes in, all the other ones are faded out temporarily.
//This resets them when a different app's view is selected.
extern "C" void resetTableViewFadeTimers()
{
    NSLog(@"PRIORITYHUB - TWEAK.XM RESET TABLE VIEW FADE TIMERS");
    [notificationListView _resetAllFadeTimers];
}

extern "C" void removeBulletinsForAppID(NSString* appID)
{
    NSLog(@"PRIORITYHUB - TWEAK.XM REMOVE BULLETINS FOR APP ID");
    [MSHookIvar<id>(notificationListController, "_observer") clearSection:appID];
}

//Returns the number of lock screen notifications stored for the given app ID
extern "C" int numNotificationsForAppID(NSString* appID)
{
    int count = 0;
    for (id listItem in MSHookIvar<NSMutableArray*>(notificationListController, "_listItems")) {
      if ([listItem isKindOfClass:[%c(SBAwayBulletinListItem) class]] && [[[listItem activeBulletin] sectionID] isEqualToString:appID]) {
        count++;
      } else {
        NSLog(@"PRIORITYHUB - TWEAK.XM LIST ITEM CLASS: %@",NSStringFromClass([listItem class]));
      }
    }
    return count;
}

//Called when any preference is changed in the settings app
static void prefsChanged(CFNotificationCenterRef center, void *observer,CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [controller updatePrefsDict];
}

//Called when the device is locked/unlocked. Resets views if device was unlocked.
static void lockStateChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    isUnlocked = !isUnlocked;
    NSLog(@"PRIORITYHUB - TWEAK.XM LOCK STATE CHANGE");
    if (isUnlocked)
        [controller removeAllNotifications];
}

%ctor
{
    //Initialize controller and set up Darwin notifications for preference changes and lock state changes
    controller = [[PHController alloc] init];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.thomasfinch.priorityhub-prefschanged"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, lockStateChanged, CFSTR("com.apple.springboard.lockstate"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    [controller updatePrefsDict];

    //dlopen'ing subtlelock causes its dylib to be loaded and executed first
    //This fixes a lot of layout problems because then priority hub's layout code runs last and
    //has the last say in the layout of some views.
    dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
}


%hook SBLockScreenNotificationListView

- (void)layoutSubviews
{
    NSLog(@"PRIORITYHUB - TWEAK.XM LAYOUT SUBVIEWS");
    %orig;
    notificationListView = self;
    UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
    UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
    MSHookIvar<UITableView*>(controller, "notificationsTableView") = notificationsTableView;

    //Add refresh control for clearing notifications
    if (refreshControl)
    {
        [refreshControl removeFromSuperview];
        //[refreshControl release];
    }
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(handlePullToClear) forControlEvents:UIControlEventValueChanged];
    [notificationsTableView addSubview:refreshControl];

    //Adjust the height of containerView if subtlelock is installed and enabled
    CGFloat containerOffset = ([controller isTweakInstalled:@"SubtleLock"] && [[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michaelpoole.subtlelock.plist"] objectForKey:@"Enabled"] boolValue]) ? [controller viewHeight] : 0;

    //Adjust the heights and locations of the container view and table view based on the icon location
    if ([[controller.prefsDict objectForKey:@"iconLocation"] intValue] == 0) //If icons are at the top
    {
      //Top
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + [controller viewHeight] + 2.5, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight] - containerOffset);
    }
    else
    {
      //Bottom
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight] - 2.5 - containerOffset);

    }

    notificationsTableView.frame = CGRectMake(0, 0, notificationsTableView.frame.size.width, containerView.frame.size.height);

    //Set the frame for the app icon view based on its location
    if ([[[controller prefsDict] objectForKey:@"iconLocation"] intValue] == 0) { //If icons are at the top
        controller.appListView.frame = CGRectMake(0, containerView.frame.origin.y - [controller viewHeight] - 2.5, containerView.frame.size.width, [controller viewHeight]);
    } else {
        controller.appListView.frame = CGRectMake(0, containerView.frame.origin.y + containerView.frame.size.height + 2.5, containerView.frame.size.width, [controller viewHeight]);
    }

    [controller layoutSubviews];
    [self addSubview:controller.appListView];
    NSLog(@"PRIORITYHUB - TWEAK.XM DONE LAYOUT OUT SUBVIEWS");
}

%new
- (void)handlePullToClear
{
    NSLog(@"PRIORITYHUB - TWEAK.XM PULL TO CLEAR");
    [refreshControl endRefreshing];
    [controller removeAllNotificationsForAppID:controller.curAppID];
}

//Returns 0 for table view cells that aren't notifications of the current selected app. This is an easy way to make them "disappear" when their app is not selected.
id modelItem;
- (double)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"PRIORITYHUB - TWEAK.XM TABLEVIEW HEIGHT FOR ROW AT INDEXPATH");
    modelItem = [MSHookIvar<id>(self, "_model") listItemAtIndexPath:indexPath];
    NSLog(@"PRIORITYHUB - TWEAK.XM ITEM: %@",modelItem);
    if (![[controller curAppID] isKindOfClass:[NSString class]]) // wtf?
        return 0.0;

    if (![controller curAppID] || ([modelItem isKindOfClass:[%c(SBAwayBulletinListItem) class]] && ![[controller curAppID] isEqualToString:[[modelItem activeBulletin] sectionID]]))
        return 0.0;
    else
        return %orig;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return NO;
}

- (void)setInScreenOffMode:(BOOL)screenOff
{
    NSLog(@"PRIORITYHUB - TWEAK.XM SET IN SCREEN OFF MODE");
    if (screenOff)
        [controller selectAppID:nil];
    %orig;
}

%end

%hook SBLockScreenNotificationListController

- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(unsigned long long)feed
{
    NSLog(@"PRIORITYHUB - TWEAK.XM OBSERVER: %@ ADDING BULLETIN: %@",observer,bulletin);
    //NSLog(@"PRIORITYHUB - TWEAK.XM OBSERVER ADD BULLETIN");
    %orig;
    notificationListController = self;
    [controller addNotificationForAppID:[bulletin sectionID]];
}

- (void)observer:(id)observer removeBulletin:(id)bulletin
{
    NSLog(@"PRIORITYHUB - TWEAK.XM OBSERVER: %@ REMOVING BULLETIN: %@",observer,bulletin);
    //NSLog(@"PRIORITYHUB - TWEAK.XM OBSERVER REMOVE BULLETIN");
    %orig;
    [controller removeNotificationForAppID:[bulletin sectionID]];
}

%end

%hook SBLockScreenNotificationCell

//Removes the lines between notification items. Not really necessary, I just thought it looked better. (Now opt-out via settings panel)
- (id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2
{
    if (!controller.showSeparators || [[controller.prefsDict objectForKey:@"showSeparators"] intValue] == 0) {
      id orig = %orig;
      MSHookIvar<UIView*>(orig,"_topSeparatorView") = nil;
      MSHookIvar<UIView*>(orig,"_bottomSeparatorView") = nil;
      return orig;
    } else {
      return %orig;
    }
}

%end

/*v1.1.4 of this tweak and its predecessors has/had a bug where if a user tried to dismiss a notification by
swiping down the NC, the NC would stutter and refuse to open on the first try, then open completely on the
second try and dismiss the notification, but leave the PriorityHub view on-screen. Hooking this method (called
when the NC is presented) and removing the view from the screen prevents this issue.*/

%hook SBNotificationCenterViewController

-(void)hostWillPresent {
  %orig;
  if (controller) {
    NSLog(@"PRIORITYHUB - TWEAK.XM DISMISS ALL NOTIFICATIONS BEFORE NCVC PRESENT");
    [controller removeAllNotifications];
    [controller.appListView removeFromSuperview];
  }
}

%end

%hook UIRefreshControl

//Makes the pull-to-clear refresh control more "sensitive" (i.e., you don't have to pull down as far to clear) on shorter devices (iPhone 4 & 4S)
- (double)_visibleHeightForContentOffset:(struct CGPoint)arg1 origin:(struct CGPoint)arg2
{
    if (self == refreshControl && [UIScreen mainScreen].bounds.size.height == 480)
        return %orig * 2.5;
    return %orig;
}

%end

//Enables blur only when notifications are displayed (suggestion by /u/jiznon on Reddit)
%hook SBLockOverlayStyleProperties

-(double)blurRadius {
  if ([[controller.prefsDict objectForKey:@"enableBlurs"] intValue] == 1) {
    if (controller.appSelected) {
      return %orig;
    } else {
      return 0;
    }
  } else {
    return %orig;
  }
}

%end
