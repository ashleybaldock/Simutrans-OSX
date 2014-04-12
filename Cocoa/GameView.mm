/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
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
- (void)flagsChanged:(NSEvent *)theEvent {
    [eventqueue enqueue:[theEvent copy]];
}



- (void)scrollWheel:(NSEvent *)theEvent {
	// Only trigger scrollwheel events if they come from a non-touch source
	Boolean Touchpad = true;
	
	if (Touchpad) {
		// Process as touch event
		NSEvent* touchEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL data1:[theEvent deltaX] data2:[theEvent deltaY]];
		[eventqueue enqueue:[touchEvent copy]];

/*	if ([theEvent deltaX] > 0) {
		NSEvent* touchEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_RIGHT data1:abs([theEvent deltaX]) data2:0];
		[eventqueue enqueue:[touchEvent copy]];
	} else if ([theEvent deltaX] < 0) {
		NSEvent* touchEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_LEFT data1:abs([theEvent deltaX]) data2:0];
		[eventqueue enqueue:[touchEvent copy]];
	}
	
	if ([theEvent deltaY] < 0) {
		NSEvent* touchEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_UP data1:abs([theEvent deltaY]) data2:0];
		[eventqueue enqueue:[touchEvent copy]];
	} else if ([theEvent deltaY] > 0) {
		NSEvent* touchEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_DOWN data1:abs([theEvent deltaY]) data2:0];
		[eventqueue enqueue:[touchEvent copy]];
	}*/
	} else {
		// Process as scrollwheel event
		[eventqueue enqueue:[theEvent copy]];
	}
}

- (void)viewDidMoveToWindow {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResized:) name:NSWindowDidResizeNotification object:[self window]];
    
}


- (void)rotateWithEvent:(NSEvent *)event {
	NSLog(@"Rotation in degree is %f", event.rotation);
	if (event.rotation > 45) {
		// Counterclockwise
		NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_ROTATE_LEFT data1:1 data2:0];
		[eventqueue enqueue:[theEvent copy]];
	} else if (event.rotation < 45) {
		// Clockwise
		NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_ROTATE_RIGHT data1:1 data2:0];
		[eventqueue enqueue:[theEvent copy]];
	}
}

- (void)magnifyWithEvent:(NSEvent *)event {
	NSLog(@"Magnification value is %f", [event magnification]);
	//NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_RIGHT data1:abs(xsteps) data2:0];
	//[eventqueue enqueue:[theEvent copy]];

}



