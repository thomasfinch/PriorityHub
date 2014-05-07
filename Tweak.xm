#import <objc/runtime.h>
#import <substrate.h>
#import "PHController.h"

static PHController *controller;
static BOOL isLocked = YES;

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
    %orig;
    UIView *containerView = MSHookIvar<UIView*>(self,"_containerView");
    UITableView *notificationTableView = MSHookIvar<UITableView*>(self,"_tableView");

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
}

- (void)setInScreenOffMode:(BOOL)screenOff
{
    if (screenOff && isLocked)
        [controller selectAppID:nil];
    %orig;
}

%end

%hook SBLockScreenNotificationListController

- (void)observer:(id)observer addBulletin:(id)bulletin forFeed:(unsigned long long)feed
{
    %orig;
    isLocked = YES;
    [controller addNotificationForAppID:[bulletin sectionID]];
}

- (void)observer:(id)observer removeBulletin:(id)bulletin
{
	%orig;
	[controller removeNotificationForAppID:[bulletin sectionID]];
}

%end

%hook SBLockScreenManager
- (void)_setUILocked:(BOOL)locked
{
    //When device is unlocked, clear all notifications and hide the views
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