// Here is the interface of the ColorBadges object.
@interface ColorBadges : NSObject
+ (instancetype)sharedInstance;
+ (BOOL)isDarkColor:(int)color;

// Returns RGB ints. i.e. 0xRRGGBB.
- (int)colorForImage:(UIImage *)image;
- (int)colorForIcon:(id)icon; // Must be an SBIcon *
@end

// You can use the API like the following. Note that you may need to dlopen ColorBadges first.
// @implementation YourObject
// - (void)configureMyBadge:(id)badge forIcon:(id)icon {
//   Class cb = %c(ColorBadges);
//   if (cb) {
//     badge.tintColor = [[cb sharedInstance] colorForIcon:icon];
//   } else {
//     badge.tintColor = [UIColor redColor]; // Default color
//   }
// }
// @end