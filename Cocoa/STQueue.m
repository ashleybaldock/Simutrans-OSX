/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 21/12/2011
 */

#import "STQueue.h"

/*
 * Thread-safe producer/consumer queue implementation with blocking/non-blocking item removal
 */
@implementation STQueue

- (id)init
{
    if ( (self=[super init]) )
    {
        elements = [[NSMutableArray alloc] init];
        lock = [[NSConditionLock alloc] initWithCondition:0];
    }
    return self;
}

/* - (void)dealloc
{
    [elements release];
    [self dealloc];
    [super dealloc];
} */

- (void)enqueue:(id)object
{
    [lock lock];
    [elements addObject:object];
	//NSLog(@"enqueue, queue length: %lu", (unsigned long)[elements count]);
    [lock unlockWithCondition:1];
}

- (void)enqueueAtFront:(id)object
{
    [lock lock];
    [elements insertObject:object atIndex:0];
	//NSLog(@"enqueueAtFront, queue length: %lu", (unsigned long)[elements count]);
    [lock unlockWithCondition:1];
}

/*
 * Get an item from the queue, if queue empty return nil object immediately
 */
- (id)dequeue
{
    [lock lock];
    id element = nil;
    if ([elements count] > 0)
    {
//        element = [[[elements objectAtIndex:0] retain] autorelease];
        element = [elements objectAtIndex:0];
        [elements removeObjectAtIndex:0];
		//NSLog(@"dequeue, queue length: %lu", (unsigned long)[elements count]);
    }
    [lock unlockWithCondition:([elements count] > 0) ? 1 : 0];
    return element;
}

/*
 * Get an item from the queue, block & wait for item if no items found
 */
- (id)dequeueBlock
{
    [lock lockWhenCondition:1];
//    id element = [[[elements objectAtIndex:0] retain] autorelease];
    id element = [elements objectAtIndex:0];
    [elements removeObjectAtIndex:0];
	//NSLog(@"dequeueBlock, queue length: %lu", (unsigned long)[elements count]);
    
    [lock unlockWithCondition:([elements count] > 0) ? 1 : 0];
    return element;
}

@end
