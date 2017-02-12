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
BBBulletin *bulletin = nil;
PHContainerView *lsPhContainerView = nil;
PHContainerView *ncPhContainerView = nil;

CGSize appViewSize(BOOL lockscreen) {
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
		NSLog(@"NIL ICON");
		// TODO: fallback get it another way
	}

	return icon;

	// Apple 2FA identifier: com.apple.springboard.SBUserNotificationAlert

	// return [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
}

void showTestNotification() {
	[[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		// BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];
		// bulletin.title = @"Priority Hub";
		// bulletin.sectionID = @"com.apple.MobileSMS";
		// bulletin.message = @"This is a test notification!";
		// bulletin.bulletinID = @"PriorityHubTest";
		// bulletin.defaultAction = nil;
		// bulletin.date = [NSDate date];

		NSLog(@"BB SERVER: %@", bbServer);

		if (bbServer && bulletin)
			[bbServer publishBulletin:bulletin destinations:14 alwaysToLockScreen:NO];
	});
}


%ctor {
    //dlopen'ing tweaks causes their dylib to be loaded and their constructors to be executed first.
    //This fixes a lot of layout problems because then priority hub's layout code runs last and
    //has the last say in the layout of some views.
    // dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
    // dlopen("/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib", RTLD_NOW);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)showTestNotification, CFSTR("com.thomasfinch.priorityhub-testnotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
    [prefs registerDefaults:@{
    	// Lockscreen settings
        @"enabled": @YES,
        @"collapseOnLock": @YES,
        @"enablePullToClear": @YES,
        @"privacyMode": @NO,
        @"iconLocation": [NSNumber numberWithInt:0],
        @"iconSize": (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0],
        @"numberStyle": [NSNumber numberWithInt:1],
        @"verticalAdjustmentTop": [NSNumber numberWithFloat:0],
        @"verticalAdjustmentBottom": [NSNumber numberWithFloat:0],
        @"verticalAdjustmentTopDirection": [NSNumber numberWithInt:0],
        @"verticalAdjustmentBottomDirection": [NSNumber numberWithInt:0],
        @"showAllWhenNotSelected": [NSNumber numberWithInt:0],

        // Notification center settings
        @"ncEnabled": @YES,
        @"ncIconLocation": [NSNumber numberWithInt:0],
        @"ncIconSize": [NSNumber numberWithInt:0],
        @"ncNumberStyle": [NSNumber numberWithInt:1],
        @"ncEnablePullToClear": @YES,
        @"ncShowAllWhenNotSelected": [NSNumber numberWithInt:0],
        @"ncCollapseOnLock": @YES
    }];
}

/*

NCNotificationListViewController is the superclass for NCNotificationPriorityListViewController (lock screen) and NCNotificationSectionListViewController (notification center)
Both subclasses have insert, modify, remove notification request methods in common
Has scrollViewDidScroll and finishedScrolling methods for pull to clear
NCNotificationChronologicalList & NCNotificationHiddenRequestsList seem useful (used in notification center)
*/

%hook NCNotificationDispatcher

-(void)postNotificationWithRequest:(NCNotificationRequest*)arg1 {
	NSLog(@"POST NOTIFICATION WITH REQUEST: %@", arg1);
	NSLog(@"SOUND: %@", [arg1 sound]);
	NSLog(@"CLEAR: %@", [arg1 clearAction]);
	NSLog(@"DEFAULT: %@", [arg1 defaultAction]);
	%orig;
}

%end

%hook NCNotificationListViewController

%new
- (NSUInteger)numNotifications {
	if (IN_LS)
		return [[(NCNotificationPriorityListViewController*)self allNotificationRequests] count];
	else {
		NSUInteger numNotifications = 0;
		unsigned numSections = [(NCNotificationSectionListViewController*)self numberOfSectionsInCollectionView:self.collectionView];
		for (unsigned i = 0 ; i < numSections; i++) {
			numNotifications += [(NCNotificationSectionListViewController*)self collectionView:self.collectionView numberOfItemsInSection:i];
		}
		return numNotifications;
	}
}

%new
- (NSString*)notificationIdentifierAtIndex:(NSUInteger)index {
	if (IN_LS)
		return [[self notificationRequestAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] sectionIdentifier];
	else {
		return @""; // TODO
	}
}

%new
- (BOOL)shouldShowNotificationAtIndex:(NSUInteger)index {
	NSString *identifier = [self notificationIdentifierAtIndex:index];
	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;

	BOOL showAllWhenNotSelected = (IN_LS && [prefs integerForKey:@"showAllWhenNotSelected"] == 1) || (!IN_LS && [prefs integerForKey:@"ncShowAllWhenNotSelected"] == 1);

	if (!(*phContainerView).selectedAppID) {
		return showAllWhenNotSelected;
	}
	else {
		return [(*phContainerView).selectedAppID isEqualToString:identifier];
	}
}

