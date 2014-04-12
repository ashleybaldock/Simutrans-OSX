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
	// 0 ... 1 - Size of initial motion to trigger event
	CGFloat threshold;
	// 0 ... 1 - Step granularity for events
	CGFloat step;
	
	NSTouch* lastTouches[2];
	NSTimeInterval lastTime;
	NSTouch* currentTouches[2];
	NSTimeInterval currentTime;
	BOOL _tracking;	
	NSSize touchesDisplacementFromTouchOrigin[2];
	
}

- (void)trigger_quit;
- (void)game_trigger_quit;

@end
