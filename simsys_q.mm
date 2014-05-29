/*
 * Copyright (c) 2011-2014 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 13/12/2011
 */

#ifndef _MSC_VER
#include <unistd.h>
#include <sys/time.h>
#endif

#include <assert.h>

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>

#import "Cocoa/GameView.h"
#import "Cocoa/STQueue.h"

#include "macros.h"
#include "simsys.h"
#include "simgraph.h"
#include "simmem.h"
#include "simevent.h"


#ifndef COLOUR_DEPTH
#define COLOUR_DEPTH 16
#endif

#if COLOUR_DEPTH == 16
typedef unsigned short PIXVAL;
#else
#	error unknown COLOUR_DEPTH
#endif



// Globals we need
// Width and height of the actual screen buffer
int width = 0;
int height = 0;
// PIXVAL is a uint16 (RGB 1555)
PIXVAL* screenbuf = NULL;

// Reference to the window which we draw to
extern GameView* theGameView;
// Reference to the queue of Cocoa events which Simutrans needs to take notice of
extern STQueue* eventqueue;


/*
 * Initialise the OS-specific window
 * First
 */
bool dr_os_init(const int*)
{
	// prepare for next event
	sys_event.type = SIM_NOEVENT;
	sys_event.code = 0;
	return TRUE;
}

/*
 * Open the OS-specific window
 * Must return the actual width of the window
 * (Using Cocoa the app window is already open when game thread is started)
 */
//int dr_os_open(int w, int h, int fullscreen)
int dr_os_open(int, int, int)
{
    // Return the width of the viewport
	return theGameView.frame.size.width;
}

/*
 * Close the OS-specific window
 */
void dr_os_close(void)
{
    [theGameView game_trigger_quit];
}

/*
 * Resize screen buffer
 */
int dr_textur_resize(unsigned short** const textur, int w, int h)
{
    //NSLog(@"dr_textur_resize");
    // Obtain a lock on screenbuf to prevent Cocoa from trying to read from it during resize
    //[theGameView setNeedsDisplay:NO];
    [theGameView->screenbuf_lock lock];
    
    // Free previous screenbuf
    free(screenbuf);
    screenbuf = NULL;
    // Alloc new buffer
    width = w;
    height = h;
    screenbuf = MALLOCN(PIXVAL, w * h);
    *textur = (unsigned short*)screenbuf;

    // Remove lock on screenbuf
    [theGameView->screenbuf_lock unlockWithCondition:1];

    // Return new width
	return w;
}


/*
 * Initialise screen buffer
 * Returns a pointer to the memory that the game's software rendering
 * will draw into
 */
unsigned short* dr_textur_init()
{
    NSLog(@"dr_textur_init");
    // Obtain a lock on screenbuf to prevent Cocoa from trying to read from it during init
    [theGameView->screenbuf_lock lock];

    NSSize size = theGameView.frame.size;
    size_t const n = size.width * size.height;
    
    width = size.width;
    height = size.height;
    screenbuf = MALLOCN(PIXVAL, n);
    MEMZERON(screenbuf, n);
    
    // Remove lock on screenbuf
    [theGameView->screenbuf_lock unlockWithCondition:0];

	return (unsigned short*)screenbuf;
}


/* Utility functions */

/*
 * Query the current resolution of the platform-dependent window
 */
resolution dr_query_screen_resolution()
{
	resolution const res = { theGameView.frame.size.width, theGameView.frame.size.height };
	return res;
}

/*
 * Take a screenshot if possible, return status code for operation
 */
int dr_screenshot(const char __unused *filename, int __unused x, int __unused y, int __unused w, int __unused h)
{
	[theGameView screenshot];
	return 0;
}

/*
 * 16-bit colour can be either RGB1555 (5 bits each for r, g, b)
 * or RGB565 (5 bits for r and b, 6 for g)
 * Depending on your OS's native colourspace you must define a mapping
 * function to produce the correct output
 * Quartz only supports RGB1555, so we use that
 */
unsigned int get_system_color(unsigned int r, unsigned int g, unsigned int b)
{
    // RGB1555
	return ((r & 0x00F8) << 7) | ((g & 0x00F8) << 2) | (b >> 3);
}


/* Events */

