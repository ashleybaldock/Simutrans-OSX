/*
 * Copyright (c) 2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 29/03/2012
 */

#import <Foundation/Foundation.h>

@interface LauncherWindowController : NSObject {
	IBOutlet NSCollectionView *downloadList;
	IBOutlet NSArrayController *arrayController;
	
	NSMutableArray* collection;
}

- (IBAction)addAction:(id)sender;

- (void)awakeFromNib;

@property (copy) NSArray* collection;

@end
