//
//  AstroCalendarTests.m
//  AstroCalendarTests
//
//  Created by Paul Moore on 11-10-19.
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

#import "AstroCalendarTests.h"
#import "RingBuffer.h"
#import "MasterDataHandler.h"

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
- (void)testRBinit
{
	RingBuffer *buffer = [[RingBuffer alloc] initWithCapacity:24];
    
    STAssertTrue([buffer capacity] == 24, @"RB capacity is not being set.");
    STAssertTrue([buffer count] == 0, @"RB count should be 0, as the RB should be empty.");
}

- (void)testRBAdd
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

- (void)testRBElements
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

- (void)testRBSaveLoad
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

//////////////////////////////////////////////////////////
// DAY DATA CACHING TESTS								//
//////////////////////////////////////////////////////////
- (void)testCacheAddDay
{
	//Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

	MasterDataHandler *dataHandler = [MasterDataHandler sharedManager];
    [dataHandler clearCache];
    
    //Create dummy day.
    DayContainer *dummyDay = [[DayContainer alloc]init];

    //Fill the dummyDay with dummy info - the only thing that matters for our tests is the month/day/year.
    NSDateComponents *dummyBuildDate = [[NSDateComponents alloc] init];
    [dummyBuildDate setDay:14];
	[dummyBuildDate setMonth:3];
    [dummyBuildDate setYear:1989]; //Stephen's birthday!
        
    dummyDay.date = [helperCalendar dateFromComponents:dummyBuildDate];
    
    //dummyDay.sunrise = [helperFormatter dateFromString:@"01-01-200001-01-01"];
    //dummyDay.sunset = [helperFormatter dateFromString:@"01-01-200001-01-01"];
    //dummyDay.moonrise = [helperFormatter dateFromString:@"01-01-200001-01-01"];
   	//dummyDay.moonset = [helperFormatter dateFromString:@"01-01-200001-01-01"];
        
    //dummyDay.tithi = @"it's a tithi!";
    //dummyDay.fortnight = @"it's a fortnight!";
    //dummyDay.lunarMonth = @"it's a lunar month!";
    
    
    //Now, add the day!
    [dataHandler addDayToCache:dummyDay];
    
    //Now, let's see if it's in the ring buffer.
    NSArray *indexBufferElement = [dataHandler.dataCacheIndexer elements];
    
    STAssertTrue([dataHandler.dataCacheIndexer count] == 1 , [NSString stringWithFormat: @"Actual value: %i", [dataHandler.dataCacheIndexer count]]);
    
    NSDate *indexedDate = [[indexBufferElement objectAtIndex:0] objectForKey:@"date"]; //((DayContainer*)[indexBufferElement objectAtIndex:0]).date;
    
    STAssertTrue([indexedDate isEqual: dummyDay.date], @"Failed to store an index to the month containing the dummy day in the cache index buffer. Expected: %@, Actual: %@", dummyDay.date, indexedDate);
    
    //Now check to see if it's been stored in the appropriate dictionary.
    NSDictionary *monthSet = (NSDictionary*)[[dataHandler dataCache] objectForKey:[[NSNumber numberWithInt:0] description]];
    
    indexedDate = ((DayContainer*)[monthSet objectForKey:[[NSNumber numberWithInt:14] description]]).date;
    
    STAssertTrue([indexedDate isEqual: dummyDay.date], [NSString stringWithFormat:@"Failed to store the actual data information in the in-memory cache dictionary. Expected: %@, Actual: %@", dummyDay.date, indexedDate]);
    
    
    //Clear out previous test. Need to start fresh to make sure our assumptions about indices hold.
    [dataHandler clearCache];
    
    STAssertTrue([[dataHandler dataCacheIndexer] count] == 0, @"The cache should be empty, but it is not");
    
    //Add a day for every month (24 of 'em)!
    [dummyBuildDate setDay:2];
    for (int i = 1; i <= 24; i++)
    {
    	[dummyBuildDate setMonth:i];
        
        DayContainer *tDate = [[DayContainer alloc]init];
        tDate.date = [helperCalendar dateFromComponents:dummyBuildDate];
        int newIndex = [dataHandler addDayToCache:tDate];
        
        STAssertTrue([[dataHandler dataCacheIndexer] count] == i, [NSString stringWithFormat: @"Indexer size was wrong. Expected: %i, Actual: %i", i, [[dataHandler dataCacheIndexer] count]]);
        
        STAssertTrue(newIndex == (i - 1), [NSString stringWithFormat: @"Index of new month is wrong. Expected: %i, Actual: %i", (i - 1), newIndex]);
        
        STAssertTrue([[dataHandler dataCache] count] == i, [NSString stringWithFormat:@"In-memory dictionary does not have the corrent number of months. Expected: %i, Actual: %i", i, [[dataHandler dataCache] count]]);
    }
    
    //Now, check to make sure they're in there.
    STAssertTrue([[dataHandler dataCacheIndexer] count] == 24, @"Cache indexer element count wrong. Expected: 24, Actual: %i", [[dataHandler dataCacheIndexer] count]);
    
    //Ok, let's check the date on every element.
    for (int i = 1; i <= 24; i++)
    {
    	NSDictionary *cachedMonthSet = (NSDictionary*)[[dataHandler dataCache] objectForKey:[[NSNumber numberWithInt:(i-1)] description]];
        
        STAssertFalse(cachedMonthSet == nil, [NSString stringWithFormat: @"The month set for month %i could not be retrieved.", i - 1]);
        
        DayContainer *cachedDay = (DayContainer*)[cachedMonthSet objectForKey:[[NSNumber numberWithInt:2] description]];
        
        STAssertFalse(cachedDay == nil, @"The day could not be retrieved");
        
        //Verify the dates.
        NSDateComponents *cachedDayComponents = [helperCalendar components:NSDayCalendarUnit | NSMonthCalendarUnit  fromDate:cachedDay.date];
        
        STAssertTrue([cachedDayComponents day] == 2, [NSString stringWithFormat: @"Retrieved month is wrong. Expected: %i, Actual: %i", i, [cachedDayComponents day]]);
    }
    
    //Cleanup!
    [dataHandler clearCache];
}

