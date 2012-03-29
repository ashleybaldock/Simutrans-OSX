/*
 * Copyright (c) 2011-2012 Timothy Baldock <tb@entropy.me.uk>
 *
 * Created 21/12/2011
 */

#import <Foundation/Foundation.h>

@interface STQueue : NSObject {
    NSMutableArray* elements;
    NSConditionLock* lock; // 0 = no elements, 1 = elements
}

- (id)init;
- (void)enqueue:(id)object;
- (void)enqueueAtFront:(id)object;
- (id)dequeue;
- (id)dequeueBlock;
//- (void)dealloc;

@end
