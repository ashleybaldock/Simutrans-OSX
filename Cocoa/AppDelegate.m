/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import "AppDelegate.h"
#import "GameView.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *) __unused aNotification
{
    // Insert code here to initialize your application
}

/*- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // We should not terminate until the game thread does
    
	// TODO Go through all Pakset objects' GameView references (if not NIL) and signal that game 
	// instance to quit, once the last one has done so NSTerminateNow will be sent back
	return NSTerminateNow;
	
    GameView* gv = [_window contentView];
    
    // If game thread has already exited, then we can quit
    if (gv->game_quit == 1) {
        NSLog(@"applicationShouldTerminate - game thread not running, quitting directly");
        return NSTerminateNow;
    } else {
        NSLog(@"applicationShouldTerminate - game thread running, asking it to quit and waiting");
        // Otherwise ask the game thread to exit and wait
        gv->game_quit = 2;
        [gv trigger_quit];
        
        return NSTerminateLater;
    }
}*/

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) __unused theApplication
{
    return YES;
}

@end
