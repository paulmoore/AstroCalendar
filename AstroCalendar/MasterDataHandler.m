//
//  MasterDataHandler.m
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-01.
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

#import "MasterDataHandler.h"

@interface NSURLRequest (DummyInterface)
	+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
	+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

static MasterDataHandler *sharedSingleton = nil;

@implementation MasterDataHandler

@synthesize dataCacheIndexer;
@synthesize dataCache;

+ (MasterDataHandler*)sharedManager
{
    if (sharedSingleton == nil) 
    {
        sharedSingleton = [[super alloc] init];
        
        [sharedSingleton loadSettings];
        
        //Attempt to load the data cache from device - if it doesn't exist, then we start anew!
        @try 
        {
    		sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] initFromPList:@"dataCacheIndex.plist"];
            NSLog(@"Loading cached data index from dataCacheIndex.plist: %i months available, of %i months.", [sharedSingleton.dataCacheIndexer count], [sharedSingleton.dataCacheIndexer capacity]);
            
            //Set up in-memory cache.
            sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:[sharedSingleton.dataCacheIndexer capacity]];
		}
		@catch (NSException *exception) 
        {
    		//Errored out - probably means that there isn't a data cache in existence.
            sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] initWithCapacity: 24]; //Store 24 months worth of data.
            NSLog(@"Could not load data cache index, starting fresh!");
            
            //Create new in-memory cache.
            sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:24];
		}
    }
    
    return sharedSingleton;
}

-(void)askApiForDates:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSLog(@"Heard message askApiForDates");
	//NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
	
	//Builds up our URL request string.
	NSString *urlString = [NSString stringWithFormat:@"%@?requestType=all&startDate=%@&endDate=%@&latitude=%d&longitude=%d", [settingsDictionary valueForKey:@"APIEndpoint"], [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate], latitude, longitude];
    
    NSLog(urlString);
    
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"cisxserver1.okanagan.bc.ca"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    
    
    //Build the async request.
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) 
    {
    	NSLog(@"Success!");
        
        NSArray *decoded = [self parseJSONDateRange: JSON];
        
        for(DayContainer *container in decoded) 
        {
    		NSLog(@"Date: %@", container.date);
            NSLog(@"Sunrise: %@", container.sunrise);
            NSLog(@"Sunset: %@", container.sunset);
            NSLog(@"Moonrise: %@", container.moonrise);
            NSLog(@"Moonset: %@", container.moonset);
            NSLog(@"Fortnight: %@", container.fortnight);
            NSLog(@"LunarMonth: %@\n", container.lunarMonth);
            
            [self addDayToCache:container];
		}
        
        //return decoded;
    } 
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) 
    {
        NSLog(@"Failure: %@ With Response: %@", error, [response description]);
    }];
    
    
    //Actually send that bitch out there.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

-(NSArray*)parseJSONDateRange: (id)json
{
	int dayCount = [[json valueForKeyPath:@"count"] intValue];
    
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    //Formatting for storing times.
    NSDateFormatter *helperFormatter = [[NSDateFormatter alloc] init];
    [helperFormatter setDateFormat:@"dd-MM-yyyyHH-mm-ss"];
    
    NSMutableArray *dayContainers = [[NSMutableArray alloc] initWithCapacity:dayCount];
            
    for (int i = 0; i < dayCount; i++)
    {
    	DayContainer *newDay = [[DayContainer alloc] init];
        NSDateComponents *buildDate = nil;
    
    	@try 
        {
    		//Parse and build the date for this container.
    		buildDate = [[NSDateComponents alloc] init];
        	[buildDate setDay:[[json valueForKeyPath:[NSString stringWithFormat:@"%i.dayNumerical", i]] intValue]];
        	[buildDate setMonth:[[json valueForKeyPath:[NSString stringWithFormat:@"%i.month", i]] intValue]];
        	[buildDate setYear:[[json valueForKeyPath:[NSString stringWithFormat:@"%i.year", i]] intValue]];
        
        	newDay.date = [helperCalendar dateFromComponents:buildDate];
        
        	newDay.sunrise = [helperFormatter dateFromString:[NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.sunrise", i]]]];
        
        	newDay.sunset = [helperFormatter dateFromString:[NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.sunset", i]]]];
        
        	newDay.moonrise = [helperFormatter dateFromString:[NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.moonrise", i]]]];
        
        	newDay.moonset = [helperFormatter dateFromString:[NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.moonset", i]]]];
        
        	newDay.tithi = [NSString stringWithFormat:@"%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.tithi", i]]];
        
        	newDay.fortnight = [NSString stringWithFormat:@"%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.fortnight", i]]];
        
        	newDay.lunarMonth = [NSString stringWithFormat:@"%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.lunarMonth", i]]];
    
    		[dayContainers addObject:newDay];
        }
		@catch (NSException *exception) 
        {
    		NSLog(@"Error decoding JSON data: %@", exception);
		}
		@finally 
        {
            // Nothing to do yet...
		}
    }
    
    return dayContainers;
}

-(void)registerAlertOnDate: (NSDate*) date: (NSString*) message
{
	/* Here we cancel all previously scheduled notifications */
	UILocalNotification *localNotification = [[UILocalNotification alloc] init];

	localNotification.fireDate = date;
	NSLog(@"Adding notification: %@, on %@", message, date);

	localNotification.timeZone = [NSTimeZone defaultTimeZone];
	localNotification.alertBody = message;
	localNotification.alertAction = NSLocalizedString(@"View details", nil);

	/* Here we set notification sound and badge on the app's icon "-1" 
	means that number indicator on the badge will be decreased by one 
	- so there will be no badge on the icon */

	localNotification.soundName = UILocalNotificationDefaultSoundName;
	//localNotification.applicationIconBadgeNumber = -1;

	[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

-(void) saveSettings
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingFormat:@"Settings.plist"]; 
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:settingsDictionary format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDesc];
    
    if(plistData) 
    {
        [plistData writeToFile:plistPath atomically:YES];
	} 
    else 
    {
    	NSLog(@"Error saving application state to plist: %@", errorDesc);
    }
}

-(void) loadSettings
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingFormat:@"Settings.plist"]; 
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) 
    	plistPath = [[NSBundle mainBundle] pathForResource:@"Settings"ofType:@"plist"];
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    NSDictionary *tempData = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    
    if (!tempData) 
    	NSLog(@"Error reading Settings plist: %@, format: %d", errorDesc, format);
        
    //Load settings.
    settingsDictionary = [[NSMutableDictionary alloc]initWithDictionary:tempData];
    
    NSLog(@"Settings: RemoteAPIEndpoint: %@", [settingsDictionary objectForKey:@"APIEndpoint"]);
    NSLog(@"Settings: SnapshotSunviewDate: %@", [[settingsDictionary objectForKey:@"Snapshot"] objectForKey:@"SunviewDate"]);
}

