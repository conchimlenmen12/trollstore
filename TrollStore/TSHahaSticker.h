#import <UIKit/UIKit.h>

// Draws the "HELLO" sticker face (blue circle, white eyes/smile, cyan
// "HELLO" text above) at the given square size.
extern UIImage* hahaStickerImage(CGFloat size);

// Draws the maintenance sticker face (yellow circle, worried brows/frown,
// amber "Bảo Trì" text above) at the given square size — shown on the
// welcome sheet when the server marks the app as under maintenance.
extern UIImage* maintenanceStickerImage(CGFloat size);

// Wraps hahaStickerImage() in a UIBarButtonItem (square custom UIImageView),
// ready to drop into a navigationItem's left/right bar button items.
extern UIBarButtonItem* hahaStickerBarButtonItem(CGFloat size);
