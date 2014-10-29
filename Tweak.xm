#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHController.h"
#import "PHPullToClearView.h"

#ifndef DEBUG
	#define NSLog
#endif

const CGFloat pullToClearThreshold = -45;
PHPullToClearView *pullToClearView;

//Called when any preference is changed in the settings app
static void prefsChanged(CFNotificationCenterRef center, void *observer,CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSLog(@"PREFS CHANGED");
    [[PHController sharedInstance] updatePrefsDict];
}

%ctor {
	//Initialize controller and set up Darwin notifications for preference changes
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.thomasfinch.priorityhub-prefschanged"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    [[PHController sharedInstance] updatePrefsDict]; //Initializes the sharedInstance object
}


%hook SBLockScreenNotificationListView

- (void)layoutSubviews {
	%orig;

	[PHController sharedInstance].appsScrollView = [[PHAppsScrollView alloc] init];

	UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
	UITableView* notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");

	//Add the app views scroll view to the lockscreen
	[PHController sharedInstance].appsScrollView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, 55);
	[self addSubview:[PHController sharedInstance].appsScrollView];

	//Adjust the container for the notifications
	containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + 55 + 2, containerView.frame.size.width, containerView.frame.size.height - 55 - 2);

	if (!pullToClearView || ![[notificationsTableView subviews] containsObject:pullToClearView]) {
		//Add the pull to clear view to the 
		if (!pullToClearView)
			pullToClearView = [[PHPullToClearView alloc] initWithFrame:CGRectMake((notificationsTableView.frame.size.width)/2, -30, 30, 30)];
		[notificationsTableView addSubview:pullToClearView];
	}

	//Remove notification cell separators if the option is on
	if (![[[PHController sharedInstance].prefsDict objectForKey:@"showSeparators"] boolValue])
		notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
	return %orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	if (scrollView.contentOffset.y <= 0 && !pullToClearView.clearing)
		[pullToClearView setXVisible:(scrollView.contentOffset.y <= pullToClearThreshold)];

	%orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(_Bool)arg2 {
	if (scrollView.contentOffset.y <= pullToClearThreshold) {
		pullToClearView.clearing = NO;
		[[PHController sharedInstance] pullToClearTriggered];
	}

	%orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidEndDecelerating:(id)arg1 {
	%orig;

	[pullToClearView setXVisible:NO];
	pullToClearView.clearing = NO;
}

%end


%hook SBLockScreenNotificationListController

-(void)_updateModelAndViewForAdditionOfItem:(id)item {
	%orig;
	NSLog(@"UPDATE MODEL AND VIEW FOR ADDITION OF ITEM: %@",item);
	[PHController sharedInstance].listController = self;
	[PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	[[PHController sharedInstance] addNotificationForAppID:[[item activeBulletin] sectionID]];
}

-(void)_updateModelForRemovalOfItem:(id)item updateView:(BOOL)view {
	%orig;
	NSLog(@"UPDATE MODEL FOR REMOVAL OF ITEM (BOOL): %@",item);
	[PHController sharedInstance].listController = self;
	[PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	[[PHController sharedInstance] removeNotificationForAppID:[[item activeBulletin] sectionID]];
}

- (void)unlockUIWithActionContext:(id)arg1 {
	NSLog(@"UNLOCK UI WITH ACTION CONTEXT: %@",arg1);
	%orig;
}

//Called when device is unlocked. Clear all app views.
- (void)prepareForTeardown {
	%orig;
	NSLog(@"PREPARE FOR TEARDOWN");
	[[PHController sharedInstance] clearAllNotificationsForUnlock];
}

%end

// %hook UIRefreshControl

// //Makes the pull-to-clear refresh control more "sensitive" (i.e., you don't have to pull down as far to clear)
// - (double)_visibleHeightForContentOffset:(struct CGPoint)arg1 origin:(struct CGPoint)arg2 {
// 	if ([self isEqual:refreshControl])
// 		return %orig * 2;
// 	else
// 		return %orig;
// }

// %end
