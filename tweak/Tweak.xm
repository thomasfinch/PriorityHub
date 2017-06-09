#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <AppList/AppList.h>
#import "substrate.h"
#import "Headers.h"
#import "PHContainerView.h"
#import "PHPullToClearView.h"

#define IN_LS [self isKindOfClass:%c(NCNotificationPriorityListViewController)]
#define ENABLED ((IN_LS && [prefs boolForKey:@"enabled"]) || (!IN_LS && [prefs boolForKey:@"ncEnabled"]))

NSUserDefaults *prefs = nil;
BBServer *bbServer = nil;
PHContainerView *lsPhContainerView = nil;
PHContainerView *ncPhContainerView = nil;
UIView *lsPullToClearView = nil;
UIView *ncPullToClearView = nil;

static const NSUInteger kNotificationCenterDestination = 2;
static const NSUInteger kLockScreenDestination = 4;


/*
	Utility functions
*/

CGSize appViewSize(BOOL lockscreen) {
	if ((lockscreen && ![prefs boolForKey:@"enabled"]) || (!lockscreen && ![prefs boolForKey:@"ncEnabled"]))
		return CGSizeZero;

	CGFloat width = 0;
	NSInteger iconSize = (lockscreen) ? [prefs integerForKey:@"iconSize"] : [prefs integerForKey:@"ncIconSize"];
	
	switch (iconSize) {
		default:
		case 0:
			width = 40;
			break;
		case 1:
			width = 53;
			break;
		case 2:
			width = 63;
			break;
		case 3:
			width = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 106 : 84;
			break;
	}

	BOOL numberStyleBelow = (lockscreen) ? [prefs boolForKey:@"numberStyle"] : [prefs boolForKey:@"ncNumberStyle"];
	CGFloat height = (numberStyleBelow) ? width * 1.45 : width;
	return CGSizeMake(width, height);
}

UIImage* iconForIdentifier(NSString* identifier) {
	UIImage *icon = [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:identifier];

	if (!icon) {
		// somehow get an NCNotificationRequest for this identifier
		// then get NCNotificationContent with request.content
		// then get icon with content.icon (20 x 20 but better than nothing)

		NSLog(@"NIL ICON");
	}

	return icon;

	// Apple 2FA identifier: com.apple.springboard.SBUserNotificationAlert
	// Low power mode identifier (maybe): com.apple.DuetHeuristic-BM

	// return [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
}


/*
	Code for sending test notifications to LS & NC
	Thanks David!
*/

static dispatch_queue_t getBBServerQueue() {
	static dispatch_queue_t queue;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		void *handle = dlopen(NULL, RTLD_GLOBAL);
		if (handle) {
			dispatch_queue_t *pointer = (dispatch_queue_t *) dlsym(handle, "__BBServerQueue");
			if (pointer) {
				queue = *pointer;
			}
			dlclose(handle);        
		}
	});
	return queue;
}

static NSUInteger bulletinNum = 0;

// Must be invoked on the BBServerQueue!
static NSString * nextBulletinID() {
	++bulletinNum;
	return [NSString stringWithFormat:@"com.thomasfinch.priorityhub.notification-id-%@", @(bulletinNum)];
}

// Must be invoked on the BBServerQueue!
static void sendTestNotification(BBServer *server, NSUInteger destinations, BOOL toLS) {
	NSString *bulletinID = nextBulletinID();
	BBBulletinRequest *bulletin = [[[%c(BBBulletinRequest) alloc] init] autorelease];
	bulletin.title = @"Priority Hub";
	bulletin.subtitle = @"This is a test notification!";
	bulletin.sectionID = @"com.apple.MobileSMS";
	bulletin.recordID = bulletinID;
	bulletin.publisherBulletinID = bulletinID;
	bulletin.clearable = YES;
	bulletin.showsMessagePreview = YES;
	NSDate *date = [NSDate date];
	bulletin.date = date;
	bulletin.publicationDate = date;
	bulletin.lastInterruptDate = date;

	NSURL *url= [NSURL URLWithString:@"prefs:root=PriorityHub"];
	bulletin.defaultAction = [%c(BBAction) actionWithLaunchURL:url];

	if ([server respondsToSelector:@selector(publishBulletinRequest:destinations:alwaysToLockScreen:)]) {
		[server publishBulletinRequest:bulletin destinations:destinations alwaysToLockScreen:toLS];
	}
}

static void showTestLockScreenNotification() {
	dispatch_queue_t queue = getBBServerQueue();
	if (!bbServer || !queue) {
		return;
	}

	[[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), queue, ^{
		sendTestNotification(bbServer, kLockScreenDestination, YES);
	});
}

