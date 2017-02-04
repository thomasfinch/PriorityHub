#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface PriorityHubNotificationCenterListController: PSListController
@end

@implementation PriorityHubNotificationCenterListController

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"NotificationCenter" target:self] retain];
	}
	return _specifiers;
}

@end
