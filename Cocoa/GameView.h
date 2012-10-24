/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import <Cocoa/Cocoa.h>

@interface GameView : NSView {
@public
	IBOutlet NSObjectController* representedObject;
    NSConditionLock* screenbuf_lock;    // 0 = Normal, 1 = resizing
    int game_quit;
	
	// Touch event stuff
	CGFloat threshold;
	NSTouch* lastTouches[2];
	NSTouch* currentTouches[2];
	BOOL _tracking;
	NSSize displacement;
	NSPoint lastpoint;
}

- (void)trigger_quit;
- (void)game_trigger_quit;

// The two tracked touches are considered the bounds of a rectangle. THe following methods allow you to get the change in origin or size from the inital tracking values to the current values of said rectangle. The values are in points (72ppi)
@property(readonly) NSPoint deltaOrigin;
@property(readonly) NSSize deltaSize;

@end
