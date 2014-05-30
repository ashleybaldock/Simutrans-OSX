/*
 * Copyright (c) 2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 30/05/2014
 */

#import <Foundation/Foundation.h>
#import "GameView.h"

@interface WindowDelegate : NSObject <NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet GameView *gameView;

@end
