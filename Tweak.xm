#import <objc/runtime.h>
#import <substrate.h>
#import "PHController.h"

static PHController *controller;
static BOOL isLocked = YES;
static id notificationListView;
static NSTimer *idleResetTimer;

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
    UITableView *notificationTableView = MSHookIvar<UITableView*>(self, "_tableView");
    MSHookIvar<UITableView*>(controller, "notificationsTableView") = notificationTableView;

    if ([[controller.prefsDict objectForKey:@"iconLocation"] intValue] == 0) //Icons are at top
    {
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + [controller viewHeight] + 2.5, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight]);
        notificationTableView.frame = CGRectMake(0, 0, notificationTableView.frame.size.width, containerView.frame.size.height);
    }
    else
    {
        containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, containerView.frame.size.height - [controller viewHeight] - 2.5);
        notificationTableView.frame = CGRectMake(0, 0, notificationTableView.frame.size.width, containerView.frame.size.height);
    }

    controller.appListView.frame =  ([[[controller prefsDict] objectForKey:@"iconLocation"] intValue] == 0) ? CGRectMake(0, containerView.frame.origin.y - [controller viewHeight] - 2.5, containerView.frame.size.width, [controller viewHeight]) : CGRectMake(0, containerView.frame.origin.y + containerView.frame.size.height + 2.5, containerView.frame.size.width, [controller viewHeight]);
    [controller layoutSubviews];
    [self addSubview:controller.appListView];
    NSLog(@"TWEAK.XM DONE LAYOUT OUT SUBVIEWS");
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
    if (screenOff && isLocked)
        [controller selectAppID:nil];
    %orig;
}

%end

%hook SBLockScreenNotificationListController

- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(unsigned long long)feed
{
    NSLog(@"TWEAK.XM OBSERVER ADD BULLETIN");
    %orig;
    isLocked = YES;
    [controller addNotificationForAppID:[bulletin sectionID]];
}

- (void)observer:(id)observer removeBulletin:(id)bulletin
{
    NSLog(@"TWEAK.XM OBSERVER REMOVE BULLETIN");
	%orig;
	[controller removeNotificationForAppID:[bulletin sectionID]];
}

%end

%hook SBLockScreenManager
- (void)_setUILocked:(BOOL)locked
{
    NSLog(@"TWEAK.XM SET UI LOCKED");
    //When device is unlocked, clear all notification views from the lockscreen
    if (!locked)
    {
        [controller removeAllNotifications];
        isLocked = NO;
    }
    
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