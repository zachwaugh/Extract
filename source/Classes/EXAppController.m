//
//  EXAppController.m
//  Extract
//
//  Created by Zach Waugh on 8/7/09.
//  Copyright 2009 zachwaugh.com. All rights reserved.
//

#import "EXAppController.h"

#define WINDOW_TOOLBAR_HEIGHT 23

NSString * const EXKeepWindowOnTop = @"KeepWindowOnTop"; 

// Private methods
@interface EXAppController ()

- (void)loadHTMLString:(NSString *)htmlString;
- (void)logSource;

@end


@implementation EXAppController

@synthesize cache, queue, background, hasWebViewFinishedLoading;


#pragma mark -
#pragma mark Application Delegate methods

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
	[appleEventManager setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}


- (void)awakeFromNib
{
	self.hasWebViewFinishedLoading = NO;
	[window setBackgroundColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.75]];
	[window setOpaque:NO];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:EXKeepWindowOnTop])
	{
		[window setLevel:NSFloatingWindowLevel];
		[keepWindowOnTop setState:NSOnState];
	}
	
	[webView setDrawsBackground:NO];
	[webView setFrameLoadDelegate:self];
	[[[webView mainFrame] frameView] setAllowsScrolling:NO];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"]]]];
}


- (void)dealloc
{
	[[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
	self.cache = nil;
	self.background = nil;
	self.queue = nil;
	
	[super dealloc];
}


#pragma mark -
#pragma mark Window handling/delegate methods

// Make sure app quits after window is closed
- (void)windowWillClose:(NSNotification *)notification
{
	[[NSApplication sharedApplication] terminate:nil];
}


- (void)toggleKeepOnTop:(id)sender
{
	if ([sender state] == NSOnState)
	{
		[window setLevel:NSNormalWindowLevel];
		[sender setState:NSOffState];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:EXKeepWindowOnTop];
	}
	else
	{
		[window setLevel:NSFloatingWindowLevel];
		[sender setState:NSOnState];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:EXKeepWindowOnTop];
	}
}


#pragma mark  -

// Allow getting original embed code back out of app
- (void)copy:(id)sender
{
	[[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
	[[NSPasteboard generalPasteboard] setString:self.cache forType:NSStringPboardType];
}


// Handle pasting embed code
- (void)paste:(id)sender
{
	// Get string from pasteboard and trim whitespace
	NSString *html = [[[NSPasteboard generalPasteboard] stringForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	// Cache pasted embed code
	self.cache = html;
	
	[self loadHTMLString:html];
}


// Parse HTML chunk and load into webview
- (void)loadHTMLString:(NSString *)htmlString
{
	// Queue HTML to be loaded later if web view hasn't finished loading
	if (!self.hasWebViewFinishedLoading)
	{
		self.queue = htmlString;
		return;
	}
	
	DOMDocument *document = [[webView mainFrame] DOMDocument];
	
	// Save reference to extract div
	DOMHTMLElement *body = [document body];
	body.innerHTML = @"";
	
	DOMHTMLDivElement *container = (DOMHTMLDivElement *)[document createElement:@"div"];
	container.innerHTML = htmlString;
	
	// Simple check of input, make sure it's not empty and the first node isn't a text node
	if ([[container childNodes] length] > 0 && [[container firstChild] nodeType] == DOM_ELEMENT_NODE)
	{
		int height, width;
		
		// Try to get width and height directly off element attributes
		width = [[(DOMElement *)[container firstChild] getAttribute:@"width"] intValue];
		height = [[(DOMElement *)[container firstChild] getAttribute:@"height"] intValue];

		// Probably invalid dimensions - set to reasonable defaults
		if (width <= 10 && height <= 10)
		{
			width = 250;
			height = 250;
		}
		
		// Change all embed elements to have a black background - looks better while loading instead of flash of white
		DOMNodeList *embeds = [container getElementsByTagName:@"embed"];
		for (int i = 0; i < [embeds length]; i++)
		{
			[(DOMElement *)[embeds item:i] setAttribute:@"bgcolor" value:@"#000000"];
		}
		
		// Resize window to just fit embed
		[self.background setHidden:YES];
		NSRect windowFrame = [window frame];
		NSRect rect = NSMakeRect(windowFrame.origin.x - ((width - windowFrame.size.width) / 2), windowFrame.origin.y - ((height - windowFrame.size.height) / 2), width, height + WINDOW_TOOLBAR_HEIGHT);
		[window setFrame:rect display:YES animate:YES];
		
		[body appendChild:container];
	}
	else
	{
		// Invalid HTML - alert error and clear body
		[self.background setHidden:NO];
		body.innerHTML = @"";
		NSAlert *alert = [NSAlert alertWithMessageText:@"Invalid HTML:" defaultButton:@"ok" alternateButton:nil otherButton:nil informativeTextWithFormat:self.cache];
		[alert runModal];
	}
}


// For debugging, output entire HTML doc
- (void)logSource
{
	NSLog(@"%@", [(DOMHTMLElement *)[[[webView mainFrame] DOMDocument] documentElement] outerHTML]);
}


#pragma mark  -
#pragma mark  Apple Event Handling

// Handle a URL sent to app via extract:// call
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
	NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSString *html = [[url stringByReplacingCharactersInRange:NSMakeRange(0, 10) withString:@""] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	self.cache = html;
	
	[self loadHTMLString:html];
}


#pragma mark -
#pragma mark Webview delegate methods

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	self.hasWebViewFinishedLoading = YES;
	
	if (self.queue)
	{
		[self loadHTMLString:self.queue];
		self.queue = nil;
	}
}

@end
