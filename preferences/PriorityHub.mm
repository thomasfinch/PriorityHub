#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface PriorityHubListController: PSListController
@end

@implementation PriorityHubListController

- (void)sendTestNotification {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.thomasfinch.priorityhub-testnotification"), nil, nil, true);
}

- (void)TFTwitterButtonTapped {
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/tomf64"];
    if ([app canOpenURL:tweetbot])
        [app openURL:tweetbot];
    else {
        NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=tomf64"];
        if ([app canOpenURL:twitterapp])
            [app openURL:twitterapp];
        else {
            NSURL *twitterweb = [NSURL URLWithString:@"http://twitter.com/tomf64"];
            [app openURL:twitterweb];
        }
    }
}

- (void)JGTwitterButtonTapped {
    UIApplication *app = [UIApplication sharedApplication];
    NSURL *tweetbot = [NSURL URLWithString:@"tweetbot:///user_profile/JeremyGoulet"];
    if ([app canOpenURL:tweetbot])
        [app openURL:tweetbot];
    else {
        NSURL *twitterapp = [NSURL URLWithString:@"twitter:///user?screen_name=JeremyGoulet"];
        if ([app canOpenURL:twitterapp])
            [app openURL:twitterapp];
        else {
            NSURL *twitterweb = [NSURL URLWithString:@"http://twitter.com/JeremyGoulet"];
            [app openURL:twitterweb];
        }
    }
}

- (void)GithubButtonTapped {
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/thomasfinch/Priority-Hub"];
    [[UIApplication sharedApplication] openURL:githubURL];
}

- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PriorityHub" target:self] retain];
	}
	return _specifiers;
}

@end
