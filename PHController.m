#import "PHController.h"
#import "substrate.h"

NSString * const kPrefsPath = @"/var/mobile/Library/Preferences/com.thomasfinch.priorityhub.plist";

@implementation PHController

@synthesize prefsDict;
@synthesize appsScrollView;

+ (PHController*)sharedInstance {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
    NSLog(@"PHCONTROLLER INIT");
    if (self = [super init]) {
        [self updatePrefsDict];
    }
    return self;
}

- (void)addNotificationForAppID:(NSString*)appID {
    NSLog(@"CONTROLLER ADD NOTIFICATION FOR APP ID: %@",appID);
    [self.appsScrollView addNotificationForAppID:appID];
}

- (void)removeNotificationForAppID:(NSString*)appID {
    NSLog(@"CONTROLLER REMOVE NOTIFICATION FOR APP ID: %@",appID);
    [self.appsScrollView removeNotificationForAppID:appID];
}

- (void)pullToClearTriggered {
    NSLog(@"PULL TO CLEAR TRIGGERED");
    if (_bulletinObserver && appsScrollView.selectedAppID) {
        [_bulletinObserver clearSection:appsScrollView.selectedAppID];
    }
    
    [appsScrollView performSelector:@selector(selectApp:) withObject:nil];
}

- (void)clearAllNotificationsForUnlock {
    [appsScrollView removeAllAppViews];
}

- (NSInteger)numNotificationsForAppID:(NSString*)appID {
    NSInteger count = 0;
    for (unsigned long long i = 0; i < [_listController count]; i++) {
        id listItem = [_listController listItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if ([listItem respondsToSelector:@selector(activeBulletin)] && [[[listItem activeBulletin] sectionID] isEqualToString:appID])
            count++;
    }

    return count;
}

- (void)updatePrefsDict
{
    prefsDict = [[NSUserDefaults alloc] initWithSuiteName:@"com.thomasfinch.priorityhub"];

    [prefsDict registerDefaults:@{
        @"showNumbers": @YES,
        @"showSeparators": @NO,
        @"colorizeSelected": @NO,
        @"collapseOnLock": @YES,
        @"enablePullToClear": @YES,
        @"privacyMode": @NO,
        @"iconLocation": [NSNumber numberWithInt:0],
        @"numberStyle": [NSNumber numberWithInt:0],
        @"verticalAdjustment": [NSNumber numberWithFloat:0]
    }];
}

+ (UIImage*)iconForAppID:(NSString*)appID {
    //Get custom priority hub icon if it exists
	NSBundle *iconsBundle = [NSBundle  bundleWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
    UIImage *img = [[UIImage class] performSelector:@selector(imageNamed:inBundle:) withObject:[NSString stringWithFormat:@"%@.png",appID] withObject:iconsBundle]; //[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];

    if (img)
        return img;
    else
        return [UIImage _applicationIconImageForBundleIdentifier:appID format:0 scale:[UIScreen mainScreen].scale];
}

+ (CGFloat)iconSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 40.0;
    else
        return 30.0;
}

// - (void)dealloc {
//     [prefsDict release];
//     [super dealloc];
// }

@end
