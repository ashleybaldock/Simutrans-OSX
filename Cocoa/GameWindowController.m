//
//  GameWindowController.m
//  simutrans
//
//  Created by Timothy Baldock on 28/06/2012.
//  Copyright (c) 2012 Simutrans Project. All rights reserved.
//

#import "GameWindowController.h"
#import "GameView.h"

@interface GameWindowController ()

@end

@implementation GameWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


/*
 * 
 */
- (bool)windowShouldClose:(id)sender
{
    // We should not terminate until the game thread does
    
    GameView* gv = [sender contentView];
    
    // If game thread has already exited, then we can quit
    if (gv->game_quit == 1) {
        NSLog(@"windowShouldClose - game thread not running, quitting directly");
        return YES;
    } else {
        NSLog(@"windowShouldClose - game thread running, asking it to quit and waiting");
        // Otherwise ask the game thread to exit and wait
        gv->game_quit = 2;
        [gv trigger_quit];
        
        return NO;
    }
}

@end
