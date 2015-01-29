#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHController.h"
#import "PHPullToClearView.h"
#include <dlfcn.h>

#ifndef DEBUG
	#define NSLog
#endif

const CGFloat pullToClearThreshold = -30;
static PHPullToClearView *pullToClearView;

//Called when any preference is changed in the settings app
static void prefsChanged(CFNotificationCenterRef center, void *observer,CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	NSLog(@"PREFS CHANGED");
    [[PHController sharedInstance] updatePrefsDict];
}

%ctor {
	//Initialize controller and set up Darwin notifications for preference changes
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.thomasfinch.priorityhub-prefschanged"), NULL,CFNotificationSuspensionBehaviorDeliverImmediately);
    [[PHController sharedInstance] updatePrefsDict]; //Initializes the sharedInstance object
    [PHController sharedInstance].appsScrollView = [[PHAppsScrollView alloc] init];

    //dlopen'ing tweaks causes their dylib to be loaded and executed first
    //This fixes a lot of layout problems because then priority hub's layout code runs last and
    //has the last say in the layout of some views.
    dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
    dlopen("/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib", RTLD_NOW);
}

%hook SBLockScreenNotificationListView

- (void)layoutSubviews {
	%orig;

	UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
	UITableView* notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");

	// if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib"]) {
	// 	containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + 30, containerView.frame.size.width, containerView.frame.size.height - 30);
	// }
	if ([[PHController sharedInstance].prefsDict floatForKey:@"verticalAdjustment"] != 0) { //Vertical adjustment setting
		float adjustment = [[PHController sharedInstance].prefsDict floatForKey:@"verticalAdjustment"];
		NSLog(@"VERTICAL ADJUSTMENT: %f", adjustment);
		
		if (adjustment < 0) { //Move the top of the view down
			containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y - adjustment, containerView.frame.size.width, containerView.frame.size.height + adjustment);
		}
		else { //Move the bottom of the view up
			containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, containerView.frame.size.height - adjustment);
			notificationsTableView.frame = CGRectMake(notificationsTableView.frame.origin.x, notificationsTableView.frame.origin.y, notificationsTableView.frame.size.width, notificationsTableView.frame.size.height - adjustment);
		}
	}

	[PHController sharedInstance].listView = self;
	[PHController sharedInstance].notificationsTableView = notificationsTableView;
	if ([[PHController sharedInstance].appsScrollView superview])
		[[PHController sharedInstance].appsScrollView removeFromSuperview];

	CGFloat scrollViewHeight = ([[PHController sharedInstance].prefsDict boolForKey:@"showNumbers"] && [[PHController sharedInstance].prefsDict integerForKey:@"numberStyle"] != 1) ? [PHController iconSize] * 1.8 : [PHController iconSize] * 1.4;

	UIView *topSeparator = ((UIView*)[containerView subviews][1]), *bottomSeparator = ((UIView*)[containerView subviews][2]);
	if (![[PHController sharedInstance].prefsDict boolForKey:@"showSeparators"]) {
		topSeparator.hidden = YES;
		bottomSeparator.hidden = YES;
	}

	if ([[PHController sharedInstance].prefsDict integerForKey:@"iconLocation"] == 0) { //App icons at the top
		[PHController sharedInstance].appsScrollView.frame = CGRectMake(notificationsTableView.frame.origin.x, notificationsTableView.frame.origin.y, notificationsTableView.frame.size.width, scrollViewHeight);
		notificationsTableView.frame = CGRectMake(notificationsTableView.frame.origin.x, notificationsTableView.frame.origin.y + scrollViewHeight + 2, notificationsTableView.frame.size.width, notificationsTableView.frame.size.height - scrollViewHeight - 2);
		UIView *topSeparator = ((UIView*)[containerView subviews][1]);
		topSeparator.frame = CGRectMake(topSeparator.frame.origin.x, [PHController sharedInstance].appsScrollView.frame.origin.y + scrollViewHeight + 2, topSeparator.frame.size.width, topSeparator.frame.size.height);
	}
	else { //App icons at the bottom
		[PHController sharedInstance].appsScrollView.frame = CGRectMake(0, notificationsTableView.frame.origin.y + notificationsTableView.frame.size.height - scrollViewHeight, notificationsTableView.frame.size.width, scrollViewHeight);
		notificationsTableView.frame = CGRectMake(notificationsTableView.frame.origin.x, notificationsTableView.frame.origin.y, notificationsTableView.frame.size.width, notificationsTableView.frame.size.height - scrollViewHeight - 2);
		bottomSeparator.frame = CGRectMake(bottomSeparator.frame.origin.x, [PHController sharedInstance].appsScrollView.frame.origin.y - 2, bottomSeparator.frame.size.width, bottomSeparator.frame.size.height);
	}

	[[PHController sharedInstance].appsScrollView updateLayout];
	[containerView addSubview:[PHController sharedInstance].appsScrollView];

	if ([[PHController sharedInstance].prefsDict boolForKey:@"enablePullToClear"] && (!pullToClearView || ![[notificationsTableView subviews] containsObject:pullToClearView])) {
		//Add the pull to clear view to the table view
		if (!pullToClearView) {
			CGFloat pullToClearSize = 30;
			pullToClearView = [[PHPullToClearView alloc] initWithFrame:CGRectMake((notificationsTableView.frame.size.width)/2 - pullToClearSize/2, -pullToClearSize, pullToClearSize, pullToClearSize)];
		}
		[notificationsTableView addSubview:pullToClearView];
	}

	//Remove notification cell separators if the option is on
	if (![[PHController sharedInstance].prefsDict boolForKey:@"showSeparators"])
		notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

