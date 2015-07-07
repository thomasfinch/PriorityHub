#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>


@interface SBAwayListItem : NSObject
@end

@interface SBApplicationIcon : NSObject
@end

@interface UIImage (Private)
+(id) _applicationIconImageForBundleIdentifier:(NSString*)displayIdentifier format:(int)form scale:(CGFloat)scale;
@end

@interface SBIconModel
- (id)expectedIconForDisplayIdentifier:(NSString*)str;
@end

@interface SBApplicationController
+ (id)sharedInstance;
- (id)applicationWithBundleIdentifier:(NSString*)id;
- (id)applicationWithDisplayIdentifier:(NSString*)id;
@end

@protocol SBLockScreenNotificationModel
- (SBAwayListItem *)listItemAtIndexPath:(NSIndexPath *)arg1;
@end

@interface SBLockScreenManager
+(id)sharedInstance;
- (void)_lockUI;
- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (void)_setUILocked:(_Bool)arg1;
@end

@interface BBAction
+ (id)action;
@end

@interface BBServer
- (void)_publishBulletinRequest:(id)arg1 forSectionID:(id)arg2 forDestinations:(unsigned int)arg3 alwaysToLockScreen:(BOOL)arg4;
- (void)demo_lockscreen:(unsigned long long)arg1;
- (void)_sendAddBulletin:(id)arg1 toFeeds:(unsigned int)arg2;
@end

@interface SpringBoard : UIApplication
- (void)lockButtonUp:(id)arg1;
- (void)lockDevice:(id)arg1;
@end

@interface BBBulletin
@property(copy, nonatomic) NSString *sectionID; // @dynamic sectionID;
@property(copy, nonatomic) NSString *title; // @dynamic title;
@property(copy, nonatomic) NSString *message; // @dynamic title;
@property(copy, nonatomic) BBAction *defaultAction; // @dynamic defaultAction;
@property(retain, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *bulletinID;
@property(retain, nonatomic) NSDate *publicationDate;
@property(retain, nonatomic) NSDate *lastInterruptDate;
@property(nonatomic) BOOL showsMessagePreview;
@end

@interface BBBulletinRequest : BBBulletin
- (void)publish;
- (void)generateBulletinID;
@property(nonatomic) BOOL clearable;
@property(copy, nonatomic) BBAction *dismissAction;
@end

@interface BBObserver
- (void)clearSection:(NSString*)arg1;
- (id)parametersForSectionID:(NSString*)sectionID;
@end

@interface SBAwayBulletinListItem : SBAwayListItem
@property(retain) BBBulletin* activeBulletin;
-(Class)class;
@end

@interface SBSCardItem : NSObject <NSCopying, NSSecureCoding>
@property(copy, nonatomic) UIImage *thumbnail; // @synthesize thumbnail=_thumbnail;
@property(copy, nonatomic) NSString *bundleName; // @synthesize bundleName=_bundleName;
@property(nonatomic) BOOL requiresPasscode; // @synthesize requiresPasscode=_requiresPasscode;
@property(copy, nonatomic) NSData *iconData; // @synthesize iconData=_iconData;
@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface SBAwayCardListItem : SBAwayListItem
@property(retain, nonatomic) UIImage *iconImage;
@property(retain, nonatomic) UIImage *cardThumbnail;
@property(readonly, nonatomic) NSString *body;
@property(readonly, nonatomic) NSString *title;
@property(copy, nonatomic) SBSCardItem *cardItem;
- (_Bool)inertWhenLocked;
- (id)sortDate;
- (NSString*)title;
- (void)dealloc;
@end

@interface SBAwaySystemAlertItem : SBAwayListItem
{
    id _currentAlert;
    NSString *_title;
    UIImage *_appImage;
    NSString *_message;
    long long _displayedButtonIndex;
    _Bool _isAlarm;
}

- (_Bool)isAlarm;
- (void)buttonPressed;
- (id)sortDate;
- (id)iconImage;
- (id)title;
- (id)message;
- (void)setCurrentAlert:(id)arg1;
- (id)currentAlert;
- (void)dealloc;
- (id)initWithSystemAlert:(id)arg1;
- (id)init;

@end

@interface SBLockScreenNotificationTableView : UITableView
@end

@interface SBLockScreenNotificationCell {
	UIView* _topSeparatorView;
	UIView* _bottomSeparatorView;
}
-(id)initWithStyle:(long long)style reuseIdentifier:(NSString*)identifier;
@end

@interface SBLockScreenNotificationListView : UIView {
	UITableView* _tableView;
	UIView* _containerView;
	id<SBLockScreenNotificationModel> _model;
}
@property(assign, nonatomic) id<SBLockScreenNotificationModel> model;
- (void)_cellTextFadeTimerFired:(id)arg1;
- (void)_textDisabledTimerFired:(id)arg1;
- (void)_clearTextFadeTimer;
- (void)_clearTextDisabledTimer;
- (void)_resetAllFadeTimers;
-(void)resetTimers;
-(void)_resetAllFadeTimers;
-(BOOL)_disableIdleTimer:(BOOL)timer;
-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
-(void)setInScreenOffMode:(BOOL)screenOffMode;
-(void)addSubview:(UIView*)arg1;
@end

@interface SBLockScreenNotificationModel : NSObject
- (SBAwayListItem *)listItemAtIndexPath:(NSIndexPath *)arg1;
- (unsigned long long)count;
@end

@interface SBLockScreenNotificationListController {
	SBLockScreenNotificationListView* _notificationView;
	NSMutableArray* _listItems;
  BBObserver* _observer;
}
-(id)listItemAtIndexPath:(NSIndexPath*)indexPath;
-(BOOL)respondsToSelector:(SEL)selector;
-(void)_showTestBulletin;
-(void)observer:(BBObserver*)observer removeBulletin:(BBBulletin*)bulletin;
-(void)observer:(BBObserver*)observer addBulletin:(id)bulletin forFeed:(unsigned long long)feed;
- (void)observer:(id)arg1 addBulletin:(id)arg2 forFeed:(unsigned long long)arg3 playLightsAndSirens:(_Bool)arg4 withReply:(id)arg5;
-(void)loadView;
-(int)count;
@end

@interface CTCallCenter
@property(retain) NSSet *currentCalls;
@end

@interface IMAVCallManager
+(instancetype)sharedInstance;
-(BOOL)hasActiveCall;
@end
