#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHView.h"
#import "PHPullToClearView.h"
#include <dlfcn.h>

#ifndef DEBUG
	#define NSLog
#endif

const CGFloat pullToClearThreshold = -35;
const CGFloat pullToClearSize = 30;
static PHPullToClearView *pullToClearView;
PHView *phView;
NSUserDefaults *defaults;

UITableView *notificationsTableView;
SBLockScreenNotificationListView *notificationListView;
SBLockScreenNotificationListController *notificationListController;
BBObserver *bulletinObserver;

void updateNotificationTableView() {
	//Call reloadData on tableview
	if (notificationsTableView)
		[notificationsTableView reloadData];

	//Reset screen off timer and notification cell fade timer
	if (notificationListView) {
		[notificationListView _disableIdleTimer:YES];
		[notificationListView _disableIdleTimer:NO];
		[notificationListView _resetAllFadeTimers];
	}

	//Hide pull to clear view if no app is selected
	if (phView.selectedAppID == nil)
		pullToClearView.hidden = YES;
	else
		pullToClearView.hidden = NO;

	//Animate notification table view fading in/out
	[UIView animateWithDuration:0.15 animations:^(){
		if (!phView.selectedAppID && [defaults integerForKey:@"showAllWhenNotSelected"] == 0)
			notificationsTableView.alpha = 0;
		else
			notificationsTableView.alpha = 1;
	}];
}

void showTestNotification() {
	[[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[notificationListController _showTestBulletin];

		// BBBulletinRequest *bulletin = [[%c(BBBulletinRequest) alloc] init];
		// bulletin.title = @"Priority Hub";
		// bulletin.sectionID = @"com.apple.MobileStore";
		// bulletin.message = @"This is a test notification!";
		// bulletin.bulletinID = @"PriorityHubTest";
		// bulletin.clearable = YES;
		// bulletin.showsMessagePreview = YES;
		// bulletin.defaultAction = [%c(BBAction) action];
		// NSDate *now = [NSDate date];
		// bulletin.date = now;
		// bulletin.publicationDate = now;
		// bulletin.lastInterruptDate = now;

		// if (notificationListController) {
		// 	if ([notificationListController respondsToSelector:@selector(observer:addBulletin:forFeed:playLightsAndSirens:withReply:)])
		// 		[notificationListController observer:MSHookIvar<id>(notificationListController, "_observer") addBulletin:bulletin forFeed:2 playLightsAndSirens:YES withReply:nil]; //iOS 8
		// 	else if ([notificationListController respondsToSelector:@selector(observer:addBulletin:forFeed:)])
		// 		[notificationListController observer:MSHookIvar<id>(notificationListController, "_observer") addBulletin:bulletin forFeed:2]; //iOS 7
		// }
	});
}

%ctor {
    //dlopen'ing tweaks causes their dylib to be loaded and executed first
    //This fixes a lot of layout problems because then priority hub's layout code runs last and
    //has the last say in the layout of some views.
    dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
    dlopen("/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib", RTLD_NOW);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)showTestNotification, CFSTR("com.thomasfinch.priorityhub-testnotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
    [defaults registerDefaults:@{
        @"enabled": @YES,
        @"showNumbers": @YES,
        @"showSeparators": @NO,
        @"collapseOnLock": @YES,
        @"enablePullToClear": @YES,
        @"privacyMode": @NO,
        @"iconLocation": [NSNumber numberWithInt:0],
        @"numberStyle": [NSNumber numberWithInt:0],
        @"verticalAdjustmentTop": [NSNumber numberWithFloat:0],
        @"verticalAdjustmentBottom": [NSNumber numberWithFloat:0],
        @"showAllWhenNotSelected": [NSNumber numberWithInt:0]
    }];
    phView = [[PHView alloc] init];
    [phView setTranslatesAutoresizingMaskIntoConstraints:NO];
}

%hook SBLockScreenNotificationListView

