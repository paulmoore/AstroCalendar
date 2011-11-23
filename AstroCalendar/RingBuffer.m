//
//  RingBuffer.m
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

#import "RingBuffer.h"
#import <math.h>

@implementation RingBuffer

//////////////////////////////////////////////////////////
// Constructor											//
//////////////////////////////////////////////////////////
- (id)initWithCapacity:(int)capacity
{
	self = [super init];
    
    if (self)
    {
    	_capacity = capacity;
        
        _elements = [[NSMutableArray alloc] initWithCapacity:_capacity];
                                                    
        _count = 0;
        _indexLast = 0;
    }
    return self;
}

- (id)initFromPList:(NSString *)pFile
{
	self = [super init];
    
    if (self)
    {
    	[self loadFromPList: pFile];
    }
    return self;
}


//////////////////////////////////////////////////////////
// Properties											//
//////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
//Capacity
-(int) capacity
{
	return _capacity;
}

///////////////////////////////////////////////////////////
//Count
-(int) count
{
	return _count;
}


//////////////////////////////////////////////////////////
// Instance Methods										//
//////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
//Add an element to the ringbuffer.
-(int) add:(id)element
{
	int oldIndex = _indexLast;
    
    if (_count < _capacity)
    	[_elements addObject: element];
    else
    	[_elements replaceObjectAtIndex:oldIndex withObject:element];  
    
    //Update the last element index, have it wrap around.
    _indexLast++;
    if (_indexLast >= _capacity)
    	_indexLast = 0;
    
    _count = MIN(_count + 1, _capacity);
    
    return oldIndex;
}


///////////////////////////////////////////////////////////
//Return an array of elements contained in the ringbuffer.
-(NSArray*) elements
{
	NSMutableArray *tArray = [[NSMutableArray alloc] initWithCapacity:_count];
    
    for (int i = 0; i < _count; i++)
    	[tArray addObject: [_elements objectAtIndex:i]];
        
    return [[NSArray alloc]initWithArray:tArray];
}

///////////////////////////////////////////////////////////
//Serializes the contents of the ring buffer to a plist in the app's root directory, with the given filename.
-(void) writeToPList:(NSString *)filename
{
    NSString *rootPath, *plistPath;
    NSString *errorDesc = nil;
    
    //Need to stick all our values in a dictionary so it can be stored/read as a key-value store.
    NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] init];
    [dataDictionary setObject:[NSNumber numberWithInt:_count] forKey:@"count"];
    [dataDictionary setObject:[NSNumber numberWithInt:_capacity] forKey:@"capacity"];
    [dataDictionary setObject:[NSNumber numberWithInt:_indexLast] forKey:@"indexLast"];
    [dataDictionary setObject:_elements forKey:@"elements"];
    
    

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingFormat: filename]; 
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:dataDictionary format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDesc];
    
    if(plistData) 
    {
        [plistData writeToFile:plistPath atomically:YES];
	} 
    else 
    {
    	NSLog(@"Error saving ringbuffer state to plist (%@): %@", filename, errorDesc);
    }

}

///////////////////////////////////////////////////////////
//Deserializes the contents of the ring buffer from a plist in the app's root directory.
-(void) loadFromPList:(NSString *)filename
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingFormat: filename]; 
    
    @try
    {
    	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    	NSDictionary *tempData = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    
    	if (!tempData) 
        {
    		NSLog(@"Error loading in ringbuffer contents from plist: %@, format: %d", errorDesc, format);
            @throw [NSException exceptionWithName:@"Cannot read ringbuffer contents from plist." reason:(NSString*)[NSString stringWithFormat:@"%@", errorDesc] userInfo:Nil];
        }
        
    	//Load settings.
    	_elements = [[NSMutableArray alloc]initWithArray: [tempData objectForKey:@"elements"]];
        _count = [[tempData objectForKey:@"count"] intValue];
        _capacity = [[tempData objectForKey:@"capacity"] intValue];
        _indexLast = [[tempData objectForKey:@"indexLast"] intValue];
    }
    @catch (NSException *exception) 
    {
    	NSLog(@"Error loading in ringbuffer contents from plist (%@): %@", filename, exception);
        
        @throw [NSException exceptionWithName:@"Cannot read ringbuffer contents from plist." reason:(NSString*)[NSString stringWithFormat:@"%@", exception] userInfo: [NSDictionary dictionaryWithObject:exception forKey:@"Exception"]];
    }
}

///////////////////////////////////////////////////////////
//Removes all elements from the buffer and resets pointers.
-(void) clear
{
    _elements = nil;
    _indexLast = 0;
    _count = 0;
    
    _elements = [[NSMutableArray alloc] initWithCapacity:_capacity];
}

@end
