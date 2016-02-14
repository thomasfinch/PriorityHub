#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHContainerView.h"
#import "substrate.h"
#import "PHPullToClearView.h"
#include <dlfcn.h>

const CGFloat pullToClearThreshold = -35;
static PHPullToClearView *pullToClearView;
BBServer *bbServer;
PHContainerView *phContainerView;
NSUserDefaults *defaults;
UITableView *notificationsTableView;
SBLockScreenNotificationListView *notificationListView;
SBLockScreenNotificationListController *notificationListController;
BBObserver *bulletinObserver;

//Internal use, helper function for printAllListItemSubclasses
BOOL classDescendsFromClass(Class classA, Class classB) {
    while(classA) {
        if (classA == classB) return YES;
        classA = class_getSuperclass(classA);
    }
    return NO;
}

//Internal use only! Used to find all classes in SpringBoard that inherit from SBAwayListItem, so they can be easily
// found and tracked between iOS versions.
//I tried doing this in cycript but ran into too many problems smh
void printAllListItemSubclasses() {
	NSLog(@"Finding all SBAwayListItem subclasses.");
	int numClasses = objc_getClassList(NULL, 0);
	Class * classes = NULL;
	Class listItemClass = objc_getClass("SBAwayListItem");

	if (numClasses > 0 ) {
	    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
	    numClasses = objc_getClassList(classes, numClasses);
	    for (int i = 0; i < numClasses; i++) {
	        Class c = classes[i];
	        if (classDescendsFromClass(c, listItemClass))
				NSLog(@"SBAWAYLISTITEM SUBCLASS: %s", class_getName(c));
	    }
	    free(classes);
	}
	NSLog(@"Done finding SBAwayListItem subclasses.");
}

NSString* identifierForListItem(SBAwayListItem *listItem) {
	if ([listItem isKindOfClass:%c(SBAwayBulletinListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmBulletinListItem)])
		return [[(SBAwayBulletinListItem*)listItem activeBulletin] sectionID];
	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)])
		return [[(SBAwayCardListItem*)listItem cardItem] identifier];
	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)])
		return @"systemAlert";
	else
		return @"noIdentifier";
}

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
	if (phContainerView.selectedAppID == nil)
		pullToClearView.hidden = YES;
	else
		pullToClearView.hidden = NO;

	//Animate notification table view fading in/out
	[UIView animateWithDuration:0.15 animations:^(){
		if (!phContainerView.selectedAppID && [defaults integerForKey:@"showAllWhenNotSelected"] == 0)
			notificationsTableView.alpha = 0;
		else
			notificationsTableView.alpha = 1;
	}];
}

void showTestNotification() {
	[[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

		// [notificationListController _showTestBulletin];

		BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];
		bulletin.title = @"Priority Hub";
		bulletin.sectionID = @"com.apple.MobileSMS";
		bulletin.message = @"This is a test notification!";
		bulletin.bulletinID = @"PriorityHubTest";
		bulletin.clearable = YES;
		bulletin.showsMessagePreview = YES;
		bulletin.defaultAction = [%c(BBAction) action];
		NSDate *now = [NSDate date];
		bulletin.date = now;
		bulletin.publicationDate = now;
		bulletin.lastInterruptDate = now;

		if (bbServer)
			[bbServer publishBulletin:bulletin destinations:4 alwaysToLockScreen:YES];
	});
}

%ctor {
    //dlopen'ing tweaks causes their dylib to be loaded and their constructors to be executed first.
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
        @"iconSize": (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0],
        @"numberStyle": [NSNumber numberWithInt:0],
        @"verticalAdjustmentTop": [NSNumber numberWithFloat:0],
        @"verticalAdjustmentBottom": [NSNumber numberWithFloat:0],
        @"showAllWhenNotSelected": [NSNumber numberWithInt:0]
    }];

    phContainerView = [[PHContainerView alloc] init];
}

%hook BBServer
	- (id)init {
		bbServer = %orig;
		return bbServer;
	}
%end

