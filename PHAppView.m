#import "PHAppView.h"
#import "PHController.h"

@implementation PHAppView

@synthesize appID;
@synthesize tapDelegate;

- (id)initWithFrame:(CGRect)frame appID:(NSString*)applicationID {
	if (self = [super initWithFrame:frame]) {
		appID = applicationID;

		iconView = [[UIImageView alloc] initWithImage:[PHController iconForAppID:appID]];
		if ([[[PHController sharedInstance].prefsDict objectForKey:@"showNumbers"] boolValue])
			iconView.frame = CGRectMake((frame.size.width - [PHController iconSize])/2, 5, [PHController iconSize], [PHController iconSize]);
		else
			iconView.frame = CGRectMake((frame.size.width - [PHController iconSize])/2, (frame.size.width - [PHController iconSize])/2, [PHController iconSize], [PHController iconSize]);
		[self addSubview:iconView];

		if ([[[PHController sharedInstance].prefsDict objectForKey:@"showNumbers"] boolValue]) {
			numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, iconView.frame.origin.y + CGRectGetHeight(iconView.frame) + ((CGRectGetHeight(frame) - (iconView.frame.origin.y + CGRectGetHeight(iconView.frame))) - 15) / 2, CGRectGetWidth(frame), 15)];
			numberLabel.textColor = [UIColor whiteColor];
			numberLabel.textAlignment = NSTextAlignmentCenter;
			[self addSubview:numberLabel];
		}

		UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:tapGestureRecognizer];
	}
	return self;
}

- (void)updateNumNotifications {
	if (numberLabel)
		numberLabel.text = [NSString stringWithFormat:@"%ld",(long)[[PHController sharedInstance] numNotificationsForAppID:appID]];
}

- (void)handleSingleTap:(UITapGestureRecognizer*)gestureRecognizer {
	[tapDelegate performSelector:@selector(handleAppViewTapped:) withObject:self];
}

@end