-(int)addDayToCache:(DayContainer *)data
{
	int addedKey = -1;

	NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSDayCalendarUnit fromDate:[data date]];
    
    NSMutableDictionary *monthSet = [self retrieveMonthSetFromCache:[data date]];
    
    if (monthSet == nil) //Haven't cached this month yet - time to add it!
    {
    	//Create a new month index container.
        MonthDataIndexer *newIndex = [MonthDataIndexer alloc];
    	newIndex.date = [data date];
        newIndex.dayCount = 1;
    
    	newIndex.index = [dataCacheIndexer add:newIndex];
        
        addedKey = newIndex.index;
        
        NSMutableDictionary *newMonthSet = [[NSMutableDictionary alloc]init];
        [dataCache setObject:newMonthSet forKey:[[NSNumber numberWithInt:newIndex.index] description]];
        
        monthSet = newMonthSet;
    }
    
    //Add the day to the month set.
    [monthSet setObject:data forKey:[[NSNumber numberWithInt:[dateComponents day]] description]];
    
    return addedKey;
}

-(NSMutableDictionary*)retrieveMonthSetFromCache:(NSDate *)date
{
	int monthIndex = -1;
    
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [sharedSingleton.dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC date]];
        
        if ([indexComponents year] == [dateComponents year] && [indexComponents month] == [dateComponents month])
        {
        	monthIndex = i;
            break;
        }
    }
    
    //[dateComponents release];
    
    if (monthIndex == -1)
    {
    	return nil;
    }
    else
    {
    	return [dataCache objectForKey:[[NSNumber numberWithInt:monthIndex]description]]; 
    }
    
    return nil;
}

-(int)retrieveMonthIndexFromCache:(NSDate *)date
{
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [sharedSingleton.dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC date]];
        
        if ([indexComponents year] == [dateComponents year] && [indexComponents month] == [dateComponents month])
        {
        	return i;
        }
    }
    
   	return -1;
}

-(DayContainer*)retrieveDayFromCache:(NSDate *)date
{
	NSMutableDictionary *monthSet;

	//Early out, check for the month.
    monthSet = [self retrieveMonthSetFromCache:date];
    
    if (monthSet == nil)
    	return nil;
    else
    {
    	NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components: NSDayCalendarUnit fromDate:date];
    
    	return [monthSet objectForKey:[[NSNumber numberWithInt:[dateComponents day]] description]];
    }
}

-(void)clearCache
{    
    //Clear out the actual cache.
    for (int i = 0; i < [dataCacheIndexer capacity]; i++)
    	[dataCache removeObjectForKey:[[NSNumber numberWithInt:i] description]];
    
    //Nuke index buffer.
	[dataCacheIndexer clear];
}

-(void) writeCache: (NSDate*) date
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;

	int monthIndex = -1; 
    monthIndex = [self retrieveMonthIndexFromCache:date];
    
    if (monthIndex < 0)
    	return; //Date doesn't exist in the cache, so we bail.

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    plistPath = [rootPath stringByAppendingFormat:@"dataCache_%i.plist", monthIndex]; 
    
    NSDictionary *monthSet = [self retrieveMonthSetFromCache:date];
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:monthSet format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDesc];
    
    if(plistData) 
    {
        [plistData writeToFile:plistPath atomically:YES];
	} 
    else 
    {
    	NSLog(@"Error writing cache for month at index %i: %@", monthIndex, errorDesc);
    }

}

-(void) loadCache
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //Loop over all the months that we might be caching, and attempt to deserialize them.
    //There's no gurantee that any given month will be cached (nothing says we've saved data out in
    //a serial fashion - this is expected behavior, but not enforced) so we need to expect
    //failures and keep on truckin'.
    for (int i = 0; i < [dataCacheIndexer capacity]; i++)
    {
    	plistPath = [rootPath stringByAppendingFormat:@"dataCache_%i.plist", i]; 
    
    	if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) 
    		plistPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat: @"dataCache_%i"]ofType:@"plist"];
    
    	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    	NSMutableDictionary *tempData = (NSMutableDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    
    	if (!tempData) 
    		NSLog(@"Unable to load cache data for month index %i: %@, format: %d",i, errorDesc, format);
        else
        	[dataCache setObject:tempData forKey:[[NSNumber numberWithInt:i] description]];
    }
}
@end
