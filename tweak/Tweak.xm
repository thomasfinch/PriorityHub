#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <AppList/AppList.h>
#import "substrate.h"
#import "Headers.h"
#import "PHContainerView.h"
#import "PHPullToClearView.h"

#define inLS [self isKindOfClass:%c(NCNotificationPriorityListViewController)]
#define enabled ((inLS && [defaults boolForKey:@"enabled"]) || (!inLS && [defaults boolForKey:@"ncEnabled"]))

NSUserDefaults *defaults = nil;
// BBServer *bbServer = nil;
PHContainerView *lsPhContainerView = nil;
PHContainerView *ncPhContainerView = nil;

CGSize appViewSize(BOOL lockscreen) {
	CGFloat width = 0;
	NSInteger iconSize = (lockscreen) ? [defaults integerForKey:@"iconSize"] : [defaults integerForKey:@"ncIconSize"];
	
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

	BOOL numberStyleBelow = (lockscreen) ? [defaults boolForKey:@"numberStyle"] : [defaults boolForKey:@"ncNumberStyle"];
	CGFloat height = (numberStyleBelow) ? width * 1.4 : width;
	return CGSizeMake(width, height);
}

UIImage* iconForIdentifier(NSString* identifier) {
	NSLog(@"ICON FOR IDENTIFIER: %@", identifier);

	return [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:identifier];

	// Apple 2FA identifier: com.apple.springboard.SBUserNotificationAlert

	// return [UIImage _applicationIconImageForBundleIdentifier:identifier format:0 scale:[UIScreen mainScreen].scale];
}

void showTestNotification() {
	[[%c(SBLockScreenManager) sharedInstance] lockUIFromSource:1 withOptions:nil];

	// dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
	// 	BBBulletin *bulletin = [[%c(BBBulletin) alloc] init];
	// 	bulletin.title = @"Priority Hub";
	// 	bulletin.sectionID = @"com.apple.MobileSMS";
	// 	bulletin.message = @"This is a test notification!";
	// 	bulletin.bulletinID = @"PriorityHubTest";
	// 	bulletin.defaultAction = nil;
	// 	bulletin.date = [NSDate date];

	// 	NSLog(@"BB SERVER: %@", bbServer);

	// 	if (bbServer)
	// 		[bbServer publishBulletin:bulletin destinations:4 alwaysToLockScreen:YES];
	// });
}


%ctor {
    //dlopen'ing tweaks causes their dylib to be loaded and their constructors to be executed first.
    //This fixes a lot of layout problems because then priority hub's layout code runs last and
    //has the last say in the layout of some views.
    // dlopen("/Library/MobileSubstrate/DynamicLibraries/SubtleLock.dylib", RTLD_NOW);
    // dlopen("/Library/MobileSubstrate/DynamicLibraries/Roomy.dylib", RTLD_NOW);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)showTestNotification, CFSTR("com.thomasfinch.priorityhub-testnotification"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

    defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];
    [defaults registerDefaults:@{
        @"enabled": @YES,
        @"collapseOnLock": @YES,
        @"enablePullToClear": @YES,
        @"privacyMode": @NO,
        @"iconLocation": [NSNumber numberWithInt:0],
        @"iconSize": (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0],
        @"numberStyle": [NSNumber numberWithInt:1],
        @"verticalAdjustmentTop": [NSNumber numberWithFloat:0],
        @"verticalAdjustmentBottom": [NSNumber numberWithFloat:0],
        @"showAllWhenNotSelected": [NSNumber numberWithInt:0],

        @"ncEnabled": @YES,
        @"ncIconLocation": [NSNumber numberWithInt:0],
        @"ncIconSize": [NSNumber numberWithInt:0],
        @"ncNumberStyle": [NSNumber numberWithInt:1],
        @"ncShowAllWhenNotSelected": [NSNumber numberWithInt:0]
    }];
}

/*

NCNotificationListViewController is the superclass for NCNotificationPriorityListViewController (lock screen) and NCNotificationSectionListViewController (notification center)
Both subclasses have insert, modify, remove notification request methods in common
Has scrollViewDidScroll and finishedScrolling methods for pull to clear
NCNotificationChronologicalList & NCNotificationHiddenRequestsList seem useful (used in notification center)
*/

