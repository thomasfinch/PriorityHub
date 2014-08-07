#import <objc/runtime.h>
#import <substrate.h>
#import <UIKit/UIKit.h>
#import "PHController.h"
#import "Headers.h"

#ifdef DEBUG
    #define PHLog(fmt, ...) NSLog((@"[PRIORITYHUB] [Line %d] %s: "  fmt), __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
    #define PHLog(fmt, ...)
#endif

static PHController *controller;
static id notificationListView, notificationListController;
static UIRefreshControl* refreshControl;
static BOOL isUnlocked = YES;

NSInvocation *timerInvocation;
NSTimer *idleResetTimer;
//Used to reset the idle timer when an app's view is tapped in priority hub.
//This prevents the phone from locking while you're tapping through your notifications.
extern "C" void resetIdleTimer()
{
    PHLog(@"TWEAK.XM RESET IDLE TIMER");
    PHLog(@"TWEAK.XM SETTING TIMER");
    [notificationListView resetTimers];

    if (timerInvocation) {
      timerInvocation = nil;
    }
    if (idleResetTimer) {
      idleResetTimer = nil;
    }

    BOOL no = NO;
    timerInvocation = [NSInvocation invocationWithMethodSignature:[notificationListView methodSignatureForSelector:@selector(_disableIdleTimer:)]];
    [timerInvocation setSelector:@selector(_disableIdleTimer:)];
    [timerInvocation setTarget:notificationListView];
    [timerInvocation setArgument:&no atIndex:2];

    idleResetTimer = [NSTimer scheduledTimerWithTimeInterval:3.0 invocation:timerInvocation repeats:NO];
    //}
}

//When a new notification comes in, all the other ones are faded out temporarily.
//This resets them when a different app's view is selected.
extern "C" void resetTableViewFadeTimers()
{
    PHLog(@"TWEAK.XM RESET TABLE VIEW FADE TIMERS");
    [notificationListView _resetAllFadeTimers];
}

extern "C" void removeBulletinsForAppID(NSString* appID)
{
    PHLog(@"TWEAK.XM REMOVE BULLETINS FOR APP ID: %@",appID);
    [MSHookIvar<BBObserver*>(notificationListController, "_observer") clearSection:appID];
}

