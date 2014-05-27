#import <Preferences/Preferences.h>

@interface PriorityHubListController: PSListController
@end

@implementation PriorityHubListController

-(void)TFTwitterButtonTapped
{
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

-(void)JGTwitterButtonTapped
{
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

-(void)DonateButtonTapped
{
    NSURL *donateURL = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=tomf64%40gmail%2ecom&lc=US&item_name=Thomas%20Finch&item_number=Priority%20Lock&no_note=0&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHostedGuest"];
    [[UIApplication sharedApplication] openURL:donateURL];
}

-(void)GithubButtonTapped
{
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
