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
	IBOutlet NSWindow *window;
	IBOutlet WebView *webView;
	IBOutlet NSImageView *background;
	IBOutlet NSMenuItem *keepWindowOnTop;
	
	NSString *cache;
}

@property (retain) NSString *cache;
@property (retain) NSImageView *background;

- (void)paste:(id)sender;
- (void)copy:(id)sender;
- (void)toggleKeepOnTop:(id)sender;

@end