%hook NCNotificationListViewController

%new
- (NSUInteger)numNotifications {
	if (inLS)
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
	if (inLS)
		return [[self notificationRequestAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] sectionIdentifier];
	else {
		return @""; // TODO
	}
}

%new
- (BOOL)isNotificationHiddenAtIndex:(NSUInteger)index {
	NSString *identifier = [self notificationIdentifierAtIndex:index];
	PHContainerView **phContainerView = (inLS) ? &lsPhContainerView : &ncPhContainerView;

	// TODO: settings with whether all notifications are hidden when not selected

	if ([(*phContainerView).selectedAppID isEqualToString:identifier] || !(*phContainerView).selectedAppID) {
		return NO;
	}
	return YES;
}

-(void)viewDidLoad {
	%orig;

	// It's a little gross using a double pointer but it lets LS & NC use the same code
	PHContainerView **phContainerView = (inLS) ? &lsPhContainerView : &ncPhContainerView;

	// Create the PHContainerView
	if (!*phContainerView) {
		*phContainerView = [[PHContainerView alloc] init:(inLS)];
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
	(*phContainerView).updateNotificationTableView = ^void() {
		[self.collectionView reloadData];
	};	
}

- (void)viewDidLayoutSubviews {
	%orig;

 	if (!enabled)
		return;

	PHContainerView **phContainerView = (inLS) ? &lsPhContainerView : &ncPhContainerView;
	self.collectionView.clipsToBounds = YES;

	CGRect phContainerViewFrame = CGRectZero;
	CGRect collectionViewFrame = CGRectZero;
	CGRectEdge edge = ((inLS && [defaults integerForKey:@"iconLocation"] == 0) || (!inLS && [defaults integerForKey:@"ncIconLocation"] == 0)) ? CGRectMinYEdge : CGRectMaxYEdge;
	CGRectDivide(self.view.bounds, &phContainerViewFrame, &collectionViewFrame, appViewSize(inLS).height, edge);

	(*phContainerView).frame = phContainerViewFrame;
	self.collectionView.frame = collectionViewFrame;
}

%new
- (void)insertOrModifyNotification:(NCNotificationRequest*)request {
	if (!enabled)
		return;

	PHContainerView **phContainerView = (inLS) ? &lsPhContainerView : &ncPhContainerView;
	[*phContainerView updateView];
	[*phContainerView selectAppID:[request sectionIdentifier] newNotification:YES];
}

%new
- (void)removeNotification:(NCNotificationRequest*)request {
	if (!enabled)
		return;

	(inLS) ? [lsPhContainerView updateView] : [ncPhContainerView updateView];
}

%end


// Customized hooks for LS, hooking same methods in super class doesn't work
%hook NCNotificationPriorityListViewController

- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
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


// Used to hide notifications that aren't for the selected app
%hook NCNotificationListCollectionViewFlowLayout

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
	const CGFloat PADDING = 8; // For iOS 10. Hope this doesn't change!
	CGFloat curVerticalOffset = 0;
	NSArray *attributes = %orig;
	NCNotificationListViewController* controller = (NCNotificationListViewController*)self.collectionView.delegate;

	NSLog(@"LAYOUT ATTRIBUTES FOR RECT: %@ ARE: %@", NSStringFromCGRect(rect), attributes);

	for (unsigned i = 0; i < [attributes count]; i++) {
		UICollectionViewLayoutAttributes* curAttributes = ((UICollectionViewLayoutAttributes*)[attributes objectAtIndex:i]);
		if ([controller isNotificationHiddenAtIndex:i]) {
			curAttributes.hidden = YES;
		}
		else {
			curAttributes.frame = CGRectMake(PADDING, curVerticalOffset + PADDING, curAttributes.frame.size.width, curAttributes.frame.size.height);
			curVerticalOffset += curAttributes.frame.size.height + PADDING;
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


// Get rid of section headers in notification center
%hook NCNotificationSectionListViewController

-(CGSize)collectionView:(id)arg1 layout:(id)arg2 referenceSizeForHeaderInSection:(long long)arg3 {
	return ([defaults boolForKey:@"ncEnabled"]) ? CGSizeZero : %orig; //TODO: give them some size otherwise spacing is thrown off (8? cell padding)
}

%end