//Returns the number of lock screen notifications stored for the given app ID
int count;
extern "C" int numNotificationsForAppID(NSString* appID)
{
    count = 0;
    PHLog(@"TWEAK.XM - START COUNTING NOTIFICATIONS");
    for (id listItem in MSHookIvar<NSMutableArray*>(notificationListController,"_listItems")) {
      if (([listItem isKindOfClass:[%c(SBAwayBulletinListItem) class]]) && [[[listItem activeBulletin] sectionID] isEqual:appID]) {
        PHLog(@"TWEAK.XM - SBAWAYBULLETINLISTITEM ADDED");
        count++;
      } else {
        PHLog(@"TWEAK.XM - ITEM IS NOT VALID: %@", listItem);
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
    PHLog(@"TWEAK.XM LOCK STATE CHANGE");
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

UIView *containerView;
UITableView *notificationsTableView;

- (void)layoutSubviews
{
    PHLog(@"TWEAK.XM LAYOUT SUBVIEWS");
    %orig;
    notificationListView = self;
    containerView = MSHookIvar<UIView*>(self, "_containerView");
    notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
    MSHookIvar<UITableView*>(controller, "notificationsTableView") = notificationsTableView;

    //Add refresh control for clearing notifications
    if (refreshControl)
      [refreshControl removeFromSuperview];

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
    } else {
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
    PHLog(@"TWEAK.XM DONE LAYOUT SUBVIEWS");
}

%new
- (void)handlePullToClear
{
    PHLog(@"TWEAK.XM PULL TO CLEAR");
    [refreshControl endRefreshing];
    [controller removeAllNotificationsForAppID:controller.curAppID];
}

%new
-(void)resetTimers {
  [self _disableIdleTimer:YES];
  [self _resetAllFadeTimers];
}


//Returns 0 for table view cells that aren't notifications of the current selected app. This is an easy way to make them "disappear" when their app is not selected.
id modelItem;
CGFloat height;

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  PHLog(@"TWEAK.XM TABLEVIEW HEIGHT FOR ROW AT INDEXPATH");
  modelItem = nil;
  height = 0.0;
  PHLog(@"TWEAK.XM PRE-MODELITEM");
  modelItem = [self.model listItemAtIndexPath:indexPath];
  PHLog(@"TWEAK.XM POST-MODELITEM: %@",modelItem);

  PHLog(@"TWEAK.XM START MODELITEM FILTER");

  if ([controller curAppID] && [[controller curAppID] isKindOfClass:[NSString class]]) {
    PHLog(@"TWEAK.XM CURAPPID IS VALID");
    if (modelItem && ([modelItem isKindOfClass:[%c(SBAwayBulletinListItem) class]] || [modelItem isKindOfClass:[%c(SBSnoozedAlarmBulletinListItem) class]])) {
      PHLog(@"TWEAK.XM MODELITEM IS VALID SBAWAYBULLETINLISTITEM OR VALID SUBCLASS");
      if ([[controller curAppID] isEqual:[[modelItem activeBulletin] sectionID]])  {
        PHLog(@"TWEAK.XM MODELITEM HAS CURAPPID");
        height = %orig;
      }
      PHLog(@"TWEAK.XM MODELITEM CREATING HEIGHT OF %f",height);
    }
  }

  PHLog(@"TWEAK.XM RETURN HEIGHT");
  if (height && height != 0.0) {
    return height;
  } else {
    return 0.0;
  }
}

- (void)setInScreenOffMode:(BOOL)screenOff
{
    PHLog(@"TWEAK.XM SET IN SCREEN OFF MODE");
    if ([[controller.prefsDict objectForKey:@"collapseOnLock"] intValue] == 1) {
      if (screenOff)
          [controller selectAppID:nil];
    }
    %orig;
}


%end

%hook SBLockScreenNotificationListController

-(void)loadView {
  %orig;
  PHLog(@"TWEAK.XM INITIALIZE NOTIFICATIONLISTCONTROLLER IF NEEDED");
  if (notificationListController)
    notificationListController = nil;
}

BOOL currentCallsExist;
- (void)observer:(BBObserver*)observer addBulletin:(BBBulletin*)bulletin forFeed:(unsigned long long)feed
{
  currentCallsExist = ([MSHookIvar<CTCallCenter*>(controller,"callCenter") currentCalls] || [[MSHookIvar<CTCallCenter*>(controller,"callCenter") currentCalls] count] > 0);

  PHLog(@"TWEAK.XM OBSERVER: %@ ADDING BULLETIN: %@",observer,bulletin);

  notificationListController = self;
  %orig;
  [controller addNotificationForAppID:[bulletin sectionID]];


  if ([[controller.prefsDict objectForKey:@"privacyModeEnabled"] intValue] == 0  && (!currentCallsExist && ![[%c(IMAVCallManager) sharedInstance] hasActiveCall])) {//If there are no active phone or facetime calls (causes crashes otherwise)
    [controller selectAppID:[bulletin sectionID]];
  }
}

- (void)observer:(BBObserver*)observer removeBulletin:(BBBulletin*)bulletin
{
    PHLog(@"TWEAK.XM OBSERVER: %@ REMOVING BULLETIN: %@",observer,bulletin);
    [controller removeNotificationForAppID:[bulletin sectionID]];
    %orig;
}

%end

%hook SBLockScreenNotificationCell

//Removes the lines between notification items. Not really necessary, I just thought it looked better. (Now opt-out via settings panel)
id orig;
- (id)initWithStyle:(long long)arg1 reuseIdentifier:(NSString*)arg2
{
  orig = %orig;
  if ([[controller.prefsDict objectForKey:@"showSeparators"] intValue] == 0) {
    MSHookIvar<UIView*>(orig,"_topSeparatorView") = nil;
    MSHookIvar<UIView*>(orig,"_bottomSeparatorView") = nil;
  }
  return orig;
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
    PHLog(@"TWEAK.XM DISMISS ALL NOTIFICATIONS BEFORE NCVC PRESENT");
    [controller removeAllNotifications];
    [controller.appListView removeFromSuperview];
  }
}

%end

%hook UIRefreshControl

//Makes the pull-to-clear refresh control more "sensitive" (i.e., you don't have to pull down as far to clear) on shorter devices (iPhone 4 & 4S)
- (double)_visibleHeightForContentOffset:(struct CGPoint)arg1 origin:(struct CGPoint)arg2
{
    if ([self isEqual:refreshControl] && [UIScreen mainScreen].bounds.size.height == 480) {
        return %orig * 3;
    } else {
      return %orig;
    }
}

%end
