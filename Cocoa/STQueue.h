/*
 * Copyright (c) 2011 Simutrans Project
 *
 * Created by Timothy Baldock on 21/12/2011.
 *
 * This file is part of the Simutrans project under the artistic licence.
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
