#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface PriorityHubNotificationCenterListController: PSListController
@end

@implementation PriorityHubNotificationCenterListController

- (void)showTestNotificationCenterNotification {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.thomasfinch.priorityhub-testnotification-nc"), nil, nil, true);
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"NotificationCenter" target:self] retain];
	}
	return _specifiers;
}

@end