- (void)testCacheRetrieveDayFromCache
{
	MasterDataHandler *dataHandler = [MasterDataHandler sharedManager];
    
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    
    //Add one day, and pull it back out.
    DayContainer *dummyDay = [[DayContainer alloc]init];
    
    //Fill the dummyDay with dummy info - the only thing that matters for our tests is the month/day/year.
    NSDateComponents *dummyBuildDate = [[NSDateComponents alloc] init];
    [dummyBuildDate setDay:14];
	[dummyBuildDate setMonth:3];
    [dummyBuildDate setYear:1989]; //Stephen's birthday!
        
    dummyDay.date = [helperCalendar dateFromComponents:dummyBuildDate];
    
    //Now, add the day!
    [dataHandler addDayToCache:dummyDay];
    
	STAssertTrue([[dataHandler retrieveDayFromCache: dummyDay.date] isEqual: dummyDay], @"Could not retrieve the dummy day inserted into the cache");
    
    //Try inserting a bunch of days and pull them back.
    
    NSMutableArray *dummyDays = [[NSMutableArray alloc]init];
    
    [dummyBuildDate setMonth:4];
    for (int i = 1; i < 24; i++)
    {
    	[dummyBuildDate setDay:i];
        
        DayContainer *testDay = [[DayContainer alloc]init];
        testDay.date = [helperCalendar dateFromComponents:dummyBuildDate];
        
        [dataHandler addDayToCache:testDay];
        [dummyDays addObject:testDay];
    }
    
    //Now, check that we can pull them all back out.
    for (DayContainer *day in dummyDays)
	{
    	DayContainer *tmpDay = (DayContainer*)[dataHandler retrieveDayFromCache:day.date];
    
    	STAssertTrue([tmpDay.date isEqual: day.date], [NSString stringWithFormat:@"Days do not match. Expected: %@, Actual: %@", day.date, tmpDay.date]);
	}
}

