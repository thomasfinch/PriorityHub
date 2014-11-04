#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHController.h"
#import "PHPullToClearView.h"

#ifndef DEBUG
	#define NSLog
#endif

const CGFloat pullToClearThreshold = -30;
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

	UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
	UITableView* notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");

	[PHController sharedInstance].listView = self;
	[PHController sharedInstance].notificationsTableView = notificationsTableView;
	if (![PHController sharedInstance].appsScrollView)
		[PHController sharedInstance].appsScrollView = [[PHAppsScrollView alloc] init];

	CGFloat scrollViewHeight = ([[[PHController sharedInstance].prefsDict objectForKey:@"showNumbers"] boolValue]) ? [PHController iconSize] * 1.8 : [PHController iconSize] * 1.4;

	if ([[[PHController sharedInstance].prefsDict objectForKey:@"iconLocation"] intValue] == 0) {
		[PHController sharedInstance].appsScrollView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, scrollViewHeight);
		containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + scrollViewHeight + 2, containerView.frame.size.width, containerView.frame.size.height - scrollViewHeight - 2);
	}
	else {
		[PHController sharedInstance].appsScrollView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + containerView.frame.size.height - scrollViewHeight, containerView.frame.size.width, scrollViewHeight);
		containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, containerView.frame.size.height - scrollViewHeight - 2);
	}

	[[PHController sharedInstance].appsScrollView updateLayout];

	if (![[PHController sharedInstance].appsScrollView superview])
		[self addSubview:[PHController sharedInstance].appsScrollView];

	if (!pullToClearView || ![[notificationsTableView subviews] containsObject:pullToClearView]) {
		//Add the pull to clear view to the table view
		if (!pullToClearView)
			pullToClearView = [[PHPullToClearView alloc] initWithFrame:CGRectMake((notificationsTableView.frame.size.width)/2, -20, 30, 30)];
		[notificationsTableView addSubview:pullToClearView];
	}

	//Remove notification cell separators if the option is on
	if (![[[PHController sharedInstance].prefsDict objectForKey:@"showSeparators"] boolValue])
		notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

//Used to "hide" notifications that aren't for the selected view
- (double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
	//If no app is selected (selectedAppID is nil)
	if (![PHController sharedInstance].appsScrollView.selectedAppID)
		return 0;

	NSString *cellAppID = [[[[PHController sharedInstance].listController listItemAtIndexPath:arg2] activeBulletin] sectionID];
	if ([cellAppID isEqualToString:[PHController sharedInstance].appsScrollView.selectedAppID])
		return %orig;
	else
		return 0;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	pullToClearView.hidden = ![PHController sharedInstance].appsScrollView.selectedAppID || (!scrollView.dragging && !scrollView.tracking);
	if (scrollView.contentOffset.y <= 0 && !pullToClearView.clearing)
		[pullToClearView setXVisible: (scrollView.contentOffset.y <= pullToClearThreshold)];

	%orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(_Bool)arg2 {
	if (scrollView.contentOffset.y <= pullToClearThreshold && [PHController sharedInstance].appsScrollView.selectedAppID && (scrollView.dragging || scrollView.tracking)) {
		pullToClearView.clearing = NO;
		[[PHController sharedInstance] pullToClearTriggered];
	}

	%orig;
}

%end


%hook SBLockScreenNotificationListController

//Called when a new notification is added to the notification table view
-(void)_updateModelAndViewForAdditionOfItem:(id)item {
	%orig;
	NSLog(@"UPDATE MODEL AND VIEW FOR ADDITION OF ITEM: %@",item);
	[PHController sharedInstance].listController = self;
	[PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	[[PHController sharedInstance] addNotificationForAppID:[[item activeBulletin] sectionID]];
}

//Called when a notification is removed from the table view
-(void)_updateModelForRemovalOfItem:(id)item updateView:(BOOL)view {
	%orig;
	NSLog(@"UPDATE MODEL FOR REMOVAL OF ITEM (BOOL): %@",item);
	[PHController sharedInstance].listController = self;
	[PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	[[PHController sharedInstance] removeNotificationForAppID:[[item activeBulletin] sectionID]];
}

//Called when device is unlocked. Clear all app views.
- (void)prepareForTeardown {
	%orig;
	[[PHController sharedInstance] clearAllNotificationsForUnlock];
}

//Called when the screen turns on or off. Used to deselect any selected app when the screen turns off.
- (void)setInScreenOffMode:(_Bool)off {
	%orig;
	if(off)
		[[PHController sharedInstance].appsScrollView screenTurnedOff];
}

%end

%hook SBLockScreenViewController

- (void)didRotateFromInterfaceOrientation:(long long)arg1 {
	%orig;
	[[PHController sharedInstance].listView layoutSubviews];
}

%end
