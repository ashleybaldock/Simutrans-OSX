/*
 * Copyright (c) 2011-2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import <Cocoa/Cocoa.h>

@interface GameView : NSView {
@public
	IBOutlet NSObjectController* representedObject;
    NSConditionLock* screenbuf_lock;    // 0 = Normal, 1 = resizing
	BOOL UIHasAskedGameToQuit;
	BOOL GameThreadHasQuit;
	
	NSString* SimutransUserDirectory;
}

- (IBAction)openUserFolder:(id)sender;
- (IBAction)openBundle:(id)sender;
- (IBAction)takeScreenshot:(id)sender;

- (void)sendQuitEventToGameThread;
- (void)gameThreadRequestQuit;
- (void)screenshot;

@end