// Convert from Cocoa event modifier keys to Simutrans event ones
static unsigned int convert_modifier_keys(NSEvent* evt)
{
    // Currently only ctrl and shift are implemented for Simutrans
	return
    (evt.modifierFlags & NSAlphaShiftKeyMask ? 0 : 0) |     // Capslock
    (evt.modifierFlags & NSShiftKeyMask      ? 1 : 0) |     // Shift
    (evt.modifierFlags & NSControlKeyMask    ? 2 : 0) |     // Ctrl
    (evt.modifierFlags & NSCommandKeyMask    ? 0 : 0) |     // Cmd
    (evt.modifierFlags & NSNumericPadKeyMask ? 0 : 0) |     // Any key in the numeric keypad is pressed, or arrow keys
    (evt.modifierFlags & NSHelpKeyMask       ? 0 : 0) |     // Help key
    (evt.modifierFlags & NSFunctionKeyMask   ? 0 : 0);      // F-keys, Help, Forward Delete, Home, End, Page Up, Page Down and the arrow keys
}

static void internal_GetEvents(bool wait)
{
	static NSPoint last_mouse_pos = NSMakePoint(-1, -1);
	
    NSEvent* evt;
    // Pick up an event from the queue (blocking or non-blocking)
    if (wait)
    {
        evt = [eventqueue dequeueBlock];
    }
    else
    {
        evt = [eventqueue dequeue];
    }
    
    if (evt == nil)
    {
        return;
    }
    

    // Filter by event type, and fill in appropriate Simutrans event
    switch (evt.type)
    {
        case NSLeftMouseDown:
        {
            sys_event.type    = SIM_MOUSE_BUTTONS;
			sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
			sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
			sys_event.mb      = SIM_MOUSE_LEFTBUTTON;
            sys_event.code    = SIM_MOUSE_LEFTBUTTON;
            break;
        }
        case NSRightMouseDown:
        {
            sys_event.type    = SIM_MOUSE_BUTTONS;
			sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
			sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
			sys_event.mb      = SIM_MOUSE_RIGHTBUTTON;
            sys_event.code    = SIM_MOUSE_RIGHTBUTTON;
			/*switch (event.button.button) {
				case 1: sys_event.code = SIM_MOUSE_LEFTBUTTON;  break;
				case 2: sys_event.code = SIM_MOUSE_MIDBUTTON;   break;
				case 3: sys_event.code = SIM_MOUSE_RIGHTBUTTON; break;
				case 4: sys_event.code = SIM_MOUSE_WHEELUP;     break;
				case 5: sys_event.code = SIM_MOUSE_WHEELDOWN;   break;
			}*/
            break;
        }
            
        case NSLeftMouseUp:
        {
			sys_event.type    = SIM_MOUSE_BUTTONS;
			sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
			sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
            sys_event.mb      = MOUSE_LEFTBUTTON;
            sys_event.code    = SIM_MOUSE_LEFTUP;
			break;
        }
        case NSRightMouseUp:
        {
			sys_event.type    = SIM_MOUSE_BUTTONS;
			sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
			sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
            sys_event.mb      = MOUSE_RIGHTBUTTON;
            sys_event.code    = SIM_MOUSE_RIGHTUP;
			/* switch (event.button.button) {
				case 1: sys_event.code = SIM_MOUSE_LEFTUP;  break;
				case 2: sys_event.code = SIM_MOUSE_MIDUP;   break;
				case 3: sys_event.code = SIM_MOUSE_RIGHTUP; break;
			} */
			break;
        }
        
        case NSMouseMoved:
        {
            sys_event.type    = SIM_MOUSE_MOVE;
            sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
			//NSLog(@"mouse moved newpos: (%f,%f)", last_mouse_pos.x, last_mouse_pos.y);
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
			//NSLog(@"local_point: (%f,%f)", local_point.x, local_point.y);
            sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
            sys_event.mb      = 0;
            sys_event.code    = SIM_MOUSE_MOVED;
            break;
        }

        case NSLeftMouseDragged:
        {
            sys_event.type    = SIM_MOUSE_MOVE;
            sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
            sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
            sys_event.mb      = MOUSE_LEFTBUTTON;
            sys_event.code    = SIM_MOUSE_MOVED;
            break;
        }

        case NSRightMouseDragged:
        {
            sys_event.type    = SIM_MOUSE_MOVE;
            sys_event.key_mod = convert_modifier_keys(evt);
            last_mouse_pos = [evt locationInWindow];
            NSPoint local_point = [theGameView convertPoint:last_mouse_pos fromView:nil];
            sys_event.mx      = local_point.x;
			sys_event.my      = height - local_point.y;
            sys_event.mb      = MOUSE_RIGHTBUTTON;
            sys_event.code    = SIM_MOUSE_MOVED;
            break;
        }
        
        case NSFlagsChanged:
        {
            // Indicates that modifier keys have changed, but Simutrans doesn't make use of this info
            sys_event.type = SIM_IGNORE_EVENT;
			sys_event.code = 0;
            break;
        }
            
        case NSKeyDown:
        {
            unsigned long code = 0;

            NSString *codechars = [evt charactersIgnoringModifiers];
            NSString *codecharsCS = [evt characters];
            
            unichar keyChar = 0;
            
            if ( [codechars length] == 0 ) {
                // Ignore dead keys
                code = 0;
            }
            else if ( [codechars length] == 1 ) {
                keyChar = [codechars characterAtIndex:0];
                switch (keyChar) {
                    case NSDeleteCharacter:         code = SIM_KEY_BACKSPACE;   break;
                    case NSTabCharacter:            code = SIM_KEY_TAB;         break;
					case NSBackTabCharacter:		code = SIM_KEY_TAB;			break;
                    case NSEnterCharacter:          code = SIM_KEY_ENTER;       break;
                    case NSLeftArrowFunctionKey:    code = SIM_KEY_LEFT;        break;
                    case NSRightArrowFunctionKey:   code = SIM_KEY_RIGHT;       break;
                    case NSUpArrowFunctionKey:      code = SIM_KEY_UP;          break;
                    case NSDownArrowFunctionKey:    code = SIM_KEY_DOWN;        break;
                    case NSHomeFunctionKey:         code = SIM_KEY_HOME;        break;
                    case NSEndFunctionKey:          code = SIM_KEY_END;         break;
                    case NSPageDownFunctionKey:     code = SIM_KEY_PGDN;        break;
                    case NSPageUpFunctionKey:       code = SIM_KEY_PGUP;        break;
                    case NSDeleteFunctionKey:       code = SIM_KEY_DELETE;      break;
                    case NSF1FunctionKey:           code = SIM_KEY_F1;          break;
                    case NSF2FunctionKey:           code = SIM_KEY_F2;          break;
                    case NSF3FunctionKey:           code = SIM_KEY_F3;          break;
                    case NSF4FunctionKey:           code = SIM_KEY_F4;          break;
                    case NSF5FunctionKey:           code = SIM_KEY_F5;          break;
                    case NSF6FunctionKey:           code = SIM_KEY_F6;          break;
                    case NSF7FunctionKey:           code = SIM_KEY_F7;          break;
                    case NSF8FunctionKey:           code = SIM_KEY_F8;          break;
                    case NSF9FunctionKey:           code = SIM_KEY_F9;          break;
                    case NSF10FunctionKey:          code = SIM_KEY_F10;         break;
                    case NSF11FunctionKey:          code = SIM_KEY_F11;         break;
                    case NSF12FunctionKey:          code = SIM_KEY_F12;         break;
                    case NSF13FunctionKey:          code = SIM_KEY_F13;         break;
                    case NSF14FunctionKey:          code = SIM_KEY_F14;         break;
                    case NSF15FunctionKey:          code = SIM_KEY_F15;         break;
                    default:
                        // TODO - need to cope with multi-character unicode inputs!
                        keyChar = [codecharsCS characterAtIndex:0];     // Use case-sensitive version (for Capslock)
                        code = keyChar;
                        break;
                }
            }
            else {
                // TODO - handle multi-character input in one keystroke!
            }
            sys_event.type    = SIM_KEYBOARD;
            sys_event.code    = code;
            sys_event.key_mod = convert_modifier_keys(evt);
            break;
        }

        case NSKeyUp:
        {
            sys_event.type = SIM_KEYBOARD;
			sys_event.code = 0;
            break;
        }

        case NSApplicationDefined:
        {
            switch (evt.subtype)
            {
                case 1:
                {
                    NSLog(@"Resize event");
                    sys_event.type = SIM_SYSTEM;
                    sys_event.code = SIM_SYSTEM_RESIZE;
                    sys_event.mx   = evt.data1;
                    sys_event.my   = evt.data2;
                    break;
                }
                case 2:
                {
                    NSLog(@"Quit event");
                    sys_event.type = SIM_SYSTEM;
                    sys_event.code = SIM_SYSTEM_QUIT;
                    break;
                }
            }
            break;
        }

        case NSScrollWheel:
        {
            if ([evt deltaY] < 0.0) {
				sys_event.type    = SIM_MOUSE_BUTTONS;
				sys_event.key_mod = convert_modifier_keys(evt);
				NSPoint event_location = [evt locationInWindow];
				NSPoint local_point = [theGameView convertPoint:event_location fromView:nil];
				sys_event.mx      = local_point.x;
				sys_event.my      = height - local_point.y;
				sys_event.mb      = 0;
				sys_event.code    = SIM_MOUSE_WHEELDOWN;
			} else if ([evt deltaY] > 0.0) {
				sys_event.type    = SIM_MOUSE_BUTTONS;
				sys_event.key_mod = convert_modifier_keys(evt);
				NSPoint event_location = [evt locationInWindow];
				NSPoint local_point = [theGameView convertPoint:event_location fromView:nil];
				sys_event.mx      = local_point.x;
				sys_event.my      = height - local_point.y;
				sys_event.mb      = 0;
				sys_event.code    = SIM_MOUSE_WHEELUP;
			}
			break;
        }

        default: {
            sys_event.type = SIM_IGNORE_EVENT;
			sys_event.code = 0;
            break;
        }
    }
}

