#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <AppList/AppList.h>
#import "substrate.h"
#import "Headers.h"
#import "PHContainerView.h"
#import "PHPullToClearView.h"

NSUserDefaults *defaults = nil;
// BBServer *bbServer;

PHContainerView *phContainerView = nil;

CGSize appViewSize() {
	CGFloat width = 0;
	switch ([defaults integerForKey:@"iconSize"]) {
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

	CGFloat height = ([defaults boolForKey:@"numberStyle"] == 1) ? width * 1.4 : width;
	return CGSizeMake(width, height);
}

// NSString* identifierForListItem(SBAwayListItem *listItem) {
// 	if ([listItem isKindOfClass:%c(SBAwayBulletinListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmBulletinListItem)]) {
// 		return [[(SBAwayBulletinListItem*)listItem activeBulletin] sectionID];
// 	}
// 	else if ([listItem isKindOfClass:%c(SBAwayCardListItem)]) {
// 		return [[(SBAwayCardListItem*)listItem cardItem] identifier];
// 	}
// 	else if ([listItem isKindOfClass:%c(SBAwaySystemAlertItem)]) {
// 		return @"systemAlert";
// 	}

// 	return @"noIdentifier";
// }

// UIImage* iconForListItem(SBAwayListItem* listItem) {
// 	UIImage *icon = nil;

// 	if ([listItem isKindOfClass:%c(SBSnoozedAlarmListItem)] || [listItem isKindOfClass:%c(SBSnoozedAlarmBulletinListItem)] || [listItem isKindOfClass:%c(SBAwayBulletinListItem)])
// 		icon = [UIImage _applicationIconImageForBundleIdentifier:identifierForListItem(listItem) format:2 scale:[UIScreen mainScreen].scale];
// 	else if ([listItem respondsToSelector:@selector(iconImage)])
// 		icon = [listItem iconImage];
// 	else
// 		icon = [[UIImage alloc] init]; //Handle the case where somehow an icon still hasn't been found yet

// 	return icon;
// }

UIImage* iconForIdentifier(NSString* identifier) {
	NSLog(@"ICON FOR IDENTIFIER: %@", identifier);

	return [[ALApplicationList sharedApplicationList] iconOfSize:ALApplicationIconSizeLarge forDisplayIdentifier:identifier];

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
NCNotificationListContainerViewController might be nice to put phcontainerview in
NCNotificationChronologicalList & NCNotificationHiddenRequestsList seem useful (used in notification center)


*/


%hook NCNotificationPriorityList

-(id)requestAtIndex:(unsigned long long)arg1 {
	NSLog(@"REQUEST AT INDEX: %llu", arg1);
	return %orig;
}

-(NSMutableOrderedSet *)requests {
	NSLog(@"REQUESTS");
	NSMutableOrderedSet *orig = %orig;
	NSMutableOrderedSet *newRequests = [NSMutableOrderedSet new];
	NSLog(@"ORIGINAL: %@", orig);

	for (int i = 0; i < [orig count]; i++) {
		NCNotificationRequest* request = [orig objectAtIndex:i];
		if (!phContainerView.selectedAppID || [[request sectionIdentifier] isEqualToString:phContainerView.selectedAppID]) {
			[newRequests addObject:request];
		}
	}

	return newRequests;
}

-(void)setRequests:(NSMutableOrderedSet *)arg1 {
	NSLog(@"SET REQUESTS: %@", arg1);
	%orig;
}

%end


// %hook NCNotificationListCollectionViewFlowLayout

// - (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
// 	NSLog(@"LAYOUT ATTRIBUTES FOR ROW: %ld ARE: %@", (long)indexPath.row, %orig);
// 	return %orig;
// 	// UICollectionViewLayoutAttributes *attributes = %orig;

// 	// if (indexPath.row % 2 == 0) {
// 	// 	attributes.hidden = YES;
// 	// 	attributes.size = CGSizeZero;
// 	// 	attributes.frame = attributes.bounds = CGRectZero;
// 	// }

// 	// return nil;
// }

// - (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect {
// 	NSLog(@"LAYOUT ATTRIBUTES FOR RECT: %@ ARE: %@", NSStringFromCGRect(rect), %orig);
// 	NSArray *orig = %orig;
// 	for (int i = 0; i < [orig count]; i++) {
// 		if (i % 2 == 0) {
// 			((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).hidden = YES;
// 			((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).frame = CGRectZero;
// 			((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).bounds = CGRectZero;
// 			((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).size = CGSizeZero;
// 		}
// 		else if (i != 0) {
// 			((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).frame = CGRectMake(((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i-1]).frame.origin.x, ((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i-1]).frame.origin.y, ((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).frame.size.width, ((UICollectionViewLayoutAttributes*)[orig objectAtIndex:i]).frame.size.height);
// 		}
// 	}
// 	return orig;
// }

// %end


// These functions are called for both LS and NC notifications
%hook NCBulletinNotificationSource

-(void)observer:(id)observer addBulletin:(BBBulletin*)bulletin forFeed:(unsigned long long)arg3 playLightsAndSirens:(BOOL)arg4 withReply:(/*^block*/id)arg5 {
	NSLog(@"OBSERVER ADD BULLETIN: %@ FOR FEED:%llu", bulletin, arg2);
	// if (!phContainerView) {
	// 	phContainerView = [PHContainerView new];
	// }
	// phContainerView.selectedAppID = bulletin.sectionID;
	%orig;
	// delay calling orig until correct app id is selected
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

%hook NCNotificationPriorityListViewController

// %new
// - (NSUInteger)filteredNumNotifications {
// 	return 3;
// }

// %new
// - (NSUInteger)filteredIndexForRealIndex:(NSUInteger)realIndex {

// }

%new
- (NSUInteger)numNotifications {
	return [[self allNotificationRequests] count];
}

%new
- (NSString*)notificationIdentifierAtIndex:(NSUInteger)index {
	return [[self notificationRequestAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]] sectionIdentifier];
}

// -(id)notificationRequestAtIndexPath:(NSIndexPath*)arg1 {
// 	NSLog(@"NOTIFICATION REQUEST AT INDEX %ld IS %@", (long)arg1.row, %orig);
// 	return nil;
// }

- (void)viewDidLoad {
	%orig;

	if (![defaults boolForKey:@"enabled"])
		return;

	// Create the PHContainerView
	if (!phContainerView) {
		phContainerView = [PHContainerView new];
		// phContainerView.backgroundColor = [UIColor blueColor];
	}
	if (![phContainerView superview]) {
		[self.view addSubview:phContainerView];
	}

	// self.view.backgroundColor = [UIColor redColor];

	// Setup notification fetching block
	phContainerView.getCurrentNotifications = ^NSDictionary*() {
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
	phContainerView.updateNotificationTableView = ^void() {
		NSLog(@"UPDATING NOTIFICATION TABLE VIEW");
		// [self.collectionView reloadData];
		// [self.collectionView layoutSubviews];
	};	
}

- (void)viewDidLayoutSubviews {
	%orig;
	
	if (![defaults boolForKey:@"enabled"])
		return;

	UIView *scrollView = [self.view subviews][0];
	phContainerView.frame = CGRectMake(0, 0, scrollView.frame.size.width, appViewSize().height);
	scrollView.frame = CGRectMake(0, appViewSize().height, scrollView.frame.size.width, [scrollView superview].bounds.size.height - appViewSize().height);
}

- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	NSLog(@"INSERT NOTIFICTION REQUEST");
	if (![defaults boolForKey:@"enabled"])
		return;
	[phContainerView updateView];
	[phContainerView selectAppID:[request sectionIdentifier] newNotification:YES];

	// Maybe wait to call %orig until after section has changed
}

- (void)modifyNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	if (![defaults boolForKey:@"enabled"])
		return;
	[phContainerView updateView];
	[phContainerView selectAppID:[request sectionIdentifier] newNotification:YES];
}

- (void)removeNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification {
	%orig;
	if (![defaults boolForKey:@"enabled"])
		return;
	[phContainerView updateView];
}

// // Doesn't really work... icon & garbled text still show up on left side of screen
// - (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
// 	NSLog(@"LKASHDFLKHASLKDHF SIZE FOR ITEM AT INDEX PATH");
// 	if (indexPath.row % 2 == 0)
// 		return CGSizeZero;
// 	return %orig;
// }

// -(void)hideRequestsForNotificationSectionIdentifier:(id)arg1 subSectionIdentifier:(id)arg2 {
// 	%orig;
// 	NSLog(@"HIDE REQUESTS FOR SECTION IDENTIFIER: %@", arg1);
// }
// -(void)showRequestsForNotificationSectionIdentifier:(id)arg1 subSectionIdentifier:(id)arg2 {
// 	%orig;
// 	NSLog(@"SHOW REQUESTS FOR SECTION IDENTIFIER: %@", arg1);
// }

// -(void)collectionView:(id)arg1 willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
// 	%orig;
// 	if (cell.bounds.size.height == 0)
// 		cell.hidden = YES;
// 	else
// 		cell.hidden = NO;
// }

// -(id)collectionView:(id)arg1 cellForItemAtIndexPath:(NSIndexPath*)arg2 {
// 	NSLog(@"CELL FOR ITEM AT INDEX PATH: %@", arg2);
// 	if (arg2.row > 0) {
// 		return %orig(arg1, [NSIndexPath indexPathForRow:arg2.row-1 inSection:0]);
// 	}
// 	return %orig;
// }

// -(long long)collectionView:(id)arg1 numberOfItemsInSection:(long long)arg2 {
// 	NSLog(@"NUMBER OF ITEMS IN SECTION");

// 	return %orig;
// 	// if (phContainerView.selectedAppID)
// 	// 	return %orig;
// 	// return 0;
// }

// -(long long)numberOfSectionsInCollectionView:(id)arg1 {
// 	NSLog(@"NUMBER OF SECTIONS");
// 	return 1;
// }

// - (void)dealloc {
// 	%orig;
// 	if (phContainerView) {
// 		[phContainerView release];
// 		phContainerView = nil;
// 	}
// }

%end
