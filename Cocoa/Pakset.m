/*
 * Copyright (c) 2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 22/06/2012
 */

#import "Pakset.h"

@implementation Pakset


/*
 Store listing of localy downloaded paksets, along with those available online
 Online listing populated at launch, when connection available
 
 name
 description			
 downloadedversion		
 availableversion		
 url					
 localpath				
 */

- (id) init
{
    if ((self = [super init]))
    {
        NSArray* keys      = [NSArray arrayWithObjects: @"paksetname", @"paksetdesc", nil];
        NSArray* values    = [NSArray arrayWithObjects: @"test pakset 1", @"Description of test pakset 1", nil];
        properties = [[NSMutableDictionary alloc] initWithObjects: values forKeys: keys];
    }
    return self;
}


- (NSMutableDictionary*) properties
{
    return properties;
}

- (void) setProperties: (NSDictionary*)newProperties
{
    if (properties != newProperties)
    {
        properties = [[NSMutableDictionary alloc] initWithDictionary: newProperties];
    }
}





@end
