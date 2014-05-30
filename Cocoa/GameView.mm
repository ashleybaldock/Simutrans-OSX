/*
 * Copyright (c) 2011-2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import "GameView.h"
#import "STQueue.h"
#import "AppDelegate.h"
#include "../simsys.h"

// This is all set up in simsys_q.mm
#ifndef COLOUR_DEPTH
#define COLOUR_DEPTH 16
#endif

#if COLOUR_DEPTH == 8
#	error unsupported COLOUR_DEPTH
#elif COLOUR_DEPTH == 16
typedef unsigned short PIXVAL;
#else
#	error unknown COLOUR_DEPTH
#endif

extern int width;
extern int height;
extern PIXVAL* screenbuf;

extern int sysmain(int, char**);

GameView* theGameView;

// Queue to hold all the events which the game should take notice of
STQueue* eventqueue = [[STQueue alloc] init];

/*
 TODO - Use double-buffering here
 Have two screen buffers, designed to allow game to update more slowly than the Cocoa thread (e.g. for resizing operations?)
 Need to handle screen buffer resizing elegantly too
 */


@implementation GameView


// We want to accept keyboard events
- (BOOL)acceptsFirstResponder
{
    return YES;
}


// Event handling

- (void)mouseDown:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

// Always preceeded by a keyDown
- (void)keyUp:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}

// Modifier key flags have changed (e.g. ctrl pressed)
- (void)flagsChanged:(NSEvent *)theEvent
{
    [eventqueue enqueue:[theEvent copy]];
}


- (void)scrollWheel:(NSEvent *)theEvent
{
	[eventqueue enqueue:[theEvent copy]];
}

- (void)viewDidMoveToWindow
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResized:) name:NSWindowDidResizeNotification object:[self window]];
}

- (void)windowResized:(NSNotification *) __unused notification
{    
    NSSize size = self.frame.size;
    
    NSLog(@"window width = %f, window height = %f", size.width, size.height);
    
    NSEvent *theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:0 subtype:1 data1:size.width data2:size.height];
    
    [eventqueue enqueueAtFront:[theEvent copy]];
}

- (void)viewDidEndLiveResize
{
    NSEvent *theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:0 subtype:1 data1:self.frame.size.width data2:self.frame.size.height];
        
    [eventqueue enqueue:[theEvent copy]];
}

/*
 * Handle synchronisation between the game thread quitting and the app quitting
 */
- (void)gameThreadRequestQuit
{
    NSLog(@"Game thread has requested quit");
	GameThreadHasQuit = YES;
	if (UIHasAskedGameToQuit)
	{
		NSLog(@"Game thread has quit in response to request from application, permitting termination");
        [NSApp replyToApplicationShouldTerminate:YES];
	}
	[[self window] close];
}

/*
 * Asks the game thread to quit
 * It will respond via dr_os_quit()
 */
- (void)sendQuitEventToGameThread
{
    NSLog(@"Sending quit event to game thread");
	UIHasAskedGameToQuit = YES;
    // Send quit event to the game thread
    // When game quits, it will send back a message (via dr_os_quit())
    NSEvent *theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0 context:0 subtype:2 data1:0 data2:0];
        
    [eventqueue enqueueAtFront:[theEvent copy]];
}

- (void)awakeFromNib
{
    NSLog(@"awakeFromNib for GameView");
    // Initialization code here.
    
    [[self window] setAcceptsMouseMovedEvents:YES];
	
	// Necessary to make this work on 10.8
	[self setWantsLayer:NO];
	
    theGameView = self;
    screenbuf_lock = [[NSConditionLock alloc] initWithCondition:0];
	UIHasAskedGameToQuit = NO;
	GameThreadHasQuit = NO;

	NSLog(@"representedObject: content - attributeKeys: %@", [[representedObject content] attributeKeys]);
	NSLog(@"representedObject: content - exposedBindings: %@", [[representedObject content] exposedBindings]);
	
    // Spawn main game thread
    [NSThread detachNewThreadSelector:@selector(GameThreadMainRoutine) toTarget:self withObject:nil];
}


