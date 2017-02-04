#import <Preferences/PSSwitchTableCell.h>

//Mostly borrowed from FLASHSwitchTableCell
//Thanks David

@interface PHSubtitleSwitchTableCell : PSSwitchTableCell
@end

@implementation PHSubtitleSwitchTableCell

- (id)initWithStyle:(int)style reuseIdentifier:(id)identifier specifier:(id)specifier {
return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
}

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	NSString *sublabel = [specifier propertyForKey:@"sublabel"];
	if (sublabel) {
		self.detailTextLabel.text = [sublabel description];
		self.detailTextLabel.textColor = [UIColor grayColor];
	}
}

@end