//Used to "hide" notifications that aren't for the selected view
- (double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
	id itemAtIndexPath = [[PHController sharedInstance].listController listItemAtIndexPath:arg2];

	//If the item is a system alert or passbook pass
	if ([itemAtIndexPath isKindOfClass:%c(SBAwaySystemAlertItem)] || [itemAtIndexPath isKindOfClass:%c(SBAwayCardListItem)])
		return %orig;

	//If no app is selected (selectedAppID is nil)
	if (![PHController sharedInstance].appsScrollView.selectedAppID)
		return 0;

	NSString *cellAppID = [[itemAtIndexPath activeBulletin] sectionID];
	if ([cellAppID isEqualToString:[PHController sharedInstance].appsScrollView.selectedAppID])
		return %orig;
	else
		return 0;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	if ([[PHController sharedInstance].prefsDict boolForKey:@"enablePullToClear"]) {
		pullToClearView.hidden = ![PHController sharedInstance].appsScrollView.selectedAppID;
		if (scrollView.contentOffset.y <= 0 && !pullToClearView.clearing)
			[pullToClearView setXVisible: (scrollView.contentOffset.y <= pullToClearThreshold)];
	}

	%orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(_Bool)arg2 {
	if ([[PHController sharedInstance].prefsDict boolForKey:@"enablePullToClear"] && scrollView.contentOffset.y <= pullToClearThreshold && [PHController sharedInstance].appsScrollView.selectedAppID && (scrollView.dragging || scrollView.tracking)) {
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
	if (![item isKindOfClass:%c(SBAwaySystemAlertItem)] && ![item isKindOfClass:%c(SBAwayCardListItem)])
		[[PHController sharedInstance] addNotificationForAppID:[[item activeBulletin] sectionID]];
}

//Called when a notification is removed from the table view
-(void)_updateModelForRemovalOfItem:(id)item updateView:(BOOL)view {
	%orig;
	NSLog(@"UPDATE MODEL FOR REMOVAL OF ITEM (BOOL): %@",item);
	[PHController sharedInstance].listController = self;
	[PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	if (![item isKindOfClass:%c(SBAwaySystemAlertItem)] && ![item isKindOfClass:%c(SBAwayCardListItem)])
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
