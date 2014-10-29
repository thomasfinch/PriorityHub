#import "PHController.h"
#import <objc/runtime.h>

const NSString *kPrefsPath = @"/var/mobile/Library/Preferences/com.thomasfinch.priorityhub.plist";

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
    NSLog(@"CONTROLLER ADD NOTIFICATOIN FOR APP ID: %@",appID);
    [self.appsScrollView addNotificationForAppID:appID];
}

- (void)removeNotificationForAppID:(NSString*)appID {
    NSLog(@"CONTROLLER REMOVE NOTIFICATION FOR APP ID: %@",appID);
    [self.appsScrollView removeNotificationForAppID:appID];
}

- (void)pullToClearTriggered {
    if (_bulletinObserver && appsScrollView.selectedAppID) {
        [_bulletinObserver clearSection:appsScrollView.selectedAppID];
    }
}

- (void)clearAllNotificationsForUnlock {
    [appsScrollView removeAllAppViews];
}

- (NSInteger)numNotificationsForAppID:(NSString*)appID {
    NSInteger count = 0;
    for (unsigned long long i = 0; i < [_listController count]; i++) {
        if ([[[[_listController listItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] activeBulletin] sectionID] isEqualToString:appID])
            count++;
    }

    return count;
}

- (void)updatePrefsDict
{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] init];
    NSDictionary *storedPrefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(CFPreferencesCopyKeyList(CFSTR("com.thomasfinch.priorityhub"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost), CFSTR("com.thomasfinch.priorityhub"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost)); 
    if (storedPrefs) {
        [preferences addEntriesFromDictionary:storedPrefs];
    }

    NSLog(@"UPDATED PREFS DICT");
    //Add preferences if they don't already exist
    if (![preferences objectForKey:@"showNumbers"])
        [preferences setObject:[NSNumber numberWithBool:YES] forKey:@"showNumbers"];
    if (![preferences objectForKey:@"showSeparators"])
        [preferences setObject:[NSNumber numberWithBool:NO] forKey:@"showSeparators"];
    if (![preferences objectForKey:@"colorizeSelected"])
        [preferences setObject:[NSNumber numberWithBool:YES] forKey:@"colorizeSelected"];
    if (![preferences objectForKey:@"collapseOnLock"])
        [preferences setObject:[NSNumber numberWithBool:YES] forKey:@"collapseOnLock"];
    if (![preferences objectForKey:@"iconLocation"])
        [preferences setObject:[NSNumber numberWithInt:0] forKey:@"iconLocation"];

    prefsDict = preferences;
    NSLog(@"Prefs dict: %@",prefsDict);
    [prefsDict writeToFile:kPrefsPath atomically:YES];
}

+ (UIImage*)iconForAppID:(NSString*)appID {
	NSBundle *iconsBundle = [NSBundle  bundleWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
    UIImage *img = [[UIImage class] performSelector:@selector(imageNamed:inBundle:) withObject:[NSString stringWithFormat:@"%@.png",appID] withObject:iconsBundle]; //[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];

    if (img)
        return img;
    else {
        id application;
        //If iOS 7: [[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:appID]
        application = [[objc_getClass("SBApplicationController") sharedInstance] applicationWithBundleIdentifier:appID]; //iOS 8
        return [[[objc_getClass("SBApplicationIcon") alloc] initWithApplication:application] getIconImage:1];
    }
}

+ (CGFloat)iconSize {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return 40.0;
    else
        return 30.0;
}

+ (BOOL)isTweakInstalled:(NSString *)name {
    return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/MobileSubstrate/DynamicLibraries/%@.dylib",name]];
}

@end
