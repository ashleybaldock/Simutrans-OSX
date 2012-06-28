//
//  DownloadListItem.h
//  simutrans
//
//  Created by Timothy Baldock on 29/03/2012.
//  Copyright (c) 2012 Simutrans Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DownloadListItem : NSCollectionViewItem {
	IBOutlet NSSegmentedControl* statusbuttons;
	IBOutlet NSTextField* paksetname;
	IBOutlet NSTextField* paksetdesc;
	IBOutlet NSImageView* paksetimg;
}

- (IBAction)doButtons:(id)sender;

- (id)copyWithZone:(NSZone *)zone;

@end