- (void)testCacheWriteLoad
{
	MasterDataHandler *dataHandler = [MasterDataHandler sharedManager];
    [dataHandler clearCache];
    
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];

    //Create a bunch of days to fill a month.
    NSMutableArray *testDaySet = [[NSMutableArray alloc]init];
    
    NSDateComponents *dummyBuildDate = [[NSDateComponents alloc] init];
    [dummyBuildDate setMonth:3];
    [dummyBuildDate setYear:1989]; //Stephen's birthday!

    
    for (int i = 1; i < 24; i += 2)
    {
    	DayContainer *dummyDay = [[DayContainer alloc]init];
    
    	//Fill the dummyDay with dummy info - the only thing that matters for our tests is the month/day/year.
        [dummyBuildDate setDay: i];
    	dummyDay.date = [helperCalendar dateFromComponents:dummyBuildDate];
        
        [dataHandler addDayToCache:dummyDay];
        [testDaySet addObject:dummyDay];
    }
    
    //Save it out to disk.
    [dataHandler writeCache:((DayContainer*)[testDaySet objectAtIndex:0]).date];
    
    //Load the cache back in.
	[dataHandler loadCache];
    
    //Now, verify dates.
    for (DayContainer *day in testDaySet)
	{
    	DayContainer *tmpDay = (DayContainer*)[dataHandler retrieveDayFromCache:day.date];
    
    	STAssertTrue([tmpDay.date isEqual: day.date], [NSString stringWithFormat:@"Days do not match. Expected: %@, Actual: %@", day.date, tmpDay.date]);
	}

}


//////////////////////////////////////////////////////////
// DAYCONTAINER TESTS									//
//////////////////////////////////////////////////////////
- (void)testDayContainerEncodeDecode
{
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];


 	//Create dummy day.
    DayContainer *dummyDay = [[DayContainer alloc]init];

    //Fill the dummyDay with dummy info - the only thing that matters for our tests is the month/day/year.
    NSDateComponents *dummyBuildDate = [[NSDateComponents alloc] init];
    [dummyBuildDate setDay:14];
	[dummyBuildDate setMonth:3];
    [dummyBuildDate setYear:1989]; //Stephen's birthday!
        
    dummyDay.date = [helperCalendar dateFromComponents:dummyBuildDate];
    
    NSDateFormatter *helperFormatter = [[NSDateFormatter alloc] init];
    [helperFormatter setDateFormat:@"dd-MM-yyyyhh-mm-ss"];
    
    dummyDay.sunrise = [helperFormatter dateFromString:@"01-01-200001-01-01"];
    dummyDay.sunset = [helperFormatter dateFromString:@"01-01-200001-01-01"];
    dummyDay.moonrise = [helperFormatter dateFromString:@"01-01-200001-01-01"];
   	dummyDay.moonset = [helperFormatter dateFromString:@"01-01-200001-01-01"];
        
    dummyDay.tithi = @"it's a tithi!";
    dummyDay.fortnight = @"it's a fortnight!";
    dummyDay.lunarMonth = @"it's a lunar month!";
    
    NSDictionary *encoded = [dummyDay encodeAsDictionary];
    
    DayContainer *decoded = [[DayContainer alloc]init];
    [decoded decodeFromDictionary:encoded];
    
    STAssertTrue([dummyDay.tithi compare: decoded.tithi] == NSOrderedSame, [NSString stringWithFormat:@"Tithis do not match. Expected: %@, Actual: %@", dummyDay.tithi, decoded.tithi]);
}

@end