-(void)viewDidLoad {
	%orig;

	NSLog(@"VIEW DID LOAD");

	// It's a little gross using a double pointer but it lets LS & NC use the same code
	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;

	// Create the PHContainerView
	if (!*phContainerView) {
		*phContainerView = [[PHContainerView alloc] init:(IN_LS)];
		[self.view addSubview:*phContainerView];
	}

	// Set up notification fetching block
	(*phContainerView).getCurrentNotifications = ^NSDictionary*() {
		NSMutableDictionary *notificationsDict = [NSMutableDictionary new];

		for (int i = 0; i < [self numNotifications]; i++) {
			NSString *identifier = [self notificationIdentifierAtIndex:i];
			unsigned int numNotifications = 1;
			if (notificationsDict[identifier]) {
				numNotifications = [notificationsDict[identifier] unsignedIntegerValue] + 1;
			}
			[notificationsDict setObject:[NSNumber numberWithUnsignedInteger:numNotifications] forKey:identifier];
		}

		return notificationsDict;
	};

	// Set up table view update block
	(*phContainerView).updateNotificationView = ^void() {
		NSLog(@"UPDATING TABLE VIEW");
		[self.collectionView reloadData];
	};	
}

- (void)viewDidLayoutSubviews {
	%orig;

 	if (!ENABLED)
		return;

	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
	self.collectionView.clipsToBounds = YES;

	CGRect phContainerViewFrame = CGRectZero;
	CGRect collectionViewFrame = CGRectZero;
	CGRectEdge edge = ((IN_LS && [prefs integerForKey:@"iconLocation"] == 0) || (!IN_LS && [prefs integerForKey:@"ncIconLocation"] == 0)) ? CGRectMinYEdge : CGRectMaxYEdge;
	CGRectDivide(self.view.bounds, &phContainerViewFrame, &collectionViewFrame, appViewSize(IN_LS).height, edge);

	(*phContainerView).frame = phContainerViewFrame;
	self.collectionView.frame = collectionViewFrame;
}

%new
- (void)insertOrModifyNotification:(NCNotificationRequest*)request {
	if (!ENABLED)
		return;

	PHContainerView **phContainerView = (IN_LS) ? &lsPhContainerView : &ncPhContainerView;
	[*phContainerView updateView];
	[*phContainerView selectAppID:[request sectionIdentifier] newNotification:YES];
}

%new
- (void)removeNotification:(NCNotificationRequest*)request {
	if (!ENABLED)
		return;

	(IN_LS) ? [lsPhContainerView updateView] : [ncPhContainerView updateView];
}

%end


// Customized hooks for LS, hooking same methods in super class doesn't work
%hook NCNotificationPriorityListViewController

- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	NSLog(@"INSERT NOTIFICATION REQUEST: %@ FOR COALESCED NOTIFICATION: %@", request, notification);
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


// Used to hide notifications that aren't for the selected app
%hook NCNotificationListCollectionViewFlowLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
	NCNotificationListViewController* controller = (NCNotificationListViewController*)self.collectionView.delegate;
	BOOL inLS = [controller isKindOfClass:%c(NCNotificationPriorityListViewController)];
	if (!((inLS && [prefs boolForKey:@"enabled"]) || (!inLS && [prefs boolForKey:@"ncEnabled"])))
		return %orig;

	const CGFloat PADDING = 8; // For iOS 10. Hope this doesn't change!
	CGFloat curVerticalOffset = 0;
	NSArray *attributes = %orig;

	NSLog(@"LAYOUT ATTRIBUTES FOR RECT: %@ ARE: %@", NSStringFromCGRect(rect), attributes);

	for (unsigned i = 0; i < [attributes count]; i++) {
		UICollectionViewLayoutAttributes* curAttributes = ((UICollectionViewLayoutAttributes*)[attributes objectAtIndex:i]);
		if ([controller shouldShowNotificationAtIndex:i]) {
			curAttributes.frame = CGRectMake(PADDING, curVerticalOffset + PADDING, curAttributes.frame.size.width, curAttributes.frame.size.height);
			curVerticalOffset += curAttributes.frame.size.height + PADDING;
		}
		else {
			curAttributes.hidden = YES;
		}
	}
	return attributes;
}

%end


// These functions are called for both LS and NC notifications
%hook NCBulletinNotificationSource

-(void)observer:(id)observer addBulletin:(BBBulletin*)bulletin forFeed:(unsigned long long)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(/*^block*/id)arg5 {
	NSLog(@"OBSERVER ADD BULLETIN: %@ FOR FEED:%llu", bulletin, arg3);
	if (lsPhContainerView)
		lsPhContainerView.selectedAppID = bulletin.sectionID;
	if (ncPhContainerView)
		ncPhContainerView.selectedAppID = bulletin.sectionID;
	%orig;
}

-(void)observer:(id)observer removeBulletin:(BBBulletin*)bulletin forFeed:(unsigned long long)arg3 {
	NSLog(@"OBSERVER REMOVE BULLETIN: %@", bulletin);
	%orig;
}

-(void)observer:(id)observer modifyBulletin:(BBBulletin*)bulletin forFeed:(unsigned long long)arg3 {
	NSLog(@"OBSERVER MODIFY BULLETIN: %@", bulletin);
	%orig;
}

%end


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

- (void)setInScreenOffMode:(BOOL)arg1 {
	%orig;
	if ([prefs boolForKey:@"enabled"] && [prefs boolForKey:@"collapseOnLock"] && lsPhContainerView) {
		[lsPhContainerView selectAppID:lsPhContainerView.selectedAppID newNotification:NO];
	}
}

%end