static void showTestNotificationCenterNotification() {
	dispatch_queue_t queue = getBBServerQueue();
	if (!bbServer || !queue) {
		return;
	}

	[[%c(SBNotificationCenterController) sharedInstance] presentAnimated:YES];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), queue, ^{
		sendTestNotification(bbServer, kNotificationCenterDestination, NO);
	});
}


%ctor {
	//dlopen'ing tweaks causes their dylib to be loaded and their constructors to be executed first.
	//This fixes a lot of layout problems because then priority hub's layout code runs last and
	//has the last say in the layout of some views.
	// dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
	// dlopen("/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib", RTLD_NOW);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)showTestNotificationCenterNotification, CFSTR("com.thomasfinch.priorityhub-testnotification-nc"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)showTestLockScreenNotification, CFSTR("com.thomasfinch.priorityhub-testnotification-ls"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
	[prefs registerDefaults:@{
		// Lockscreen settings
		@"enabled": @YES,
		@"collapseOnLock": @YES,
		@"enablePullToClear": @YES,
		@"privacyMode": @NO,
		@"iconLocation": [NSNumber numberWithInt:0],
		@"iconSize": [NSNumber numberWithInt:1],
		@"numberStyle": [NSNumber numberWithInt:1],
		@"verticalAdjustmentTop": [NSNumber numberWithFloat:0],
		@"verticalAdjustmentBottom": [NSNumber numberWithFloat:0],
		@"verticalAdjustmentTopDirection": [NSNumber numberWithInt:0],
		@"verticalAdjustmentBottomDirection": [NSNumber numberWithInt:0],
		@"showAllWhenNotSelected": [NSNumber numberWithInt:0],

		// Notification center settings
		@"ncEnabled": @YES,
		@"ncIconLocation": [NSNumber numberWithInt:0],
		@"ncIconSize": [NSNumber numberWithInt:1],
		@"ncNumberStyle": [NSNumber numberWithInt:1],
		@"ncEnablePullToClear": @YES,
		@"ncShowAllWhenNotSelected": [NSNumber numberWithInt:0],
		@"ncCollapseOnLock": @YES
	}];
}


/*
	Main hooks
*/

%hook BBServer

- (id)init {
	bbServer = %orig;
	return bbServer;
}

%end

%hook NCNotificationListViewController

%new
- (BOOL)shouldShowNotificationAtIndexPath:(NSIndexPath*)indexPath {
	NSString *identifier = [[self notificationRequestAtIndexPath:indexPath] sectionIdentifier];
	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
	BOOL showAllWhenNotSelected = (IN_LS && [prefs integerForKey:@"showAllWhenNotSelected"] == 1) || (!IN_LS && [prefs integerForKey:@"ncShowAllWhenNotSelected"] == 1);

	if (!(*phContainerView).selectedAppID) {
		if (IN_LS && [prefs boolForKey:@"privacyMode"])
			return NO;
		else
			return showAllWhenNotSelected;
	}

	return [(*phContainerView).selectedAppID isEqualToString:identifier];
}

%new
- (NSArray*)allIndexPaths {
	NSMutableArray *indexPaths = [NSMutableArray new];

	for (NSInteger section = 0; section < [self numberOfSectionsInCollectionView:self.collectionView]; section++) {
		for (NSInteger item = 0; item < [self collectionView:self.collectionView numberOfItemsInSection:section]; item++) {
			[indexPaths addObject:[NSIndexPath indexPathForRow:item inSection:section]];
		}
	}

	return indexPaths;
}

-(void)viewDidLoad {
	%orig;

	// It's a little gross using double pointers but it lets LS & NC use the same code
	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
	UIView **pullToClearView = (IN_LS) ? &lsPullToClearView : &ncPullToClearView;

	// Create the PHContainerView
	if (!*phContainerView) {
		*phContainerView = [[PHContainerView alloc] init:(IN_LS)];
		[self.view addSubview:*phContainerView];
	}

	// Create the pull to clear view
	if (!*pullToClearView) {
		*pullToClearView = [PHPullToClearView new];
		[self.collectionView addSubview:*pullToClearView];
	}

	// Set up notification fetching block
	(*phContainerView).getCurrentNotifications = ^NSDictionary*() {
		NSMutableDictionary *notificationsDict = [NSMutableDictionary new];

		// Loop through all sections and rows
		for (NSInteger section = 0; section < [self numberOfSectionsInCollectionView:self.collectionView]; section++) {
			for (NSInteger item = 0; item < [self collectionView:self.collectionView numberOfItemsInSection:section]; item++) {
				NSString *identifier = [[self notificationRequestAtIndexPath:[NSIndexPath indexPathForRow:item inSection:section]] sectionIdentifier];
				unsigned int numNotifications = 1;
				if (notificationsDict[identifier]) {
					numNotifications = [notificationsDict[identifier] unsignedIntegerValue] + 1;
				}
				[notificationsDict setObject:[NSNumber numberWithUnsignedInteger:numNotifications] forKey:identifier];
			}
		}

		NSLog(@"NOTIFICATIONS: %@", notificationsDict);

		return notificationsDict;
	};

	// Set up table view update block
	(*phContainerView).updateNotificationView = ^void() {
		[self.collectionView.collectionViewLayout invalidateLayout];
		[self.collectionView reloadData];
		[self.collectionView setContentOffset:CGPointZero animated:NO];
		// TODO: update scroll view height

		// Hide pull to clear view if no app is selected
		PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
		UIView **pullToClearView = (IN_LS) ? &lsPullToClearView : &ncPullToClearView;
		(*pullToClearView).hidden = !(*phContainerView).selectedAppID;
	};
}

