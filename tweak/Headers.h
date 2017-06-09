

@interface NCNotificationListCollectionViewFlowLayout : UICollectionViewFlowLayout
@end

@interface NCNotificationListClearButton : UIControl
@end

@interface SBNotificationCenterController : NSObject
- (BOOL)isVisible;
- (void)presentAnimated:(BOOL)arg1 completion:(id)arg2;
- (void)presentAnimated:(BOOL)arg1;
@end

@interface BBAction : NSObject
+ (id)actionWithLaunchURL:(NSURL*)url;
@end

@interface SBDashBoardPageControl : UIPageControl
@end

@interface SBDashBoardMainPageView : UIView
@property(retain, nonatomic) UILabel *callToActionLabel;
@end

@interface SBDashBoardClippingLine : UIView
@end

@interface NCNotificationAction : NSObject
@end

@interface NCNotificationSound : NSObject
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic,copy,readonly) NSSet * requestDestinations;
@property (nonatomic,readonly) NCNotificationSound * sound;
@property (nonatomic,readonly) NCNotificationAction * clearAction;
@property (nonatomic,readonly) NCNotificationAction * closeAction;
@property (nonatomic,readonly) NCNotificationAction * defaultAction;
- (NSString*)sectionIdentifier;
@end

@interface NCNotificationListViewController : UICollectionViewController <UICollectionViewDelegateFlowLayout>
-(long long)collectionView:(id)arg1 numberOfItemsInSection:(long long)arg2;
-(long long)numberOfSectionsInCollectionView:(id)arg1;
- (NSString*)notificationIdentifierAtIndex:(NSUInteger)index;
- (NSUInteger)numNotifications;
- (NCNotificationRequest*)notificationRequestAtIndexPath:(NSIndexPath*)path;
- (BOOL)shouldShowNotificationAtIndexPath:(NSIndexPath*)indexPath;
- (void)removeNotification:(NCNotificationRequest*)request;
- (void)insertOrModifyNotification:(NCNotificationRequest*)request;
-(void)setNeedsReloadData:(BOOL)arg1;

@end

@interface BBServer : NSObject
- (void)publishBulletin:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(bool)arg3;
- (void)publishBulletinRequest:(id)arg1 destinations:(unsigned long long)arg2 alwaysToLockScreen:(bool)arg3;
@end

@interface BBBulletin
@property(copy, nonatomic) NSString *sectionID; // @dynamic sectionID;
@property(copy, nonatomic) NSString *title; // @dynamic title;
@property(copy, nonatomic) NSString *message; // @dynamic title;
@property(copy, nonatomic) id defaultAction; // @dynamic defaultAction;
@property(retain, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *bulletinID;
@property(copy, nonatomic) NSString *publisherBulletinID;
@property(retain, nonatomic) NSDate *publicationDate;
@property(retain, nonatomic) NSDate *lastInterruptDate;
@property(nonatomic) BOOL showsMessagePreview;
@property(nonatomic) BOOL clearable;
@property(retain, nonatomic) NSString* subtitle;
@property(retain, nonatomic) NSString* recordID;
@end

@interface BBBulletinRequest : BBBulletin
@end

@interface NCNotificationPriorityList : NSObject {
	NSMutableOrderedSet* _requests;
}
@property (nonatomic,retain) NSMutableOrderedSet * requests;
-(unsigned long long)count;
-(id)_identifierForNotificationRequest:(id)arg1;
@end

@interface UIImage (Private)
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier format:(int)format;
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier format:(int)format scale:(float)scale;
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier roleIdentifier:(id)id format:(int)format scale:(float)scale;
@end



@interface NCNotificationPriorityListViewController : NCNotificationListViewController
- (NSOrderedSet*)allNotificationRequests;
-(NCNotificationPriorityList *)notificationRequestList;
- (NCNotificationRequest*)notificationRequestAtIndexPath:(NSIndexPath*)path;
- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
- (void)modifyNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
- (void)removeNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
-(void)_reloadNotificationViewControllerForHintTextAtIndexPaths:(id)arg1;
-(void)_reloadNotificationViewControllerForHintTextAtIndexPath:(id)arg1;
@end

@interface NCNotificationSectionListViewController : NCNotificationListViewController
@end

@interface NCNotificationListCollectionView : UICollectionView
- (NCNotificationPriorityListViewController*)dataSource;
@end

@interface SBDashBoardNotificationListViewController : UIViewController
- (NCNotificationListCollectionView*)notificationListScrollView;
- (NSUInteger)numNotifications;
- (NSString*)notificationIdentifierAtIndex:(NSUInteger)index;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (void)lockUIFromSource:(int)source withOptions:(id)options;
@end

@interface SBApplication : NSObject
@end

@interface SBApplicationController: NSObject
+ (id)sharedInstance;
- (SBApplication*)applicationWithBundleIdentifier:(NSString*)arg1;
@end

@interface NCNotificationViewController : UIViewController
@property (nonatomic,retain) NCNotificationRequest * notificationRequest;
@end

@interface NCNotificationListCell : UICollectionViewCell
@property (nonatomic,retain) NCNotificationViewController * contentViewController;
@end

@interface NCMaterialView : UIView
@property (assign,nonatomic) double grayscaleValue; 
+(id)materialViewWithStyleOptions:(unsigned long long)arg1;

@end

