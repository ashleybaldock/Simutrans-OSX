/*
 * Copyright (c) 2011 Simutrans Project
 *
 * Created by Timothy Baldock on 13/12/2011.
 *
 * This file is part of the Simutrans project under the artistic licence.
 */

#import "AppDelegate.h"
#import "GameView.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // We should not terminate until the game thread does
    
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
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
