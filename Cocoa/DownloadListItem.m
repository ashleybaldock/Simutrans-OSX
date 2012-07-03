/*
 * Copyright (c) 2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 29/03/2012
 */

#import "DownloadListItem.h"

@implementation DownloadListItem

- (id)initWithFrame:(NSRect)frame
{
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (IBAction)doButtons:(NSSegmentedControl*)sender {
	NSString* s = [[self representedObject] valueForKey:@"paksetname"];
	NSLog(@"Pakname is: %@", s);
	//NSWindow* w = [[NSWindow alloc] init];
	[NSBundle loadNibNamed:@"GameView" owner:self];
}


@end
