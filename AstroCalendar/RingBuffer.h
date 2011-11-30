//
//  RingBuffer.h
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-09.
//  University of British Columbia.
//  https://github.com/paulmoore/AstroCalendar
/*
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>

/**
 * A ringbuffer is a fixed-length array that overwrites the oldest
 * item in the array when and element is added that would exceed
 * capacity. This implementation supports serialization to/from
 * pLists.
 */
@interface RingBuffer : NSObject
{
#pragma mark -
#pragma mark Instance Data

	@private
    /** The fixed maximum number of elements that can be stored simultaniously
    	in the ringbuffer. */
    int _capacity;
    
    /** The number of elements currently stored in the ringbuffer. */
    int _count;
    
    /** The index of the latest element added to the ringbuffer. */
    int _indexLast;
    
    /** Array containing the elements that are stored in the ringbuffer. */
    NSMutableArray *_elements;
}

#pragma mark -
#pragma mark Instance Methods

/**
 * Initializes the ringbuffer with a fixed maximum capacity.
 *
 * @param capacity The maximum number of elements that can
                   exist in the ringbuffer. If capacity + 1
                   elements are added, the extra element
                   will overwrite the oldest element.
 */
- (id)initWithCapacity:(int)capacity;

/**
 * Initializes the ringbuffer by loading state and contents
 * from a pList that was previously written by a ringbuffer
 * instance.
 *
 * @param filename The path and name of the plist to read.
 */
- (id)initFromPList:(NSString *)filename;

/**
 * Serializes the ringbuffer to a property list.
 *
 * @param filename The name of the plist to write to.
 */
- (void)writeToPList:(NSString *)filename;

/**
 * Deserializes and populates the current ringbuffer
 * instance by loading state and contents from a pList
 * that was previously written by another ringbuffer
 * instance.
 */
- (void)loadFromPList:(NSString *)filename;

/**
 * Removes all elements from the ringbuffer and resets
 * index pointers.
 */
- (void)clear;

/**
 * Adds an element to the ringbuffer. If this causes the
 * number of contained elements to exceed the capacity of
 * the ringbuffer, the oldest element is replaced instead.
 *
 * @param element The element to add to the ringbuffer.
 * @return The index that the element has been stored at.
 */
- (int)add:(id)element;

/**
 * Returns an array containing all the elements in the
 * ringbuffer.
 */
- (NSArray *)elements;


#pragma mark -
#pragma mark Properties

/**
 * Returns the total fixed number of elements that can
 * be held by the ringbuffer.
 */
- (int)capacity;

/**
 * Returns the number of elements currently in the
 * ringbuffer.
 */
- (int)count;

@end
