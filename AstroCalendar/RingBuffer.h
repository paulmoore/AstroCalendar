//
//  RingBuffer.h
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-09.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
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
 * A Queue (sort of).
 */
@interface RingBuffer : NSObject
{

	@private
    int _capacity; //The total fixed capacity of the ringbuffer.
    int _count; //The number of elements currently in the ringbuffer.
    int _indexLast; //The index to the last element in the ringbuffer.
    
    NSMutableArray *_elements; //Array containing the elements of the ring buffer.
}

//////////////////////////////////////////////////////////
// Constructor											//
//														//
// Initalizes the ringbuffer with a fixed size			//
// capacity.											//
//////////////////////////////////////////////////////////
- (id)initWithCapacity:(int) capacity;

//////////////////////////////////////////////////////////
// Constructor											//
//														//
// Initializes a new ringbuffer with the contents and	//
// state of a ringbuffer that was serialized to a pfile.//
//////////////////////////////////////////////////////////
- (id)initFromPList:(NSString*) pFile;


//Properties.
//////////////////////////////////////////////////////////
// Returns the total fixed capacity of the ringbuffer.	//
//////////////////////////////////////////////////////////
-(int) capacity;

//////////////////////////////////////////////////////////
// Returns the number of elements currently in the		//
// ringbuffer.											//
//////////////////////////////////////////////////////////
-(int) count;


//Methods.
//////////////////////////////////////////////////////////
// Adds the given element to the ringbuffer. This will	//
// overwrite the oldest element in the buffer, if the 	//
// buffer is at capacity.								//
//////////////////////////////////////////////////////////
-(int) add:(id) element;

//////////////////////////////////////////////////////////
// Returns an array containing the elements in the 		//
// ringbuffer.											//
//////////////////////////////////////////////////////////
-(NSArray*) elements;

//////////////////////////////////////////////////////////
// Serializes the ringbuffer into the given pfile.		//
//////////////////////////////////////////////////////////
-(void) writeToPFile:(NSString*) filename;

//////////////////////////////////////////////////////////
// Deserializes and populates this ringbuffer from the	//
// given pfile.											//
//////////////////////////////////////////////////////////
-(void) loadFromPFile:(NSString*) filename;

//////////////////////////////////////////////////////////
//Removes all elements from the buffer and resets index	//
//pointers.												//
//////////////////////////////////////////////////////////
-(void) clear;
@end
