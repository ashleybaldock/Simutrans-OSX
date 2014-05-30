/*
 * Copyright (c) 2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 30/05/2014
 */

#import "WindowDelegate.h"

@implementation WindowDelegate

@synthesize window = _window;
@synthesize gameView = _gameView;

- (BOOL)windowShouldClose:(id) __unused sender
{
	if (_gameView->GameThreadHasQuit)
	{
		return YES;
	}
	else
	{
		[NSApp terminate: nil];
		return NO;
	}
}

@end
