#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface PriorityHubLockScreenListController: PSListController
@end

@implementation PriorityHubLockScreenListController

- (void)showTestLockScreenNotification {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.thomasfinch.priorityhub-testnotification-ls"), nil, nil, true);
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"LockScreen" target:self] retain];
	}
	return _specifiers;
}

@end
