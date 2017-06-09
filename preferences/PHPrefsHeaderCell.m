#import <Preferences/PSTableCell.h>

//Mostly the same as FLASHHeaderCell.m
//Thanks agian, David

@interface PHPrefsHeaderCell : PSTableCell {
	UIImageView *iconView;
	UILabel *titleLabel;
}
@end

@implementation PHPrefsHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)reuseIdentifier specifier:(id)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		self.backgroundColor = [UIColor clearColor];

		titleLabel = [UILabel new];
		titleLabel.text = @"Priority Hub";
		titleLabel.font = [UIFont systemFontOfSize:25];
		[self addSubview:titleLabel];

		iconView = [UIImageView new];
		iconView.image = [UIImage imageNamed:@"PriorityHub" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/PriorityHub.bundle"] compatibleWithTraitCollection:nil];
		[self addSubview:iconView];
	}
	return self;
}

- (instancetype)initWithSpecifier:(id)specifier {
	UITableViewCellStyle style = UITableViewCellStyleDefault;
	return [self initWithStyle:style reuseIdentifier:@"PHPrefsHeaderCell" specifier:specifier];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
	return 100;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat iconSize = CGRectGetHeight(self.bounds) / 2.5;
	CGFloat padding = 15;
	CGFloat xBorderPoint = CGRectGetWidth(self.bounds) / 2.9;
	iconView.frame = CGRectMake(xBorderPoint - iconSize, CGRectGetMidY(self.bounds) - iconSize/2, iconSize, iconSize);
	titleLabel.frame = CGRectMake(xBorderPoint + padding, 0, CGRectGetWidth(self.bounds) - (xBorderPoint + padding), CGRectGetHeight(self.bounds));
}

- (void)dealloc {
	[titleLabel release];
	[iconView release];
	[super dealloc];
}

// Fix for iPad alignment issue.  
- (void)setFrame:(CGRect)frame {
	frame.origin.x = 0;
	[super setFrame:frame];
}

@end