//
//  AstroCalendarTests.m
//  AstroCalendarTests
//
//  Created by Paul Moore on 11-10-19.
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

#import "AstroCalendarTests.h"
#import "RingBuffer.h"

@implementation AstroCalendarTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

//////////////////////////////////////////////////////////
// RING BUFFER TESTS									//
//////////////////////////////////////////////////////////
-(void) testRBinit
{
	RingBuffer *buffer = [[RingBuffer alloc] initWithCapacity:24];
    
    STAssertTrue([buffer capacity] == 24, @"RB capacity is not being set.");
    STAssertTrue([buffer count] == 0, @"RB count should be 0, as the RB should be empty.");
}

-(void) testRBAdd
{
	RingBuffer *buffer = [[RingBuffer alloc] initWithCapacity:24];
    
    [buffer add: @"0"];
    
    STAssertTrue([buffer count] == 1, @"RB count is not correct.");
    
    [buffer add: @"1"];
    STAssertTrue([buffer count] == 2, @"RB count is not correct.");

	//Fill up buffer to capacity.    
    for (int i = 2; i <= 24; i++)
    	[buffer add:[NSString stringWithFormat:@"%i", i]];

	STAssertTrue([buffer count] == 24, @"RB count is not correct when full.");
    
    //Add one more to overflow and wrap around.
    [buffer add:@"24"];
    
    STAssertTrue([buffer count] == 24, @"RB count is not correct when wrapping around at full capacity.");
    
    NSArray *elements = [buffer elements];
    
    //Compare against the first element, which should be "24" because the lastIndex should have wrapped around.
    STAssertTrue([(NSString*)[elements objectAtIndex:0] compare: @"24"] == NSOrderedSame, [NSString stringWithFormat: @"Expected: 24, Actual: %@", [elements objectAtIndex:0]]);
}

-(void) testRBElements
{
	RingBuffer *buffer = [[RingBuffer alloc] initWithCapacity:5];
    
    for (int i = 0; i < 5; i++)
    {
    	[buffer add: [NSString stringWithFormat:@"%i", i]];
    }
        
    NSArray *elements = [buffer elements];
    
    for (int i = 0; i < 5; i++)
    {
    	NSString *tString = [NSString stringWithFormat:@"%i", i];
    	STAssertTrue([(NSString*)[elements objectAtIndex:i] compare: tString] == NSOrderedSame, (NSString*)[NSString stringWithFormat:@"Index %@, value %@ does not match.", tString, [elements objectAtIndex: i]]);
    }
}

-(void) testRBSaveLoad
{
	//Create some dummy data.
    RingBuffer *originalBuffer = [[RingBuffer alloc] initWithCapacity: 15];
    
    for (int i = 0; i < 15; i++)
    	[originalBuffer add: [NSString stringWithFormat:@"%i", i]];
        
    //Save it to disk.
    //HAHA - there's no disk, silly boy.
    [originalBuffer writeToPList:@"test_ringbuffer_saveload.plist"];
    
    //Ok, let's create a new buffer, load it from disk, and give it a shot.
    RingBuffer *loadedBuffer = [[RingBuffer alloc] initFromPList: @"test_ringbuffer_saveload.plist"];
    
    //Now, compare the elements in the two buffers - they should be string-equal.
    NSArray *originalElements = [originalBuffer elements];
    NSArray *loadedElements = [loadedBuffer elements];
    
    for (int i = 0; i < 15; i++)
    {
    	NSString *originalElement = (NSString*)[originalElements objectAtIndex: i];
        NSString *loadedElement = (NSString*)[loadedElements objectAtIndex: i];
    
    	STAssertTrue([originalElement compare: loadedElement] == NSOrderedSame , @"Elements at index %i do not match! Original: %@, loaded %@.", i, originalElement, loadedElement);
    }
    
    for (int i = 0; i < 14; i++)
    {
    	NSString *originalElement = (NSString*)[originalElements objectAtIndex: i];
        NSString *loadedElement = (NSString*)[loadedElements objectAtIndex: i + 1];
    
    	STAssertFalse([originalElement compare: loadedElement] == NSOrderedSame , @"Elements at index %i should not match! Original: %@, loaded %@.", i, originalElement, loadedElement);
    }
}


@end
