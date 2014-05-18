#import <objc/runtime.h>
#import <substrate.h>
#import "PHController.h"

static PHController *controller;
static id notificationListView, notificationListController;
static NSTimer *idleResetTimer;
static UIRefreshControl* refreshControl;

extern "C" void resetIdleTimer()
{
    NSLog(@"RESET IDLE TIMER");

    if (![idleResetTimer isValid])
    {
        NSLog(@"SETTING TIMER");
        [notificationListView _disableIdleTimer:YES];

        //NSInvocation needed to send BOOL argument to notificationListView when the timer ends
        //So complicated and messy :(
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[[notificationListView class] instanceMethodSignatureForSelector:@selector(_disableIdleTimer:)]];
        [invocation setTarget:notificationListView];
        [invocation setSelector:@selector(_disableIdleTimer:)];
        BOOL no = NO;
        [invocation setArgument:&no atIndex:2];
        if (idleResetTimer)
            [idleResetTimer release];
        idleResetTimer = [[NSTimer scheduledTimerWithTimeInterval:3 invocation:invocation repeats:NO] retain];
    }
}

extern "C" void resetTableViewFadeTimers()
{
    NSLog(@"RESET TABLE VIEW FADE TIMERS");
    [notificationListView _resetAllFadeTimers];
}

extern "C" void removeBulletinsForAppID(NSString* appID)
{
    NSLog(@"REMOVE FULLETINS FOR APP ID");
    [MSHookIvar<id>(notificationListController, "_observer") clearSection:appID];
}

extern "C" int numNotificationsForAppID(NSString* appID)
{
    int count = 0;
    for (id listItem in MSHookIvar<NSMutableArray*>(notificationListController, "_listItems"))
        if ([[[listItem activeBulletin] sectionID] isEqualToString:appID])
            count++;
    return count;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer,CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [controller updatePrefsDict];
}

%ctor
{
	controller = [[PHController alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.thomasfinch.priorityhub-prefschanged"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
	[controller updatePrefsDict];
}


%hook SBLockScreenNotificationListView

- (void)layoutSubviews
{
    NSLog(@"TWEAK.XM LAYOUT SUBVIEWS");
    %orig;
    notificationListView = self;
    UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
    UITableView *notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
    MSHookIvar<UITableView*>(controller, "notificationsTableView") = notificationsTableView;

    //Add refresh control for clearing notifications
    if (refreshControl)
        [refreshControl release];
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    [refreshControl addTarget:self action:@selector(handlePullToClear) forControlEvents:UIControlEventValueChanged];
    [notificationsTableView addSubview:refreshControl];

    if ([[controller.prefsDict objectForKey:@"iconLocation"] intValue] == 0) //Icons are at top
    {
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + [controller viewHeight] + 2.5, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight]);
        notificationsTableView.frame = CGRectMake(0, 0, notificationsTableView.frame.size.width, containerView.frame.size.height);
    }
    else
    {
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight] - 2.5);
        notificationsTableView.frame = CGRectMake(0, 0, notificationsTableView.frame.size.width, containerView.frame.size.height);
    }

    controller.appListView.frame =  ([[[controller prefsDict] objectForKey:@"iconLocation"] intValue] == 0) ? CGRectMake(0, containerView.frame.origin.y - [controller viewHeight] - 2.5, containerView.frame.size.width, [controller viewHeight]) : CGRectMake(0, containerView.frame.origin.y + containerView.frame.size.height + 2.5, containerView.frame.size.width, [controller viewHeight]);
    [controller layoutSubviews];
    [self addSubview:controller.appListView];
    NSLog(@"TWEAK.XM DONE LAYOUT OUT SUBVIEWS");
}

%new
- (void)handlePullToClear
{
    NSLog(@"PULL TO CLEAR");
    [refreshControl endRefreshing];
    [controller removeAllNotificationsForAppID:controller.curAppID];
}

- (double)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSLog(@"TABLEVIEW HEIGHT FOR ROW AT INDEXPATH");
    if (![controller curAppID] || ![[controller curAppID] isEqualToString:[[[MSHookIvar<id>(self, "_model") listItemAtIndexPath:indexPath] activeBulletin] sectionID]])
        return 0;
    else
        return %orig;
}

- (void)setInScreenOffMode:(BOOL)screenOff
{
    NSLog(@"SET IN SCREEN OFF MODE");
    if (screenOff)
        [controller selectAppID:nil];
    %orig;
}

%end

%hook SBLockScreenNotificationListController

- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(unsigned long long)feed
{
    NSLog(@"TWEAK.XM OBSERVER ADD BULLETIN");
    %orig;
    notificationListController = self;
    [controller addNotificationForAppID:[bulletin sectionID]];
}

- (void)observer:(id)observer removeBulletin:(id)bulletin
{
    NSLog(@"TWEAK.XM OBSERVER REMOVE BULLETIN");
	%orig;
	[controller removeNotificationForAppID:[bulletin sectionID]];
}

- (void)prepareForTeardown
{
    NSLog(@"LIST CONTROLLER PREPARE FOR TEARDOWN");
    %orig;
}

- (void)unlockUIWithActionContext:(id)arg1
{
    NSLog(@"UNLOCK UI WITH ACTION CONTEXT");
    %orig;
}

%end

%hook SBLockScreenManager
- (void)_setUILocked:(BOOL)locked
{
    NSLog(@"TWEAK.XM SET UI LOCKED");
    //When device is unlocked, clear all notification views from the lockscreen
    if (!locked)
        [controller removeAllNotifications];

    %orig;
}
%end

%hook SBLockScreenNotificationCell
- (id)initWithStyle:(long long)arg1 reuseIdentifier:(id)arg2
{
    id orig = %orig;
    MSHookIvar<UIView*>(orig,"_topSeparatorView") = nil;
    MSHookIvar<UIView*>(orig,"_bottomSeparatorView") = nil;
    return orig;
}
%end