/*
 * Get a new event from the events queue, wait for event if queue is empty
 */
void GetEvents(void)
{
    // Get an event, block if queue is empty
    internal_GetEvents(true);
}

/*
 * Get a new event from the events queue, do not wait if queue is empty
 */
void GetEventsNoWait(void)
{
    // If we don't find an event, this should be set to indicate there wasn't one
    sys_event.type = SIM_NOEVENT;
	sys_event.code = 0;
    internal_GetEvents(false);
}



/* Mouse-pointer */

/*
 * Not implemented for Mac as this breaks human interface guidelines
 */
void show_pointer(int)
{
}

/*
 * Not implemented for Mac as this breaks human interface guidelines
 */
void move_pointer(int, int)
{
}

/*
 * Not implemented for Mac as this breaks human interface guidelines
 */
void set_pointer(int)
{
}


/* Time */

static timeval first;

uint32 dr_time(void)
{
	timeval second;
	gettimeofday(&second,NULL);
	if (first.tv_usec > second.tv_usec) {
		// since those are often unsigned
		second.tv_usec += 1000000;
		second.tv_sec--;
	}
	return (uint32)(second.tv_sec - first.tv_sec)*1000ul + (uint32)(uint32)(second.tv_usec - first.tv_usec)/1000ul;
}

