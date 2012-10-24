/*
 * Copyright (c) 2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 29/03/2012
 */

#import "LauncherWindowController.h"
#import "Pakset.h"

@implementation LauncherWindowController

@synthesize collection;

- (IBAction)addAction:(id) __unused sender {
	int index = [[arrayController arrangedObjects] count];
	[arrayController insertObject: [NSDictionary dictionaryWithObjectsAndKeys:@"Jon", @"Name", nil] atArrangedObjectIndex:index];
}

- (void) awakeFromNib {
	collection = [[NSMutableArray alloc] init];
	//NSSize size = NSMakeSize(500, 200);
	//[downloadList setMinItemSize:size];
	//[downloadList setMaxItemSize:size];
	
	[arrayController addObject: [NSDictionary dictionaryWithObjectsAndKeys:@"pak64", @"paksetname", @"Standard Simutrans pakset", @"paksetdesc", @"pak/", @"paksetpath", nil]];
	[arrayController addObject: [NSDictionary dictionaryWithObjectsAndKeys:@"pak128", @"paksetname", @"Double size graphics pakset", @"paksetdesc", @"pak2/", @"paksetpath", nil]];
	[arrayController addObject: [NSDictionary dictionaryWithObjectsAndKeys:@"pak96.comic", @"paksetname", @"Comic style pakset", @"paksetdesc", @"pak3/", @"paksetpath", nil]];
	
	// Connect to listing server to download pakset listing
	// Send game version, which is used to return only compatible paksets
	// Use online listing combined with local listing to produce array for display to users (add an element to array for each one)
	
}

// We want to accept keyboard events
- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end
