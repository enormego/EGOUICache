//
//  EGOUICache.m
//  EGOUICache
//
//  Created by Shaun Harrison on 12/29/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOUICache.h"
#import "EGOCache.h"

static NSTimeInterval _cacheTimeoutInterval = 604800;

UIImage* EGOUICachedDrawing(id target, SEL selector, CGRect rect, NSString* salt) {
	NSString* key = @"EGOUI-";
	key = [key stringByAppendingFormat:@"%@-", NSStringFromClass([target class])];
	key = [key stringByAppendingFormat:@"%@-", NSStringFromSelector(selector)];
	key = [key stringByAppendingFormat:@"%.2fx%.2f-", rect.size.width, rect.size.height];
	key = [key stringByAppendingString:salt];
	key = [key stringByAppendingString:@".png"];

	UIImage* image = nil;
	
	if((image = [[EGOCache currentCache] imageForKey:key])) {
		return image;
	} else {
		CGRect adjustedRect = rect;
		adjustedRect.origin = CGPointMake(0.0f,0.0f);
		
		CGContextRef imageContext = CGBitmapContextCreate(NULL/*data - pass NULL to let CG allocate the memory*/, 
														  adjustedRect.size.width,  
														  adjustedRect.size.height, 
														  8 /*bitsPerComponent*/, 
														  0 /*bytesPerRow - CG will calculate it for you if it's allocating the data.  This might get padded out a bit for better alignment*/, 
														  CGColorGetColorSpace([UIColor redColor].CGColor), 
														  kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
		CGContextConcatCTM(imageContext, CGAffineTransformMake(1, 0, 0, -1, 0, rect.size.height));
		UIGraphicsPushContext(imageContext);
		
		[[UIColor clearColor] set];
		CGContextFillRect(UIGraphicsGetCurrentContext(), adjustedRect);
		
		NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:selector]];
		[invocation setSelector:selector];
		[invocation setArgument:&adjustedRect atIndex:2];
		[invocation invokeWithTarget:target];
		
		if(!_cancelCache) {
			CGImageRef cgImage = CGBitmapContextCreateImage(imageContext);
			UIGraphicsPopContext();
			CGContextRelease(imageContext);
			
			image = [UIImage imageWithCGImage:cgImage];
			CGImageRelease(cgImage);
			
			[[EGOCache currentCache] setImage:image forKey:key withTimeoutInterval:_cacheTimeoutInterval];
			return image;
		} else {
			_cancelCache = NO;
			return nil;
		}
	}
}

void EGOUICacheCancel() {
	_cancelCache = YES;
}

void EGOUICacheSetCacheTimeoutInterval(NSTimeInterval cacheTimeoutInterval) {
	_cacheTimeoutInterval = cacheTimeoutInterval;
}

void EGOUICacheSetCacheTimeoutOneYear() {
	EGOUICacheSetCacheTimeoutInterval(31556926);
}

void EGOUICacheSetCacheTimeoutOneMonth() {
	EGOUICacheSetCacheTimeoutInterval(2629743.83);
}

void EGOUICacheSetCacheTimeoutOneWeek() {
	EGOUICacheSetCacheTimeoutInterval(604800);
}

void EGOUICacheSetCacheTimeoutOneDay() {
	EGOUICacheSetCacheTimeoutInterval(86400);
}

void EGOUICacheSetCacheTimeoutOneHour() {
	EGOUICacheSetCacheTimeoutInterval(3600);
}