/*- (void)cancelTracking {
	touchesDisplacementFromTouchOrigin[0] = NSZeroSize;
	touchesDisplacementFromTouchOrigin[1] = NSZeroSize;
	lastTouches[0] = currentTouches[0] = nil;
	lastTouches[1] = currentTouches[1] = nil;
	lastTime = currentTime = 0;
	
	_tracking = NO;
}

- (void)touchesBeganWithEvent:(NSEvent *)event
{
	[self cancelTracking];

    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
	
    if (touches.count == 2) {		
        NSArray *array = [touches allObjects];
        lastTouches[0] = currentTouches[0] = [[array objectAtIndex:0] copy];
        lastTouches[1] = currentTouches[1] = [[array objectAtIndex:1] copy];
		lastTime = currentTime = [event timestamp];
		_tracking = YES;
    }
}

- (void)touchesCancelledWithEvent:(NSEvent *) __unused event
{
	[self cancelTracking];
}

- (void)touchesEndedWithEvent:(NSEvent *) __unused event
{
	[self cancelTracking];
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
	
    if (touches.count == 2 && lastTouches[0]) {
        NSArray *array = [touches allObjects];
		
        NSTouch *touch;
		
        touch = [array objectAtIndex:0];
        if ([touch.identity isEqual:lastTouches[0].identity]) {
            currentTouches[0] = [touch copy];
        } else {
            currentTouches[1] = [touch copy];
        }
		
        touch = [array objectAtIndex:1];
        if ([touch.identity isEqual:lastTouches[0].identity]) {
            currentTouches[0] = [touch copy];
        } else {
            currentTouches[1] = [touch copy];
        }
		
		currentTime = [event timestamp];
		
		if (_tracking) {
			NSSize deviceSize = currentTouches[0].deviceSize;

			NSSize delta[2];
			delta[0].width = currentTouches[0].normalizedPosition.x - lastTouches[0].normalizedPosition.x;
			delta[1].width = currentTouches[1].normalizedPosition.x - lastTouches[1].normalizedPosition.x;
			delta[0].height = currentTouches[0].normalizedPosition.y - lastTouches[0].normalizedPosition.y;
			delta[1].height = currentTouches[1].normalizedPosition.y - lastTouches[1].normalizedPosition.y;
			
			// Add to total displacement
			touchesDisplacementFromTouchOrigin[0].width += delta[0].width;
			touchesDisplacementFromTouchOrigin[0].height += delta[0].height;
			touchesDisplacementFromTouchOrigin[1].width += delta[1].width;
			touchesDisplacementFromTouchOrigin[1].height += delta[1].height;
			
			int x0 = 0;
			int y0 = 0;
			int x1 = 0;
			int y1 = 0;
			
			NSSize velocity[2];
			velocity[0] = NSZeroSize;
			velocity[1] = NSZeroSize;
			
			NSTimeInterval deltaTime = currentTime - lastTime;
			
			// Minimum velocity is 1
			velocity[0].width = max(fabs(delta[0].width) / deltaTime, 1);
			velocity[0].height = max(fabs(delta[0].height) / deltaTime, 1);
			velocity[1].width = max(fabs(delta[1].width) / deltaTime, 1);
			velocity[1].height = max(fabs(delta[1].height) / deltaTime, 1);

			// Is either touch above threshold?
			
			// Scroll speed is related to:
			//  device size (larger reduces overall)
			//  velocity (faster increases speed)
			//  displacement size
			if (fabs(touchesDisplacementFromTouchOrigin[0].width) > threshold) {
				x0 = (int) (touchesDisplacementFromTouchOrigin[0].width / step);
				touchesDisplacementFromTouchOrigin[0].width -= x0 * step;
			}
			if (fabs(touchesDisplacementFromTouchOrigin[0].height) > threshold) {
				y0 = (int) (touchesDisplacementFromTouchOrigin[0].height / step);
				touchesDisplacementFromTouchOrigin[0].height -= y0 * step;
			}
			if (fabs(touchesDisplacementFromTouchOrigin[1].width) > threshold) {
				x1 = (int) (touchesDisplacementFromTouchOrigin[1].width / step);
				touchesDisplacementFromTouchOrigin[1].width -= x1 * step;
			}
			if (fabs(touchesDisplacementFromTouchOrigin[1].height) > threshold) {
				y1 = (int) (touchesDisplacementFromTouchOrigin[1].height / step);
				touchesDisplacementFromTouchOrigin[1].height -= y1 * step;
			}
			
			int xsteps = (int) ((x0 + x1) * (velocity[0].width + velocity[1].width));
			int ysteps = (int) ((y0 + y1) * (velocity[0].height + velocity[1].height));
			
			if (xsteps != 0 || ysteps != 0) {
				NSLog(@"vx0: %f, vy0: %f, vx1: %f, vy1: %f - xsteps: %d, ysteps: %d", velocity[0].width, velocity[0].height, velocity[1].width, velocity[1].height, xsteps, ysteps);
			}
			
			if (xsteps > 0) {
				NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_RIGHT data1:abs(xsteps) data2:0];
				[eventqueue enqueue:[theEvent copy]];
			} else if (xsteps < 0) {
				NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_LEFT data1:abs(xsteps) data2:0];
				[eventqueue enqueue:[theEvent copy]];
			}
			
			if (ysteps > 0) {
				NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_UP data1:abs(ysteps) data2:0];
				[eventqueue enqueue:[theEvent copy]];
			} else if (ysteps < 0) {
				NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:SIM_TOUCH_SCROLL_DOWN data1:abs(ysteps) data2:0];
				[eventqueue enqueue:[theEvent copy]];
			}
			
			// Swap ready for next event
			lastTouches[0] = currentTouches[0];
			lastTouches[1] = currentTouches[1];
			lastTime = currentTime;
		}
	}
}*/


/*- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}*/

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
- (void)game_trigger_quit
{
    NSLog(@"Game quit event triggered");
    // Send quit event to the game thread
    // When game quits, it will send back a message indicating this (via dr_os_quit())
    if (game_quit == 0) {
        game_quit = 1;
		// Don't terminate, just close parent window
        //[NSApp terminate:nil];
		[[self window] close];
    } else {
        game_quit = 1;
        NSLog(@"Game thread has quit in response to request from application, permitting termination");
		[[self window] close];
        [NSApp replyToApplicationShouldTerminate:YES];
    }
}

/*
 * Asks the game thread to quit
 * It will respond via dr_os_quit()
 */
- (void)trigger_quit
{
    NSLog(@"Quit event triggered");
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
	
	// Touch stuff
	//[self setAcceptsTouchEvents:YES];
	_tracking = NO;
	threshold = 0.05;
	step = 0.01;
	
    theGameView = self;
    screenbuf_lock = [[NSConditionLock alloc] initWithCondition:0];
    game_quit = 0;

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
		
	// Location of pakset
	// Generate from sandbox location + pakset base name
	//[argvs addObject:@"-objects"];
	//[argvs addObject:@"pak/"];

	[argvs addObject:@"-debug"];
	[argvs addObject:@"3"];

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
