//
//  Pakset.h
//  simutrans
//
//  Created by Timothy Baldock on 22/06/2012.
//  Copyright (c) 2012 Simutrans Project. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * All details about a pakset
 * 
 * Includes files on disk (download) etc.
 * Local listing is stored describing installed paksets
 * this is merged with the online liting retrieved at startup
 * and the two together provide information for the in-game listing
 *
 * properties dict contains:
 *  paksetname
 *  paksetdesc
 *  ...
 */

@interface Pakset : NSObject
{
	NSMutableDictionary* properties;
}

- (NSMutableDictionary*) properties;

- (void) setProperties: (NSDictionary*)newProperties;


@end
