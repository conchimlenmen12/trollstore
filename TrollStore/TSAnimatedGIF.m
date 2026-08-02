#import "TSAnimatedGIF.h"
#import <ImageIO/ImageIO.h>

UIImage* animatedGIFNamed(NSString* name)
{
	NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:@"gif"];
	NSData* data = path ? [NSData dataWithContentsOfFile:path] : nil;
	if(!data) return nil;

	CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	if(!source) return nil;

	size_t frameCount = CGImageSourceGetCount(source);
	NSMutableArray<UIImage*>* frames = [NSMutableArray new];
	NSTimeInterval totalDuration = 0;

	for(size_t i = 0; i < frameCount; i++)
	{
		CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, i, NULL);
		if(!cgImage) continue;

		NSDictionary* properties = (__bridge_transfer NSDictionary*)CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
		NSDictionary* gifProperties = properties[(__bridge NSString*)kCGImagePropertyGIFDictionary];
		NSNumber* delayTime = gifProperties[(__bridge NSString*)kCGImagePropertyGIFUnclampedDelayTime] ?: gifProperties[(__bridge NSString*)kCGImagePropertyGIFDelayTime];
		totalDuration += delayTime ? delayTime.doubleValue : 0.1;

		[frames addObject:[UIImage imageWithCGImage:cgImage]];
		CGImageRelease(cgImage);
	}
	CFRelease(source);

	if(frames.count == 0) return nil;
	return [UIImage animatedImageWithImages:frames duration:totalDuration];
}

UIBarButtonItem* animatedGIFBarButtonItem(NSString* name, CGFloat size)
{
	UIImage* image = animatedGIFNamed(name);
	if(!image) return nil;

	UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.frame = CGRectMake(0, 0, size, size);

	return [[UIBarButtonItem alloc] initWithCustomView:imageView];
}