// -(void)scrollViewDidScroll:(UIScrollView*)scrollView {
// 	%orig;

// 	if (!ENABLED)
// 		return;

// 	// TODO: pull to clear
// }

- (void)viewWillAppear {
	%orig;
	NSLog(@"VIEW WILL APPEAR");
	// [self.collectionView.collectionViewLayout invalidateLayout];
	// [self.collectionView reloadData];
	// [self.collectionView setContentOffset:CGPointZero animated:NO];
}

- (void)viewWillLayoutSubviews {
	%orig;
	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;

	if (!ENABLED) {
		self.collectionView.frame = self.view.bounds;
		(*phContainerView).hidden = YES;
		return;
	}

	// // Vertical adjustment setup
	// CGFloat verticalAdjustmentTop = 0;
	// CGFloat verticalAdjustmentBottom = 0;
	// if (IN_LS) {
	// 	verticalAdjustmentTop = [prefs floatForKey:@"verticalAdjustmentTop"];
	// 	if ([prefs integerForKey:@"verticalAdjustmentTopDirection"] == 0)
	// 		verticalAdjustmentTop = -verticalAdjustmentTop;
	// 	verticalAdjustmentBottom = [prefs floatForKey:@"verticalAdjustmentBottom"];
	// 	if ([prefs integerForKey:@"verticalAdjustmentBottomDirection"] == 0)
	// 		verticalAdjustmentBottom = -verticalAdjustmentBottom;
	// }

	// NSLog(@"VERTICAL TOP: %f", verticalAdjustmentTop);
	// NSLog(@"VERTICAL BOTTOM: %f", verticalAdjustmentBottom);
	
	// CGRect newFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + verticalAdjustmentTop, self.view.frame.size.width, self.view.frame.size.height - verticalAdjustmentTop + verticalAdjustmentBottom);
	// self.view.frame = newFrame;

	(*phContainerView).hidden = NO;
	
	self.collectionView.clipsToBounds = YES;

	CGRect phContainerViewFrame = CGRectZero;
	CGRect collectionViewFrame = CGRectZero;
	CGRectEdge edge = ((IN_LS && [prefs integerForKey:@"iconLocation"] == 0) || (!IN_LS && [prefs integerForKey:@"ncIconLocation"] == 0)) ? CGRectMinYEdge : CGRectMaxYEdge;
	CGRectDivide(self.view.bounds, &phContainerViewFrame, &collectionViewFrame, appViewSize(IN_LS).height, edge);

	(*phContainerView).frame = phContainerViewFrame;
	self.collectionView.frame = collectionViewFrame;

	// Layout pull to clear view
	// UIView **pullToClearView = (IN_LS) ? &lsPullToClearView : &ncPullToClearView;
	// BOOL pullToClearEnabled = (IN_LS) ? [prefs boolForKey:@"enablePullToClear"] : [prefs boolForKey:@"ncEnablePullToClear"];
	// (*pullToClearView).frame = CGRectMake(0, -pullToClearSize, self.collectionView.bounds.size.width, pullToClearSize);
	// (*pullToClearView).hidden = !pullToClearEnabled;

	// // Doesn't make any difference
	// self.collectionView.contentSize = self.collectionView.bounds.size;
	// self.collectionView.alwaysBounceVertical = YES;
}

%new
- (void)insertOrModifyNotification:(NCNotificationRequest*)request {
	if (!ENABLED)
		return;

	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
	[*phContainerView updateView];
	if (!(IN_LS && [prefs boolForKey:@"privacyMode"]))
		[*phContainerView selectAppID:[request sectionIdentifier] newNotification:YES];
}

%new
- (void)removeNotification:(NCNotificationRequest*)request {
	if (!ENABLED)
		return;

	(IN_LS) ? [lsPhContainerView updateView] : [ncPhContainerView updateView];
}

%end


// Customized hooks for LS, hooking same methods in super class doesn't work (too early)
%hook NCNotificationPriorityListViewController

- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	if (![prefs boolForKey:@"privacyMode"])
		lsPhContainerView.selectedAppID = [request sectionIdentifier];

	[self.collectionView performBatchUpdates:^{
		[UIView setAnimationsEnabled:NO];
		[self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
	} completion:^(BOOL finished) {
		[UIView setAnimationsEnabled:YES];
		%orig;
		[(NCNotificationListViewController*)self insertOrModifyNotification:request];
	}];
}

- (void)modifyNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	[(NCNotificationListViewController*)self insertOrModifyNotification:request];
}

- (void)removeNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	[(NCNotificationListViewController*)self removeNotification:request];
}

%end

// Also customized hooks for NC
%hook NCNotificationSectionListViewController

- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	ncPhContainerView.selectedAppID = [request sectionIdentifier];
	%orig;
	[(NCNotificationListViewController*)self insertOrModifyNotification:request];
}

- (void)modifyNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	[(NCNotificationListViewController*)self insertOrModifyNotification:request];
}

- (void)removeNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	[(NCNotificationListViewController*)self removeNotification:request];
}

%end

%hook NCNotificationListCollectionViewFlowLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
	NCNotificationListViewController* controller = (NCNotificationListViewController*)self.collectionView.delegate;
	BOOL inLS = [controller isKindOfClass:%c(NCNotificationPriorityListViewController)];
	if (!((inLS && [prefs boolForKey:@"enabled"]) || (!inLS && [prefs boolForKey:@"ncEnabled"])))
		return %orig;

	const CGFloat PADDING = 8; // For iOS 10. Hope this doesn't change!
	CGFloat curVerticalOffset = 0;
	NSArray *attributes = %orig;

	for (unsigned i = 0; i < [attributes count]; i++) {
		UICollectionViewLayoutAttributes* curAttributes = ((UICollectionViewLayoutAttributes*)[attributes objectAtIndex:i]);

		if (curAttributes.representedElementCategory != UICollectionElementCategoryCell)
			continue;

		if ([controller shouldShowNotificationAtIndexPath:[[attributes objectAtIndex:i] indexPath]]) {
			curAttributes.frame = CGRectMake(curAttributes.frame.origin.x, curVerticalOffset + PADDING, curAttributes.frame.size.width, curAttributes.frame.size.height);
			curVerticalOffset += curAttributes.frame.size.height + PADDING;
		}
		else {
			curAttributes.hidden = YES;
			curAttributes.frame = CGRectMake(curAttributes.frame.origin.x, -100, curAttributes.frame.size.width, 0);
		}
	}

	NSLog(@"ATTRIBUTES: %@", attributes);

	return attributes;
}

%end


/*
	Small hooks for small visual fixes/improvements
*/

// Hide section headers in notification center
%hook NCNotificationSectionListViewController

-(CGSize)collectionView:(id)arg1 layout:(id)arg2 referenceSizeForHeaderInSection:(long long)arg3 {
	return ([prefs boolForKey:@"ncEnabled"]) ? CGSizeZero : %orig; //TODO: give them some size otherwise spacing is thrown off (8? cell padding)
}

%end

// Hide line that shows when scrolling up on lock screen
%hook SBDashBoardClippingLine

- (void)layoutSubviews {
	%orig;
	self.hidden = YES;
}

%end

// Hide "Press home to unlock" label on lock screen if PH is at the bottom
%hook SBDashBoardMainPageView

- (void)_layoutCallToActionLabel {
	%orig;
	self.callToActionLabel.hidden = ([prefs boolForKey:@"enabled"] && [prefs integerForKey:@"iconLocation"] == 1);
}

%end

// Hide lock screen page indicators if PH is at the bottom
%hook SBDashBoardPageControl

- (void)layoutSubviews {
	%orig;
	self.hidden = ([prefs boolForKey:@"enabled"] && [prefs integerForKey:@"iconLocation"] == 1);
}

%end

// For the deselect on lock feature on lock screen
%hook SBLockScreenViewControllerBase

- (void)setInScreenOffMode:(BOOL)locked {
	%orig;
	if (locked && [prefs boolForKey:@"enabled"] && [prefs boolForKey:@"collapseOnLock"] && lsPhContainerView) {
		[lsPhContainerView selectAppID:lsPhContainerView.selectedAppID newNotification:NO];
	}
}

%end

// For the deselect on close feature in notification center
%hook SBNotificationCenterController

-(void)transitionDidBegin:(id)arg1 {
	%orig;
	[ncPhContainerView updateView];
	[ncPhContainerView selectAppID:ncPhContainerView.selectedAppID newNotification:NO];
	ncPhContainerView.updateNotificationView();
}

- (void)transitionDidFinish:(id)arg1 {
	%orig;
	if (![self isVisible] && [prefs boolForKey:@"ncEnabled"] && [prefs boolForKey:@"ncCollapseOnLock"] && ncPhContainerView) {
		[ncPhContainerView selectAppID:ncPhContainerView.selectedAppID newNotification:NO];
	}	
}

%end
