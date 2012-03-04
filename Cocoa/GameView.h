/*
 * Copyright (c) 2011 Simutrans Project
 *
 * Created by Timothy Baldock on 13/12/2011.
 *
 * This file is part of the Simutrans project under the artistic licence.
 */

#import <Cocoa/Cocoa.h>

@interface GameView : NSView {
@public
    NSConditionLock* screenbuf_lock;    // 0 = Normal, 1 = resizing
    int game_quit;
    int screenbuf_resizing;
}

- (void)trigger_quit;
- (void)game_trigger_quit;

@end
