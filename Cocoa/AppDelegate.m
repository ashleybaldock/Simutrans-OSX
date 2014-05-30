/*
 * Copyright (c) 2011-2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#import "AppDelegate.h"
#import "GameView.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize gameView = _gameView;

- (void)applicationDidFinishLaunching:(NSNotification *) __unused aNotification
{
    // Insert code here to initialize your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) __unused theApplication
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *) __unused sender
{
	if (_gameView->GameThreadHasQuit)
	{
		return NSTerminateNow;
	}
	else
	{
		[_gameView sendQuitEventToGameThread];
		return NSTerminateLater;
	}
}

@end
