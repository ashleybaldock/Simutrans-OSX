/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import "GameView.h"
#import "STQueue.h"
#import "AppDelegate.h"

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
	// Only trigger scrollwheel events if they come from a non-touch source
	// TODO - need a more reliable way to do this!
	if (false && !_tracking) {
    	[eventqueue enqueue:[theEvent copy]];
	}
}

- (void)viewDidMoveToWindow
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowResized:) name:NSWindowDidResizeNotification object:[self window]];
    
}



- (void)cancelTracking {
	//if (self.endTrackingAction) [NSApp sendAction:self.endTrackingAction to:self.view from:self];
	// TODO send message to indicate that tracking has completed
	if (_tracking) {
		//NSLog(@"Tracking complete");
		//NSPoint dOrigin = [self deltaOrigin];
		NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:12 data1:0 data2:0];
		[eventqueue enqueue:[theEvent copy]];

		lastTouches[0] = nil;
		lastTouches[0] = nil;
		currentTouches[0] = nil;
		currentTouches[0] = nil;
		displacement = NSZeroSize;
	
		_tracking = NO;
	}
}

- (void)touchesBeganWithEvent:(NSEvent *)event
{
	//if (!self.isEnabled) return;
	
    NSSet *touches = [event touchesMatchingPhase:NSTouchPhaseTouching inView:self];
	
    if (touches.count == 2) {		
        NSArray *array = [touches allObjects];
		
        lastTouches[0] = [[array objectAtIndex:0] copy];
        lastTouches[1] = [[array objectAtIndex:1] copy];
        currentTouches[0] = lastTouches[0];
        currentTouches[1] = lastTouches[1];
		displacement = NSZeroSize;
		
    } else if (touches.count > 2) {
        // More than 2 touches. Only track 2.
		[self cancelTracking];
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
		
        /*if (!_tracking) {
			// Not already tracking, store starting location
            NSPoint dOrigin = [self deltaOrigin];
            NSSize  dSize = [self deltaSize];
            if (fabs(dOrigin.x) > _threshold ||
                fabs(dOrigin.y) > _threshold ||
                fabs(dSize.width) > _threshold ||
                fabs(dSize.height) > _threshold) {
                _tracking = YES;
				// TODO here send message that move has begun
				NSLog(@"Tracking begins");
            }
        } else {*/
		if (_tracking) {
			// Calculate difference since last call
			// Produce event + queue
			// Store new start position
			//NSPoint dOrigin = [self deltaOrigin];
            /*if (fabs(dOrigin.x) > _threshold ||
                fabs(dOrigin.y) > _threshold ||
                fabs(dSize.width) > _threshold ||
                fabs(dSize.height) > _threshold) {
                _tracking = YES;
				// TODO here send message that move is ongoing
				//NSLog(@"Tracking continues, dOrigin: (%f,%f), dSize: (%f,%f)", dOrigin.x, dOrigin.y, dSize.width, dSize.height);*/
			
			// Find change from last location
            NSSize dSize = [self deltaSize];
			// Add to total displacement
			displacement.width += dSize.width;
			displacement.height += dSize.height;
			
			// If this is above threshold for event, trigger
			if (fabs(displacement.width) > threshold || fabs(displacement.height) > threshold) {
				
				int w = (int) displacement.width;
				int h = (int) displacement.height;
				
				NSPoint fakePoint = NSMakePoint(w, h);
				NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:fakePoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:10 data1:0 data2:0];
				[eventqueue enqueue:[theEvent copy]];
				
				displacement.width -= w;
				displacement.height -= h;
			}
        } else {
			// Start of new touch event
			displacement = NSZeroSize;
			_tracking = YES;
			
			NSEvent* theEvent = [NSEvent otherEventWithType:NSApplicationDefined location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:[[self window] windowNumber] context:[[self window] graphicsContext] subtype:11 data1:0 data2:0];
			[eventqueue enqueue:[theEvent copy]];
		}
		
		// Swap ready for next event
        lastTouches[0] = currentTouches[0];
        lastTouches[1] = currentTouches[1];
    }
}


- (NSPoint)deltaOrigin {
    if (!(lastTouches[0] && lastTouches[1] &&
		  currentTouches[0] && currentTouches[1])) return NSZeroPoint;
	
    CGFloat x1 = MIN(lastTouches[0].normalizedPosition.x, lastTouches[1].normalizedPosition.x);
    CGFloat x2 = MAX(currentTouches[0].normalizedPosition.x, currentTouches[1].normalizedPosition.x);
    CGFloat y1 = MIN(lastTouches[0].normalizedPosition.y, lastTouches[1].normalizedPosition.y);
    CGFloat y2 = MAX(currentTouches[0].normalizedPosition.y, currentTouches[1].normalizedPosition.y);
	
    NSSize deviceSize = lastTouches[0].deviceSize;
    NSPoint delta;
    delta.x = (x2 - x1) * deviceSize.width;
    delta.y = (y2 - y1) * deviceSize.height;
	//NSLog(@"deviceSize, w: %f, h: %f", deviceSize.width, deviceSize.height);
    return delta;
}


// It's this code which doesn't work!!!
// Need a better way to measure scroll displacement
- (NSSize)deltaSize {
    if (!(lastTouches[0] && lastTouches[1] && currentTouches[0] && currentTouches[1])) return NSZeroSize;
	
    CGFloat x1,x2,y1,y2,width1,width2,height1,height2;    
    x1 = MIN(lastTouches[0].normalizedPosition.x, lastTouches[1].normalizedPosition.x);
    x2 = MAX(lastTouches[0].normalizedPosition.x, lastTouches[1].normalizedPosition.x);
    width1 = x2 - x1;
	
    y1 = MIN(lastTouches[0].normalizedPosition.y, lastTouches[1].normalizedPosition.y);
    y2 = MAX(lastTouches[0].normalizedPosition.y, lastTouches[1].normalizedPosition.y);
    height1 = y2 - y1;
	
    x1 = MIN(currentTouches[0].normalizedPosition.x, currentTouches[1].normalizedPosition.x);
    x2 = MAX(currentTouches[0].normalizedPosition.x, currentTouches[1].normalizedPosition.x);
    width2 = x2 - x1;
	
    y1 = MIN(currentTouches[0].normalizedPosition.y, currentTouches[1].normalizedPosition.y);
    y2 = MAX(currentTouches[0].normalizedPosition.y, currentTouches[1].normalizedPosition.y);
    height2 = y2 - y1;
	
    NSSize deviceSize = lastTouches[0].deviceSize;
    NSSize delta;
    delta.width = (width2 - width1) * deviceSize.width;
    delta.height = (height2 - height1) * deviceSize.height;
    return delta;
}

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
    NSLog(@"Game quit event triggered!!!");
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
    NSLog(@"Quit event triggered!!!");
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
	[self setAcceptsTouchEvents:YES];
	_tracking = NO;
	threshold = 1;
	lastpoint = NSZeroPoint;
	
    theGameView = self;
    screenbuf_lock = [[NSConditionLock alloc] initWithCondition:0];
    game_quit = 0;

	NSLog(@"%@", [[representedObject content] attributeKeys]);
	NSLog(@"%@", [[representedObject content] exposedBindings]);
	
	
	NSLog(@"awakeFromNib, paksetname is: %@", [[representedObject content] valueForKey:@"paksetname"]);
	
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
	[argvs addObject:[NSString stringWithString:@"-objects"]];
	[argvs addObject:[NSString stringWithString:@"pak/"]];
	
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
