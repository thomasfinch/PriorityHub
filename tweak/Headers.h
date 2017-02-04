
@interface BBBulletin
@property(copy, nonatomic) NSString *sectionID; // @dynamic sectionID;
@property(copy, nonatomic) NSString *title; // @dynamic title;
@property(copy, nonatomic) NSString *message; // @dynamic title;
@property(copy, nonatomic) id defaultAction; // @dynamic defaultAction;
@property(retain, nonatomic) NSDate *date;
@property(copy, nonatomic) NSString *bulletinID;
@property(retain, nonatomic) NSDate *publicationDate;
@property(retain, nonatomic) NSDate *lastInterruptDate;
@property(nonatomic) BOOL showsMessagePreview;
@property(nonatomic) BOOL clearable;
@end

@interface NCNotificationPriorityList : NSObject {
	NSMutableOrderedSet* _requests;
}
@end

@interface UIImage (Private)
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier format:(int)format;
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier format:(int)format scale:(float)scale;
+ (UIImage*)_applicationIconImageForBundleIdentifier:(NSString*)identifier roleIdentifier:(id)id format:(int)format scale:(float)scale;
@end

@interface NCNotificationRequest : NSObject
- (NSString*)sectionIdentifier;
@end

@interface NCNotificationPriorityListViewController : UICollectionViewController
- (NSOrderedSet*)allNotificationRequests;
- (NCNotificationRequest*)notificationRequestAtIndexPath:(NSIndexPath*)path;
- (NSString*)notificationIdentifierAtIndex:(NSUInteger)index;
- (NSUInteger)numNotifications;
- (void)insertNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
- (void)modifyNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
- (void)removeNotificationRequest:(NCNotificationRequest*)request forCoalescedNotification:(id)notification;
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