%hook SBLockScreenNotificationListView

	- (id)initWithFrame:(struct CGRect)frame {
		self = %orig;

		if (![defaults boolForKey:@"enabled"])
			return self;

		//Save important views to variables
		UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");
		notificationsTableView = MSHookIvar<UITableView*>(self, "_tableView");
		notificationListView = self;

		[containerView addSubview:phContainerView];

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
			pullToClearView = [[PHPullToClearView alloc] initWithFrame:CGRectZero];
			[notificationsTableView addSubview:pullToClearView];
		}

		return self;
	}

	- (void)layoutSubviews {
		%orig;

		CGRect phContainerViewFrame = CGRectZero;
		CGRect tableViewFrame = CGRectZero;
		UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");

		//Change the container view's frame depending on the vertical adjustments set
		CGFloat verticalAdjustmentTop = [defaults floatForKey:@"verticalAdjustmentTop"];
		CGFloat verticalAdjustmentBottom = [defaults floatForKey:@"verticalAdjustmentBottom"];
		containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + verticalAdjustmentTop, containerView.frame.size.width, containerView.frame.size.height - verticalAdjustmentTop + verticalAdjustmentBottom);

		//Layout PHContainerView and notifications table view
		int iconLocation = [defaults integerForKey:@"iconLocation"];
		if (iconLocation == 0) //App icons at top
			CGRectDivide(containerView.bounds, &phContainerViewFrame, &tableViewFrame, [phContainerView appViewSize].height, CGRectMinYEdge);
		else if (iconLocation == 1)//App icons at bottom
			CGRectDivide(containerView.bounds, &phContainerViewFrame, &tableViewFrame, [phContainerView appViewSize].height, CGRectMaxYEdge);
		else if (iconLocation == 2)//App icons at left
			CGRectDivide(containerView.bounds, &phContainerViewFrame, &tableViewFrame, [phContainerView appViewSize].width, CGRectMinXEdge);
 		else //App icons at right
			CGRectDivide(containerView.bounds, &phContainerViewFrame, &tableViewFrame, [phContainerView appViewSize].width, CGRectMaxXEdge);

		phContainerView.frame = phContainerViewFrame;
		notificationsTableView.frame = tableViewFrame;

		//Layout pull to clear view
		if (pullToClearView)
			pullToClearView.frame = CGRectMake(0, -pullToClearSize, notificationsTableView.bounds.size.width, pullToClearSize);
	}

	%new
	- (BOOL)shouldDisplayIndexPath:(NSIndexPath*)indexPath {
		//If no app is selected
		if (!phContainerView.selectedAppID) {
			return !([defaults integerForKey:@"showAllWhenNotSelected"] == 0 || [defaults boolForKey:@"privacyMode"]);
		}

		//Only show the cell if it's equal to the selected app ID
		return [phContainerView.selectedAppID isEqualToString:identifierForListItem([self.model listItemAtIndexPath:indexPath])];
	}

	// Used to hide notifications that aren't for the selected app
	- (double)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
		return (![defaults boolForKey:@"enabled"] || [self shouldDisplayIndexPath:indexPath]) ? %orig : 0;
	}

	//All scroll view methods are used for pull to clear control
	- (void)scrollViewDidScroll:(UIScrollView*)scrollView {
		if ([defaults boolForKey:@"enabled"] && [defaults boolForKey:@"enablePullToClear"] && scrollView.contentOffset.y <= 0)
			[pullToClearView setXVisible:(scrollView.contentOffset.y <= pullToClearThreshold)];

		%orig;
	}

	//All scroll view methods are used for pull to clear control
	- (void)scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(_Bool)arg2 {
		if ([defaults boolForKey:@"enabled"] && [defaults boolForKey:@"enablePullToClear"] && phContainerView.selectedAppID != nil && scrollView.contentOffset.y <= pullToClearThreshold &&  (scrollView.dragging || scrollView.tracking)) {
			[bulletinObserver clearSection:phContainerView.selectedAppID];
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
		phContainerView.listController = self;
	}

	//Called when a new notification is added to the notification list
	- (void)_updateModelAndViewForAdditionOfItem:(SBAwayListItem*)item {
		%orig;
		if (![defaults boolForKey:@"enabled"])
			return;

		[phContainerView updateView];

		if (![defaults boolForKey:@"privacyMode"])
			[phContainerView selectAppID:identifierForListItem(item) newNotification:YES];
	}

	//Called when a notification is removed from the list
	- (void)_updateModelForRemovalOfItem:(SBAwayListItem*)item updateView:(BOOL)update {
		%orig;

		if ([defaults boolForKey:@"enabled"])
			[phContainerView updateView];
	}

	//Called when device is unlocked, clear all app views.
	- (void)prepareForTeardown {
		%orig;

		if ([defaults boolForKey:@"enabled"])
			[phContainerView updateView];
	}

	//Called when the screen turns on or off, used to deselect any selected app when the screen turns off.
	- (void)setInScreenOffMode:(BOOL)off {
		%orig;
		
		if(off && [defaults boolForKey:@"enabled"] && [defaults boolForKey:@"collapseOnLock"] && phContainerView && phContainerView.selectedAppID)
			[phContainerView selectAppID:phContainerView.selectedAppID newNotification:NO];
	}

%end
