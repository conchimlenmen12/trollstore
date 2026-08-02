#import <UIKit/UIKit.h>

// Decodes every frame of a .gif resource bundled in the app and returns it as
// an animated UIImage (nil if the resource doesn't exist or isn't a GIF).
extern UIImage* animatedGIFNamed(NSString* name);

// Wraps animatedGIFNamed() in a UIBarButtonItem (square custom UIImageView),
// ready to drop into a navigationItem's left/right bar button items. Returns
// nil if the named resource couldn't be loaded.
extern UIBarButtonItem* animatedGIFBarButtonItem(NSString* name, CGFloat size);
