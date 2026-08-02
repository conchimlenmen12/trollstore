#import <UIKit/UIKit.h>

// Draws the "HAHA" sticker face (blue circle, white eyes/smile, cyan
// "HAHA" text above) at the given square size.
extern UIImage* hahaStickerImage(CGFloat size);

// Wraps hahaStickerImage() in a UIBarButtonItem (square custom UIImageView),
// ready to drop into a navigationItem's left/right bar button items.
extern UIBarButtonItem* hahaStickerBarButtonItem(CGFloat size);
