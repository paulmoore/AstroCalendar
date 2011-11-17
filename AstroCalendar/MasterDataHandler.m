//
//  MasterDataHandler.m
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-01.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import "MasterDataHandler.h"

//
@interface NSURLRequest (DummyInterface)
	+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
	+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end
//

@implementation MasterDataHandler

static MasterDataHandler *sharedSingleton = nil;

double longitude, latitude;

@synthesize dataCacheIndexer;
@synthesize dataCache;



// Singleton pattern initializer. There should only ever be ONE instance of MasterDataHandler
// available to the application, so that only a single entry point to the data is visible.
// @see: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
+ (MasterDataHandler*)sharedManager
{
    if (sharedSingleton == nil) 
    {
        sharedSingleton = [[super allocWithZone:NULL] init];
        
        [sharedSingleton loadSettings];
        
        //Attempt to load the data cache from device - if it doesn't exist, then we start anew!
        @try 
        {
    		sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] load:@"dataCacheIndex.plist"];
            NSLog(@"Loading cached data index from dataCacheIndex.plist: %i months available, of %i months.", [sharedSingleton.dataCacheIndexer count], [sharedSingleton.dataCacheIndexer capacity]);
            
            //Set up in-memory cache.
            sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:[sharedSingleton.dataCacheIndexer capacity]];
		}
		@catch (NSException *exception) 
        {
    		//Errored out - probably means that there isn't a data cache in existence.
            sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] set: 24]; //Store 24 months worth of data.
            NSLog(@"Could not load data cache index, starting fresh!");
            
            //Create new in-memory cache.
            sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:24];
		}
    }
    
    return sharedSingleton;
}

 
+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedManager] retain];
}
 
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
 
- (id)retain
{
    return self;
}
 
- (NSUInteger)retainCount
{
    return NSUIntegerMax;  //denotes an object that cannot be released
}
 
- (oneway void)release
{
	[super release];
    //do nothing
}
 
- (id)autorelease
{
    return self;
}


//////////////////////////////////////////////////////////////
//															//
//////////////////////////////////////////////////////////////
-(void)askApiForDates:(NSDate*) startDate: (NSDate*) endDate
{
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
        
        NSArray *decoded = [sharedSingleton parseJSONDateRange: JSON];
        
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
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:operation];
}


///////////////////////////////////////////////////////////
//Parses a JSON response from the API server to create a new
//Day dataset. Returns an array containing all the days in
//the JSON response.
-(NSArray*)parseJSONDateRange: (id)json
{
	int dayCount = [[json valueForKeyPath:@"count"] intValue];
    
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    
    //Formatting for storing times.
    NSDateFormatter *helperFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [helperFormatter setDateFormat:@"dd-MM-yyyyHH-mm-ss"];
    
    NSMutableArray *dayContainers = [[NSMutableArray alloc] initWithCapacity:dayCount];
            
    for (int i = 0; i < dayCount; i++)
    {
    	DayContainer *newDay = [[DayContainer alloc] init];
    
    	@try 
        {
    		//Parse and build the date for this container.
    		NSDateComponents *buildDate = [[[NSDateComponents alloc] init] autorelease];
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
    		//Don't have to do anything here yet.
		}
    }
    
    return dayContainers;
}

///////////////////////////////////////////////////////////
//Registers a customer alert (displaying the message) on the given
//date (includes time).
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

///////////////////////////////////////////////////////////
//Saves applications settings to a Settings.plist file.
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
    	[errorDesc release];
    }
}

///////////////////////////////////////////////////////////
//Loads application settings from a Settings.plist file.
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
    if (settingsDictionary != nil)
    	[settingsDictionary release];
        
    settingsDictionary = [[NSMutableDictionary alloc]initWithDictionary:tempData];
    
    NSLog(@"Settings: RemoteAPIEndpoint: %@", [settingsDictionary objectForKey:@"APIEndpoint"]);
    NSLog(@"Settings: SnapshotSunviewDate: %@", [[settingsDictionary objectForKey:@"Snapshot"] objectForKey:@"SunviewDate"]);
}


///////////////////////////////////////////////////////////
//Adds a given day dataset to the cache. If the specified
//month isn't already cached, it overrides the oldest cached
//month.
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

///////////////////////////////////////////////////////////
//Retrieves a dictionary of cached days for a given month if
//it exists, otherwise returns nil.
-(NSMutableDictionary*)retrieveMonthSetFromCache:(NSDate *)date
{
	int monthIndex = -1;
    
    NSDateComponents *dateComponents = [[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date] autorelease];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [sharedSingleton.dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC date]] autorelease];
        
        if ([indexComponents year] == [dateComponents year] && [indexComponents month] == [dateComponents month])
        {
        	monthIndex = i;
            break;
        }
    }
    
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
    NSDateComponents *dateComponents = [[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date] autorelease];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [sharedSingleton.dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC date]] autorelease];
        
        if ([indexComponents year] == [dateComponents year] && [indexComponents month] == [dateComponents month])
        {
        	return i;
        }
    }
    
   	return -1;
}

///////////////////////////////////////////////////////////
//Returns the cached information for a given date if it exists,
//otherwise returns nil.
-(DayContainer*)retrieveDayFromCache:(NSDate *)date
{
	NSMutableDictionary *monthSet;

	//Early out, check for the month.
    monthSet = [self retrieveMonthSetFromCache:date];
    
    if (monthSet == nil)
    	return nil;
    else
    {
    	NSDateComponents *dateComponents = [[[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components: NSDayCalendarUnit fromDate:date] autorelease];
    
    	return [monthSet objectForKey:[[NSNumber numberWithInt:[dateComponents day]] description]];
    }
}


///////////////////////////////////////////////////////////
//Nuke the entire cash - we can leave plists, they'll get
//overridden anyway.
-(void)clearCache
{    
    //Clear out the actual cache.
    for (int i = 0; i < [dataCacheIndexer capacity]; i++)
    	[dataCache removeObjectForKey:[[NSNumber numberWithInt:i] description]];
    
    //Nuke index buffer.
	[dataCacheIndexer clear];
}


///////////////////////////////////////////////////////////
//Writes the month set of data for the given index to a
//plist on the device.
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
    	[errorDesc release];
    }

}


///////////////////////////////////////////////////////////
//Reads in the entire cache from plists on disk, and puts
//them in to the in-memory cache.
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
