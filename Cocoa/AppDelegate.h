/*
 * Copyright (c) 2011-2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import <Cocoa/Cocoa.h>
#import "GameView.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSApplication *app;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet GameView *gameView;

@end
