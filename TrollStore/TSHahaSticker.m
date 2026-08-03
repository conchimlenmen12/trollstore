#import "TSHahaSticker.h"
#import "TSUtil.h"
#import <TSPresentationDelegate.h>

#ifndef TROLLSTORE_LITE
// Long-pressing the haha sticker for 3s offers a quick "uninstall CheatTrollStore but
// keep installed apps" escape hatch, mirroring Settings' "Uninstall CheatTrollStore,
// Preserve Apps" action (Shared/TSListControllerShared.m) without navigating there.
@interface TSHahaStickerLongPressHandler : NSObject
+ (instancetype)shared;
- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer;
@end

@implementation TSHahaStickerLongPressHandler

+ (instancetype)shared
{
	static TSHahaStickerLongPressHandler* instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [TSHahaStickerLongPressHandler new];
	});
	return instance;
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)recognizer
{
	if(recognizer.state != UIGestureRecognizerStateBegan) return;

	UIAlertController* confirmAlert = [UIAlertController alertControllerWithTitle:@"Uninstall CheatTrollStore"
		message:@"Gỡ tạm CheatTrollStore khỏi máy nhưng vẫn giữ nguyên các app đã cài. Muốn dùng lại thì mở app đã dùng để cài CheatTrollStore ban đầu (TrollInstallerX) và cài lại."
		preferredStyle:UIAlertControllerStyleAlert];

	[confirmAlert addAction:[UIAlertAction actionWithTitle:@"Huỷ" style:UIAlertActionStyleCancel handler:nil]];
	[confirmAlert addAction:[UIAlertAction actionWithTitle:@"Uninstall CheatTrollStore, Preserve Apps" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		NSMutableArray* args = [@[@"uninstall-trollstore", @"preserve-apps"] mutableCopy];
		spawnRoot(rootHelperPath(), args, nil, nil);
		exit(0);
	}]];

	[TSPresentationDelegate presentViewController:confirmAlert animated:YES completion:nil];
}

@end
#endif

UIImage* hahaStickerImage(CGFloat size)
{
	UIGraphicsImageRendererFormat* format = [UIGraphicsImageRendererFormat preferredFormat];
	format.opaque = NO;
	UIGraphicsImageRenderer* renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size) format:format];

	return [renderer imageWithActions:^(UIGraphicsImageRendererContext* rendererContext)
	{
		CGContextRef ctx = rendererContext.CGContext;
		CGFloat scale = size / 100.0;

		// face
		UIColor* faceColor = [UIColor colorWithRed:0.165 green:0.388 blue:0.788 alpha:1.0];
		CGContextSetFillColorWithColor(ctx, faceColor.CGColor);
		CGFloat faceRadius = 34 * scale;
		CGContextFillEllipseInRect(ctx, CGRectMake((50 * scale) - faceRadius, (52 * scale) - faceRadius, faceRadius * 2, faceRadius * 2));

		// eyes
		CGContextSetFillColorWithColor(ctx, UIColor.whiteColor.CGColor);
		CGFloat eyeRadius = 5.5 * scale;
		CGContextFillEllipseInRect(ctx, CGRectMake((38 * scale) - eyeRadius, (46 * scale) - eyeRadius, eyeRadius * 2, eyeRadius * 2));
		CGContextFillEllipseInRect(ctx, CGRectMake((62 * scale) - eyeRadius, (46 * scale) - eyeRadius, eyeRadius * 2, eyeRadius * 2));

		// smile
		CGContextSetStrokeColorWithColor(ctx, UIColor.whiteColor.CGColor);
		CGContextSetLineWidth(ctx, 4 * scale);
		CGContextSetLineCap(ctx, kCGLineCapRound);
		CGContextBeginPath(ctx);
		CGContextMoveToPoint(ctx, 32 * scale, 60 * scale);
		CGContextAddCurveToPoint(ctx, 38 * scale, 68 * scale, 62 * scale, 68 * scale, 68 * scale, 60 * scale);
		CGContextStrokePath(ctx);

		// "HAHA" text
		NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
		paragraphStyle.alignment = NSTextAlignmentCenter;
		NSDictionary* attrs = @{
			NSFontAttributeName: [UIFont boldSystemFontOfSize:16 * scale],
			NSForegroundColorAttributeName: [UIColor colorWithRed:0.498 green:0.902 blue:1.0 alpha:1.0],
			NSParagraphStyleAttributeName: paragraphStyle
		};
		NSString* text = @"HAHA";
		CGSize textSize = [text sizeWithAttributes:attrs];
		CGPoint textOrigin = CGPointMake((size - textSize.width) / 2.0, (2 * scale));
		[text drawAtPoint:textOrigin withAttributes:attrs];
	}];
}

UIBarButtonItem* hahaStickerBarButtonItem(CGFloat size)
{
	UIImage* image = hahaStickerImage(size);

	UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.frame = CGRectMake(0, 0, size, size);

#ifndef TROLLSTORE_LITE
	imageView.userInteractionEnabled = YES;
	UILongPressGestureRecognizer* longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:TSHahaStickerLongPressHandler.shared action:@selector(handleLongPress:)];
	longPress.minimumPressDuration = 3.0;
	[imageView addGestureRecognizer:longPress];
#endif

	return [[UIBarButtonItem alloc] initWithCustomView:imageView];
}
