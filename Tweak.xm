#import <UIKit/UIKit.h>
#import "Headers.h"
#import "PHController.h"

#ifndef DEBUG
  #define NSLog
#endif
#ifdef DEBUG
    #define PHLog(fmt, ...) NSLog((@"[PRIORITYHUB]: "  fmt), __LINE__, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
    #define PHLog(fmt, ...)
#endif



%hook SBLockScreenNotificationListView

- (void)layoutSubviews {
  %orig;

  PHLog(@"laying out subviews");

  UIView *containerView = MSHookIvar<UIView*>(self, "_containerView");


  [PHController sharedInstance].appsScrollView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y, containerView.frame.size.width, 55);
  [self addSubview:[PHController sharedInstance].appsScrollView];

  containerView.frame = CGRectMake(containerView.frame.origin.x, containerView.frame.origin.y + 55 + 2, containerView.frame.size.width, containerView.frame.size.height - 55 - 2);

}

-(BOOL)tableView:(id)view shouldDrawTopSeparatorForSection:(int)section {
  //This doesn't really work, should use the original method
  if ([[[PHController sharedInstance].prefsDict objectForKey:@"showSeparators"] boolValue])
    return %orig;
  else
    return NO;
}

%end


%hook SBLockScreenNotificationListController

-(void)_updateModelAndViewForAdditionOfItem:(id)item {
  %orig;
  NSLog(@"UPDATE MODEL AND VIEW FOR ADDITION OF ITEM: %@",item);
  [PHController sharedInstance].listController = self;
  [PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
  [[PHController sharedInstance] addNotificationForAppID:[[item activeBulletin] sectionID]];
}

-(void)_updateModelForRemovalOfItem:(id)item updateView:(BOOL)view {
  %orig;
  NSLog(@"UPDATE MODEL FOR REMOVAL OF ITEM (BOOL): %@",item);
  [PHController sharedInstance].listController = self;
  [PHController sharedInstance].bulletinObserver = MSHookIvar<BBObserver*>(self, "_observer");
  [[PHController sharedInstance] removeNotificationForAppID:[[item activeBulletin] sectionID]];
}

%end
