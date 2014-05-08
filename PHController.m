#import "PHController.h"

#define kPrefsPath @"/var/mobile/Library/Preferences/com.thomasfinch.priorityhub.plist"

@implementation PHController

@synthesize prefsDict;
@synthesize appListView;
@synthesize curAppID;

- (id)init
{
    self = [super init];
    if (self)
    {
        appViewsDict = [[NSMutableDictionary alloc] init];
        curAppID = nil;
        appListView = [[UIScrollView alloc] init];
        iconsBundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];

        selectedView = [[UIView alloc] init];
        selectedView.backgroundColor = [UIColor colorWithWhite:0.75f alpha:0.3f];
        selectedView.layer.cornerRadius = 10.0f;
        selectedView.layer.masksToBounds = YES;
    }
    return self;
}

- (float)iconSize
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) //if device is an ipad
        return 40.0f;
    else
        return 30.0f;
}

- (float)viewWidth
{
    return [self iconSize] * 1.55;
}

- (float)viewHeight
{
    if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        return [self iconSize] * 1.85;
    else
        return [self viewWidth];
}

- (void)updatePrefsDict
{
    if (prefsDict)
        [prefsDict release];
    prefsDict = [[NSMutableDictionary alloc] init];
    if ([NSDictionary dictionaryWithContentsOfFile:kPrefsPath])
        [prefsDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPrefsPath]];
    
    //Add preferences if they don't already exist
    if (![prefsDict objectForKey:@"showNumbers"])
        [prefsDict setObject:[NSNumber numberWithBool:YES] forKey:@"showNumbers"];
    if (![prefsDict objectForKey:@"iconLocation"])
        [prefsDict setObject:[NSNumber numberWithInt:0] forKey:@"iconLocation"];
    
    [prefsDict writeToFile:kPrefsPath atomically:YES];
}

- (BOOL)isTweakInstalled:(NSString *)name
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/Library/MobileSubstrate/DynamicLibraries/%@.dylib",name]];
}

- (UIImage *)iconForAppID:(NSString *)appID
{
    if (!iconsBundle)
        iconsBundle = [[NSBundle alloc] initWithPath:@"/Library/Application Support/PriorityHub/Icons.bundle"];
    
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",appID] inBundle:iconsBundle];
    if (img)
        return img;
    else
        return [[[objc_getClass("SBApplicationIcon") alloc] initWithApplication:[[objc_getClass("SBApplicationController") sharedInstance] applicationWithDisplayIdentifier:appID]] getIconImage:1];

}

- (void)layoutSubviews
{
    //Remove all subviews and start fresh
    for (UIView *v in [appListView subviews])
        [v removeFromSuperview];

    [appListView addSubview:selectedView];

    //Put all app views in scroll view
    appListView.contentSize = CGSizeMake(0, [self viewHeight]);
    float totalViewWidth = [[appViewsDict allKeys] count] * [self viewWidth];
    float startX = (appListView.frame.size.width - totalViewWidth)/2;
    if (startX < 0)
        startX = 0;
    for (UIView *appView in [appViewsDict allValues])
    {
        appView.frame = CGRectMake(startX + appListView.contentSize.width, 0, [self viewWidth], [self viewHeight]);
        appListView.contentSize = CGSizeMake(appListView.contentSize.width + [self viewWidth], [self viewHeight]);
        [appListView addSubview:appView];
    }
}

- (void)selectAppID:(NSString*)appId
{
    if (!appId || [appId isEqualToString:curAppID])
    {
        curAppID = nil;
        [notificationsTableView reloadData];

        [UIView animateWithDuration:0.15f animations:^{
            selectedView.alpha = 0.0f;
            notificationsTableView.alpha = 0.0f;
        }completion:^(BOOL completed){}];
    }
    else
    {
        // if (shouldBlockFade && controller)
        //     [MSHookIvar<id>(controller,"_notificationView") _resetAllFadeTimers];
        // shouldBlockFade = YES;

        BOOL wasAppSelected = (curAppID != nil);
        curAppID = appId;
        [notificationsTableView reloadData];
        if (!wasAppSelected)
            selectedView.frame = ((UIView*)[appViewsDict objectForKey:appId]).frame;
        
        [UIView animateWithDuration:0.15f animations:^{
            selectedView.alpha = 1.0f;
            notificationsTableView.alpha = 1.0f;
            if (wasAppSelected)
                selectedView.frame = ((UIView*)[appViewsDict objectForKey:appId]).frame;
        }completion:^(BOOL completed){}];
    }
}

- (void)addNotificationForAppID:(NSString *)appId
{
    if (![appViewsDict objectForKey:appId])
    {
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(appListView.contentSize.width, 0, [self viewWidth], [self viewHeight])];
        containerView.tag = 1;
        
        UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [containerView addGestureRecognizer:singleFingerTap];
        
        UIImageView *iconImageView = [[UIImageView alloc] initWithImage:[self iconForAppID:appId]];
        iconImageView.frame = CGRectMake(([self viewWidth] - [self iconSize])/2, 5, [self iconSize], [self iconSize]);
        [containerView addSubview:iconImageView];
        
        if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
        {
            UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, iconImageView.frame.origin.y + iconImageView.frame.size.height + ((containerView.frame.size.height - (iconImageView.frame.origin.y + iconImageView.frame.size.height)) - 15) / 2, [self viewWidth], 15)];
            numberLabel.text = @"1";
            numberLabel.textColor = [UIColor whiteColor];
            numberLabel.textAlignment = UITextAlignmentCenter;
            [containerView addSubview:numberLabel];
        }
        else
            iconImageView.frame = CGRectMake(([self viewHeight] - [self iconSize])/2, ([self viewWidth] - [self iconSize])/2, [self iconSize], [self iconSize]);
        
        
        [appViewsDict setObject:containerView forKey:appId];
        [self layoutSubviews];
    }
    else
    {
        ((UIView*)[appViewsDict objectForKey:appId]).tag++;
        if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
            ((UILabel*)[[appViewsDict objectForKey:appId] subviews][1]).text = [NSString stringWithFormat:@"%li",((UIView*)[appViewsDict objectForKey:appId]).tag];
    }

    [self selectAppID:appId];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)recognizer
{
    [self selectAppID:[appViewsDict allKeysForObject:recognizer.view][0]];
}

- (void)removeNotificationForAppID:(NSString *)appId
{
    ((UIView*)[appViewsDict objectForKey:appId]).tag--;
        if ([[prefsDict objectForKey:@"showNumbers"] boolValue])
            ((UILabel*)[[appViewsDict objectForKey:appId] subviews][1]).text = [NSString stringWithFormat:@"%li",((UIView*)[appViewsDict objectForKey:appId]).tag];

    if (((UIView*)[appViewsDict objectForKey:appId]).tag == 0)
    {
        [[appViewsDict objectForKey:appId] release];
        [appViewsDict removeObjectForKey:appId];
        [self layoutSubviews];
    }
}

- (void)removeAllNotificationsForAppID:(NSString *)appId
{
    [appViewsDict removeObjectForKey:appId];
    [self layoutSubviews];
}

- (void)removeAllNotifications
{
    for (UIView *appView in [appViewsDict allValues])
        [appView removeFromSuperview];

    [appViewsDict removeAllObjects];
    [self layoutSubviews];
}

@end