- (void)GameThreadMainRoutine
{
    NSLog(@"Thread spawned...");
	
	NSMutableArray* argvs = [[NSMutableArray alloc] init];
	
	[argvs addObject:[NSString stringWithString:[[[NSProcessInfo processInfo] arguments] objectAtIndex:0]]];

#ifdef DEBUG
	[argvs addObject:@"-debug"];
	[argvs addObject:@"3"];
#endif

	[argvs addObject:@"-screensize"];
	[argvs addObject:[NSString stringWithFormat:@"%dx%d", (int)self.frame.size.width, (int)self.frame.size.height]];

	int g_argc = [argvs count];
	char* g_argv[32];
	
	for (int i = 0; i < g_argc; i++) {
		g_argv[i] = strdup([[argvs objectAtIndex:i] UTF8String]);
	}
	
	// Hope here that the game doesn't alter any of the argv pointers...
    sysmain(g_argc, g_argv);
    
	for (int i = 0; i < g_argc; i++) {
		free(g_argv[i]);				// This doesn't work!!
	}
}

- (void)screenshot
{
	// Find first unused screenshot filename
	NSString* screenshotFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Simutrans/screenshot", NSHomeDirectory()];

	int number = 0;
	NSString* screenshotPath;
	do {
		screenshotPath = [NSString stringWithFormat:@"%@/simscr%03d.png", screenshotFolder, number];
		number++;
	} while ([[NSFileManager defaultManager] fileExistsAtPath:screenshotPath]);
	
	NSBitmapImageRep* rep = [self bitmapImageRepForCachingDisplayInRect:[self bounds]];
	[self cacheDisplayInRect:[self bounds] toBitmapImageRep:rep];
	NSData *data = [rep representationUsingType: NSPNGFileType properties: nil];
	[data writeToFile: screenshotPath atomically: NO];
}

- (void)drawRect:(NSRect) __unused dirtyRect
{
	// Create image from raw data wrapped in provider
	if (width > 0 && height > 1)
	{
		// Lock screenbuf so main game thread cannot modify it
		[screenbuf_lock lockWhenCondition:0];

		NSGraphicsContext* nsGraphicsContext = [NSGraphicsContext currentContext];
		CGContextRef myContext = (CGContextRef) [nsGraphicsContext graphicsPort];

		// Create a data provider to permit access to the raw pixel array
		CGDataProviderRef screenbuf_provider = CGDataProviderCreateWithData(screenbuf, screenbuf, width*height*2, nil);
		
		CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
		

		
		CGImageRef img = CGImageCreate(width,                      // width
									   height,                     // height
									   5,                          // bitsPerComponent
									   16,                         // bitsPerPixel
									   width*2,                    // bytesPerRow
									   space,                      // colorspace
									   kCGBitmapByteOrder16Little|kCGImageAlphaNoneSkipFirst,  // bitmapInfo
									   screenbuf_provider,                   // CGDataProvider
									   NULL,                       // decode array
									   NO,                         // shouldInterpolate
									   kCGRenderingIntentDefault); // intent
		
		CGContextDrawImage(myContext, CGRectMake(0, self.frame.size.height - height, width, height), img);
		
		// Clean up
		CGImageRelease(img);
		CGColorSpaceRelease(space);
		// Release provider to permit game to render to memory again
		CGDataProviderRelease(nil);
		[screenbuf_lock unlockWithCondition:0];
	}
}


- (IBAction)takeScreenshot:(id) __unused sender
{
	[self screenshot];
}

- (IBAction)openBundle:(id) __unused sender
{
	[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/Contents/MacOS/", [[NSBundle mainBundle] bundlePath]]];

}

- (IBAction)openUserFolder:(id) __unused sender
{
	[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/Library/Application Support/Simutrans", NSHomeDirectory()]];
}

- (BOOL)isOpaque
{
    return NO;
}

// This may improve performance
// http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CocoaViewsGuide/Optimizing/Optimizing.html#//apple_ref/doc/uid/TP40002978-CH11-SW1
/*- (BOOL)wantsDefaultClipping {
    return NO;
}*/


@end
