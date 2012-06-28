//
//  LauncherWindowController.h
//  simutrans
//
//  Created by Timothy Baldock on 29/03/2012.
//  Copyright (c) 2012 Simutrans Project. All rights reserved.
//

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
