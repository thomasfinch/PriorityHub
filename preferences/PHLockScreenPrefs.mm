#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface PriorityHubLockScreenListController: PSListController
@end

@implementation PriorityHubLockScreenListController

- (void)sendTestNotification {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.thomasfinch.priorityhub-testnotification"), nil, nil, true);
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"LockScreen" target:self] retain];
	}
	return _specifiers;
}

@end
