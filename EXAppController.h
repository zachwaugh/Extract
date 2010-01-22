//
//  EXAppController.h
//  Extract
//
//  Created by Zach Waugh on 8/7/09.
//  Copyright 2009 zachwaugh.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface EXAppController : NSObject
{
	IBOutlet NSPanel *window;
	IBOutlet WebView *webView;
	IBOutlet NSImageView *background;
	
	NSString *originalEmbed;
}

@property (retain) NSString *originalEmbed;
@property (retain) NSImageView *background;

- (void)paste:(id)sender;
- (void)copy:(id)sender;
- (void)loadEmbed:(NSString *)embedCode;
- (void)callJavaScript:(NSString *)script;
- (void)play:(id)sender;
- (void)pause:(id)sender;
- (void)logSource;
@end