/*
 * OS-specific sleep function (millisecond accuracy)
 */
void dr_sleep(uint32 msec)
{
    //sleep( msec );
    usleep(msec * 1000);
}



/*
 * Indicate a section of the screen is dirty and needs redrawing
 * May be called multiple times by display_flush_buffer()
 */
void dr_textur(int __unused xp,int __unused yp, int __unused w, int __unused h)
{
    //NSLog(@"dr_textur, x: %i, y: %i, w: %i, h: %i", xp, yp, w, h);

    // Add the rect to the screen's list of areas which need to be updated
    // This will automatically cause a redraw at the next point one would normally occur

    // Coords need to be translated by flipping them vertically
    //NSRect rect = NSMakeRect(xp, height - yp - h, w, h);
    
    // TODO add these rects together to form the eventual dirty area for the next redraw
    // If we add them peicemeal then the other thread will update arbitrary areas of the screen out of sync!
    
    //rect = [theGameView convertRectFromBacking:rect];
    //[theGameView setNeedsDisplayInRect:rect];

}

/*
 * Called before drawing operations, pause here if needed
 * (Useful for thread-safety if a thread is used for screen rendering)
 */
void dr_prepare_flush()
{
    // Block on obtain lock on surface
    [theGameView->screenbuf_lock lock];
}

/*
 * Called after drawing operations have completed
 * Call display_flush_buffer(), which will repeatedly call dr_textur()
 * to indicate which regions of the screen need updating
 */
void dr_flush()
{
	// Call method to queue up rects for screen update via dr_textur()
    display_flush_buffer();
    
    // When drawing done, release lock
    [theGameView->screenbuf_lock unlockWithCondition:0];

    // Let UI thread know that screen needs to be redrawn
    [theGameView setNeedsDisplay:YES];
	[[theGameView window] setViewsNeedDisplay:YES];
		
	//[theGameView display];

}

/*
 * Application main loop
 * Just launches the Cocoa application, which then starts Simutrans in second thread
 */
int main (int argc, char** argv)
{
    gettimeofday(&first, NULL);

    return NSApplicationMain(argc, (const char**)argv);
}

