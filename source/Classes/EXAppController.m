//
//  EXAppController.m
//  Extract
//
//  Created by Zach Waugh on 8/7/09.
//  Copyright 2009 zachwaugh.com. All rights reserved.
//

#import "EXAppController.h"

// Private methods
@interface EXAppController ()

- (void)loadEmbed:(NSString *)embedCode;
- (void)logSource;

@end


@implementation EXAppController

@synthesize originalEmbed, background;

- (void)awakeFromNib
{
	// Allow spaces to work
	//[window setFloatingPanel:NO];
	[webView setDrawsBackground:NO];
	
	[[[webView mainFrame] frameView] setAllowsScrolling:NO];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]]]];
}

- (void)dealloc
{
	self.originalEmbed = nil;
	self.background = nil;
	
	[super dealloc];
}

// Make sure app quits after panel is closed
- (void)windowWillClose:(NSNotification *)notification
{
	[[NSApplication sharedApplication] terminate:nil];
}

// Allow getting original embed code back out of app
- (void)copy:(id)sender
{
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[[NSPasteboard generalPasteboard] setString:self.originalEmbed forType:NSStringPboardType];
}

// Handle pasting embed code
- (void)paste:(id)sender
{
	NSString *content = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
	
	// Cache pasted embed code
	self.originalEmbed = content;
	
	[self loadEmbed:content];
}

- (void)loadEmbed:(NSString *)embedCode
{	
	DOMHTMLElement *extract = (DOMHTMLElement *)[[[webView mainFrame] DOMDocument] getElementById:@"_extract"];

	int height, width;
	
	extract.innerHTML = embedCode;
	DOMElement *video;
	
	// First look for <object> element
	if ([[extract getElementsByTagName:@"object"] length] > 0)
	{
		video = (DOMElement *)[[extract getElementsByTagName:@"object"] item:0];
		width = [[video getAttribute:@"width"] intValue];
		height = [[video getAttribute:@"height"] intValue] + 20;
		
		// Check for nested <embed> element
		if ([[video getElementsByTagName:@"embed"] length] > 0)
		{
			DOMHTMLElement *embed = (DOMHTMLElement *)[[video getElementsByTagName:@"embed"] item:0];
			[embed setAttribute:@"id" value:@"video"];
			[embed setAttribute:@"bgcolor" value:@"#000000"];
			[embed setAttribute:@"width" value:@"100%"];
			[embed setAttribute:@"height" value:@"100%"];
		}
	}
	else if ([[extract getElementsByTagName:@"embed"] length] > 0)
	{
		video = (DOMElement *)[[extract getElementsByTagName:@"embed"] item:0];
		width = [[video getAttribute:@"width"] intValue];
		height = [[video getAttribute:@"height"] intValue] + 20;
	}
	else
	{
		// Invalid embed code - alert error
		extract.innerHTML = @"";
		NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid embed code:" defaultButton:@"ok" alternateButton:nil otherButton:nil informativeTextWithFormat:self.originalEmbed];
		[alert runModal];
		
		return;
	}

	// Update video attributes
	[video setAttribute:@"bgcolor" value:@"#000000"];
	[video setAttribute:@"width" value:@"100%"];
	[video setAttribute:@"height" value:@"100%"];
	
	// Resize window to just fit embed
	[self.background setHidden:YES];
	NSRect windowFrame = [window frame];
	NSRect rect = NSMakeRect(windowFrame.origin.x - ((width - windowFrame.size.width) / 2), windowFrame.origin.y - ((height - windowFrame.size.height) / 2), width, height);
	[window setFrame:rect display:YES animate:YES];
	//[self logSource];
}

- (void)logSource
{
	NSLog(@"%@", [(DOMHTMLElement *)[[[webView mainFrame] DOMDocument] documentElement] outerHTML]);
}

@end
