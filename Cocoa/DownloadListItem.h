/*
 * Copyright (c) 2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 29/03/2012
 */

#import <Cocoa/Cocoa.h>

@interface DownloadListItem : NSCollectionViewItem {
	IBOutlet NSSegmentedControl* statusbuttons;
	IBOutlet NSTextField* paksetname;
	IBOutlet NSTextField* paksetdesc;
	IBOutlet NSImageView* paksetimg;
}

- (IBAction)doButtons:(id)sender;

//- (id)copyWithZone:(NSZone *)zone;

@end