- (void)layoutSubviews {
	%orig;

	if (![defaults boolForKey:@"enabled"])
		return;

	//-----View creation and layout-----

	UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
	notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
	notificationListView = self;

	[containerView addSubview:phView];

	//Set up autolayout constraints
	CGFloat height = [phView appViewSize].height;
	NSDictionary *metrics = @{@"height":[NSNumber numberWithFloat:height]};
	NSDictionary *viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:phView, @"phView", notificationsTableView, @"notifTableView", nil];
	[notificationsTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
	[containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[phView]|" options:nil metrics:nil views:viewsDictionary]];
	[containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[notifTableView]|" options:nil metrics:nil views:viewsDictionary]];

	//Change the notification table view's frame depending on the icon location option
	if ([defaults integerForKey:@"iconLocation"] == 0) //App icons at top
		[containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[phView(height)][notifTableView]|" options:nil metrics:metrics views:viewsDictionary]];
	else //App icons at bottom
		[containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[notifTableView][phView(height)]|" options:nil metrics:metrics views:viewsDictionary]];
	
	//Change the container view's frame depending on the vertical adjustments set
	CGFloat verticalAdjustmentTop = [defaults floatForKey:@"verticalAdjustmentTop"];
	CGFloat verticalAdjustmentBottom = [defaults floatForKey:@"verticalAdjustmentBottom"];
	containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + verticalAdjustmentTop, containerView.frame.size.width, containerView.frame.size.height - verticalAdjustmentTop + verticalAdjustmentBottom);
	
	//-----Other general setup-----

	//Remove notification cell separators if the option is on		
	if (![defaults boolForKey:@"showSeparators"]) {
		UIView *topSeparator = ((UIView*)[containerView subviews][1]), *bottomSeparator = ((UIView*)[containerView subviews][2]);
		topSeparator.hidden = YES;
		bottomSeparator.hidden = YES;
		notificationsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	}

	//Add pull to clear view if the option is on
	if ([defaults boolForKey:@"enablePullToClear"]) {
		if (pullToClearView)
			[pullToClearView removeFromSuperview];
		pullToClearView = [[PHPullToClearView alloc] initWithFrame:CGRectMake((notificationsTableView.frame.size.width)/2 - pullToClearSize/2, -pullToClearSize * 1.1, pullToClearSize, pullToClearSize)];
		[notificationsTableView addSubview:pullToClearView];
	}
}

//Used to hide notifications that aren't for the selected app
- (double)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	if (![defaults boolForKey:@"enabled"])
		return %orig;

	SBAwayListItem *listItem = [MSHookIvar<SBLockScreenNotificationModel*>(self, "_model") listItemAtIndexPath:indexPath];

	//If the item is not a notification (system alert or passbook pass)
	if (![listItem isKindOfClass:%c(SBAwayBulletinListItem)])
		return %orig;

	//If no app is selected
	if (phView.selectedAppID == nil) {
		if ([defaults integerForKey:@"showAllWhenNotSelected"] == 0 || [defaults boolForKey:@"privacyMode"]) //If all notifications are hidden when not selected
			return 0;
		else
			return %orig;
	}

	//Only show the cell if it's equal to the selected app ID
	if ([phView.selectedAppID isEqualToString:[[(SBAwayBulletinListItem*)listItem activeBulletin] sectionID]])
		return %orig;
	else
		return 0;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
	if ([defaults boolForKey:@"enabled"] && [defaults boolForKey:@"enablePullToClear"]) {
		if (scrollView.contentOffset.y <= 0)
			[pullToClearView setXVisible:(scrollView.contentOffset.y <= pullToClearThreshold)];
	}

	%orig;
}

//All scroll view methods are used for pull to clear control
- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(_Bool)arg2 {
	if ([defaults boolForKey:@"enabled"] && [defaults boolForKey:@"enablePullToClear"] && phView.selectedAppID != nil && scrollView.contentOffset.y <= pullToClearThreshold &&  (scrollView.dragging || scrollView.tracking)) {
		[bulletinObserver clearSection:phView.selectedAppID];
		notificationsTableView.alpha = 0;
		[pullToClearView setXVisible:NO];
	}

	%orig;
}

%end


%hook SBLockScreenNotificationListController

- (void)loadView {
	%orig;
	bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
	notificationListController = self;
	phView.listController = self;
}

//Called when a new notification is added to the notification list
- (void)_updateModelAndViewForAdditionOfItem:(SBAwayListItem*)item {
	%orig;
	if (![defaults boolForKey:@"enabled"])
		return;

	NSLog(@"UPDATE MODEL AND VIEW FOR ADDITION OF ITEM: %@",item);
	[phView updateView];

	if (![defaults boolForKey:@"privacyMode"]) {
		NSString *appID = nil;
		if ([item isKindOfClass:%c(SBAwayBulletinListItem)])
			appID = [[(SBAwayBulletinListItem*)item activeBulletin] sectionID];
		else if ([item isKindOfClass:%c(SBAwayCardListItem)])
			appID = [[(SBAwayCardListItem*)item cardItem] identifier];
		else if ([item isKindOfClass:%c(SBAwaySystemAlertItem)])
			appID = [(SBAwaySystemAlertItem*)item title];
		[phView selectAppID:appID newNotification:YES];
	}
}

//Called when a notification is removed from the list
- (void)_updateModelForRemovalOfItem:(SBAwayListItem*)item updateView:(BOOL)update {
	%orig;
	if (![defaults boolForKey:@"enabled"])
		return;

	NSLog(@"UPDATE MODEL FOR REMOVAL OF ITEM (BOOL): %@",item);
	[phView updateView];
}

//Called when device is unlocked, clear all app views.
- (void)prepareForTeardown {
	%orig;
	if ([defaults boolForKey:@"enabled"])
		[phView updateView];
}

//Called when the screen turns on or off, used to deselect any selected app when the screen turns off.
- (void)setInScreenOffMode:(BOOL)off {
	%orig;
	if(off && [defaults boolForKey:@"enabled"] && [defaults boolForKey:@"collapseOnLock"] && phView && phView.selectedAppID)
		[phView selectAppID:phView.selectedAppID newNotification:NO];
}

%end

// %hook SBLockScreenViewController

// - (void)didRotateFromInterfaceOrientation:(long long)arg1 {
// 	%orig;
// 	if (![[PHController sharedInstance].prefsDict boolForKey:@"enabled"])
// 		return;
// 	[[PHController sharedInstance].listView layoutSubviews];
// }

// %end
