//
//  MasterDataHandler.m
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-01.
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

#import "MasterDataHandler.h"

// This is a hack to allow for invalid ssh certs. to be ignored.
// Was done because our development server gave out bad certs,
// and we didn't have the ability to fix that.
@interface NSURLRequest (DummyInterface)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString *)host;

@end

static __strong MasterDataHandler *sharedSingleton = nil;

//static RingBuffer *dataCacheIndexer;
//static NSMutableDictionary *dataCache;
//static CoreLocationController *locationController;

@implementation MasterDataHandler

@synthesize settingsDictionary, dataCache, dataCacheIndexer, locationController;

+ (MasterDataHandler *)sharedManager
{
    if (sharedSingleton == nil) 
    {
        sharedSingleton = [[MasterDataHandler alloc] init];
        
        //Begin getting location info!
        //Do this first to try and give the device time to get back
        //to use before firing off a data request. If it doesn't get
        //back in time, we'll use the cached values.
        sharedSingleton.locationController = [[CoreLocationController alloc] init];
		sharedSingleton.locationController.delegate = self;
		[sharedSingleton.locationController.locationManager startUpdatingLocation];
        
        [MasterDataHandler loadSettings];
        
        //Attempt to load the data cache from device - if it doesn't exist, then we start anew!
        @try 
        {
    		sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] initFromPList:@"cache_index.plist"];
            NSLog(@"Loading cached data index from cache_index.plist: %i months available, of %i months.", [sharedSingleton.dataCacheIndexer count], [sharedSingleton.dataCacheIndexer capacity]);
            
            //Set up in-memory cache.
            //sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:[dataCacheIndexer capacity]];
            sharedSingleton.dataCache = [[NSMutableDictionary alloc] initWithCapacity:[sharedSingleton.dataCacheIndexer capacity]];
            
            [sharedSingleton loadCache];
		}
		@catch (NSException *exception) 
        {
    		//Errored out - probably means that there isn't a data cache in existence.
            sharedSingleton.dataCacheIndexer = [[RingBuffer alloc] initWithCapacity: 24]; //Store 24 months worth of data.
            NSLog(@"Could not load data cache index, starting fresh!");
            
            //Create new in-memory cache.
            //sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:24];
            sharedSingleton.dataCache = [[NSMutableDictionary alloc]initWithCapacity:24];
		}
    }
    
    return sharedSingleton;
}

- (void)getDates:(NSDate *)startDate endDate:(NSDate *)endDate delegate:(id<MasterDataHandlerDelegate>)delegate
{
	NSLog(@"Fielding request for dates...");

	NSMutableArray *cachedDays = [[NSMutableArray alloc]init];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    //Scan through request date range and pull from cache. The instant we
    //hit a date that isn't the cache, we're just going to pull ALL the dates
    //down from the API (to keep the cache fresh).
    
    NSDateComponents *endComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:endDate];
    
    NSDate *workingDate = (NSDate *)[startDate copy];
    NSDate *workingDatePlus = (NSDate *)[startDate copy];
    
    BOOL askApi = false;
    
    while ([endDate compare:workingDate] == NSOrderedDescending)
    {
    	NSLog([workingDate description]);
    	DayContainer *day = [self retrieveDayFromCache:workingDate];
        
        NSDateComponents *offsetExtra = [[NSDateComponents alloc]init];
        	[offsetExtra setDay:1];
        
        //Move forward a day.
        workingDatePlus = [gregorian dateByAddingComponents: offsetExtra toDate: workingDate options:0];
        
        DayContainer *dayPlusOne = [self retrieveDayFromCache:workingDatePlus];
    
    	NSDateComponents *workingComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:workingDate];
    
    	//If we miss two days in a row (sometimes no tithi starts on an individual day, so missing a day can happen. Can't skip a 48 hour period though)
        //or the end date is missing, then we need to pull from the cache.
    	if ((!day && !dayPlusOne) || (!day && [workingComponents year] == [endComponents year] && [workingComponents month] == [endComponents month] && [workingComponents day] == [endComponents day]))
        {
        	askApi = true;
            NSLog(@"Unable to retrieve day %@ from cache!", workingDate);
            break;
        }
        else
        {
        	if (day)
            {
        		[cachedDays addObject:day];
            }
        
        	NSDateComponents *offset = [[NSDateComponents alloc]init];
        	[offset setDay:1];
        
        	workingDate = [gregorian dateByAddingComponents: offset toDate: workingDate options:0];
            NSLog(@"Next date: %@", [workingDate description]);
        }
    }
    
    if (askApi)
    {
    	NSLog(@"Asking API for new data!");
    	[self askApiForDates:startDate endDate:endDate delegate:delegate]; //Ask api for data.
    }
    else
    {	
    	NSLog(@"Data retrieved from cache!");
    	[delegate didRecieveData:cachedDays]; //Return cached data.
    }
}

- (void)askApiForDates:(NSDate *)startDate endDate:(NSDate *)endDate delegate:(id<MasterDataHandlerDelegate>)delegate
{
	//NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
	
    //Grab location info.
    NSDictionary *locationSettings = [settingsDictionary objectForKey:@"Location"];
    
    //Get local timezone.
    NSTimeZone* currentTimeZone = [NSTimeZone localTimeZone];
    NSInteger currentGMTOffset = [currentTimeZone secondsFromGMT] / (60 * 60); //Divide to get hours.
    
    
	//Builds up our URL request string.
	NSString *urlString = [NSString stringWithFormat:@"%@?requestType=all&startDate=%@&endDate=%@&latitude=%@&longitude=%@altitude=%@&&GMTOffset=%i", [settingsDictionary valueForKey:@"APIEndpoint"], [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate], [locationSettings valueForKey:@"Latitude"], [locationSettings valueForKey:@"Longitude"], [locationSettings valueForKey:@"Altitude"], currentGMTOffset];
    
    NSLog(urlString);
    
    //WARNING! This is a hack used to ignore security certs over https. Bad news bears, but we
    //needed it because our dev server gave out invalid certs, and normally ios doesn't
    //allow us to connect.
	[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"cisxserver1.okanagan.bc.ca"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    //Build the async request.
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) 
    {
    	NSLog(@"Success!");
        
        NSCalendar *gregorian =  [NSCalendar currentCalendar];//[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        NSMutableArray *decoded = [self parseJSONDateRange: JSON];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = @"dd-MM-yy-HH-mm";
        [formatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: currentGMTOffset * 60 * 60]];//[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        
        //Look for duplicated tithi's, which means split in to two objects.
        for (int i = 0; i < [decoded count]; i++)
        {
        	DayContainer *original = (DayContainer*)[decoded objectAtIndex:i];
        	NSArray *splitStringFornight = [original.fortnight componentsSeparatedByString: @"-"];
        	
            //Handle case where there are two tithis in a single day.
            if ([splitStringFornight count] > 1)
            {
            	NSDateComponents *dayComponents = [gregorian components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:original.date];
            
            	NSArray *splitStringLunarmonth = [original.lunarMonth componentsSeparatedByString: @"-"];
                NSArray *splitStringTithi = [original.tithi componentsSeparatedByString: @"-"];
                NSArray *splitStringTithiStart = [original.tithiStart componentsSeparatedByString:@"-"];
                
                //Tithi start comes in format hh:mm, so must split on colon.
                NSArray *tithiOne = [[splitStringTithiStart objectAtIndex:0]componentsSeparatedByString:@":"];
                NSArray *tithiTwo = [[splitStringTithiStart objectAtIndex:1]componentsSeparatedByString:@":"];
                
                //Sometimes we don't get any tithi data.. so we handle that here.
                if ([tithiOne count] > 1)
                {
                	[dayComponents setHour: [[tithiOne objectAtIndex:0] intValue]];
                	[dayComponents setMinute: [[tithiOne objectAtIndex:1] intValue]];
                }
                
                //Clean up original day.
                original.fortnight = [splitStringFornight objectAtIndex:0];
                original.lunarMonth = [splitStringLunarmonth objectAtIndex:0];
                original.tithi = [splitStringTithi objectAtIndex:0];
                //original.date = [gregorian dateFromComponents:dayComponents];
                
                original.date = [formatter dateFromString:[NSString stringWithFormat:@"%i-%i-%i-%i-%i", [dayComponents day], [dayComponents month], [dayComponents year], [[tithiOne objectAtIndex:0]intValue], [[tithiOne objectAtIndex:1]intValue]]];
                
                //Next day.
                if ([tithiTwo count] > 1)
                {
                	dayComponents = [gregorian components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:original.date];
                	[dayComponents setHour: [[tithiTwo objectAtIndex:0] intValue]];
                	[dayComponents setMinute: [[tithiTwo objectAtIndex:1] intValue]];
                }
                
                DayContainer *nextDay = [[DayContainer alloc]init];
                
                nextDay.sunset = [original.sunset copy];
                nextDay.sunrise = [original.sunrise copy];
                nextDay.moonset = [original.moonset copy];
                nextDay.moonrise = [original.moonrise copy];
                
                nextDay.fortnight = [splitStringFornight objectAtIndex:1];
                nextDay.lunarMonth = [splitStringLunarmonth objectAtIndex:1];
                nextDay.tithi = [splitStringTithi objectAtIndex:1];


                //Make sure we format the dates correctly.
                nextDay.date = [formatter dateFromString:[NSString stringWithFormat:@"%i-%i-%i-%i-%i", [dayComponents day], [dayComponents month], [dayComponents year], [[tithiTwo objectAtIndex:0]intValue], [[tithiTwo objectAtIndex:1]intValue]]];
                
                
                [decoded insertObject:nextDay atIndex: i+1];
            }
            else
            {
            	//Correct the tithi start time.
                NSDateComponents *dayComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:original.date];
                
				//Tithi start comes in format hh:mm, so must split on colon.
                NSArray *tithiOne = [original.tithiStart componentsSeparatedByString:@":"];

				if ([tithiOne count] > 1)
                {
                	original.date = [formatter dateFromString:[NSString stringWithFormat:@"%i-%i-%i-%i-%i", [dayComponents day], [dayComponents month], [dayComponents year], [[tithiOne objectAtIndex:0]intValue], [[tithiOne objectAtIndex:1]intValue]]];
                }

            }
        }
        
        NSMutableArray *toRemove = [[NSMutableArray alloc]init];
        
        for(DayContainer *container in decoded) 
        {
        	//If we don't have data for something, let's make a human readable message.
            if ([container.fortnight isEqualToString:@"(null)"])
            	container.fortnight = @"(no data)";
                
            if ([container.lunarMonth isEqualToString:@"(null)"])
            	container.lunarMonth = @"(no data)";
                
            if ([container.tithi isEqualToString:@"(null)"])
            	container.tithi = @"(no data)";
                
            //If there isn't a tithi, format it nicely
            if ([container.fortnight isEqualToString:@"noPaksha"])
            	container.fortnight = @"(No Paksha)";
                
            if ([container.fortnight isEqualToString:@"none"])
            	[toRemove addObject:container];
            else
            	[self addDayToCache:container];
        
    		/*NSLog(@"Date: %@", container.date);
            NSLog(@"Sunrise: %@", container.sunrise);
            NSLog(@"Sunset: %@", container.sunset);
            NSLog(@"Moonrise: %@", container.moonrise);
            NSLog(@"Moonset: %@", container.moonset);
            NSLog(@"Fortnight: %@", container.fortnight);
            NSLog(@"LunarMonth: %@\n", container.lunarMonth);
            NSLog(@"Tithi: %@\n", container.tithi);
            NSLog(@"TithiStart: %@\n\n", container.tithiStart);*/
		}
        
        //Remove any days that contain "none"!
        for (DayContainer *containerToRemove in toRemove)
        	[decoded removeObject:containerToRemove];
        
        //Sort everything by date - this is the only location we're guranteed that
        //the data is sorted.
        [decoded sortUsingSelector:@selector(compare:)];
        
        //Loop through the days, and cache each month,
        /*NSDate *testDate = ((DayContainer*)[decoded objectAtIndex:0]).date;
        for (DayContainer *container in decoded)
        {
        	NSDateComponents *testComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:testDate];
        
        	NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:container.date];
        
        	if (testDate == ((DayContainer*)[decoded objectAtIndex:0]).date || [testComponents month] != [dateComponents month])
            {
            	testDate = container.date;
                
                [self writeCache:testDate];
                NSLog(@"Updating hard cache: %@", [testDate description]);
            }
        }*/
        
        [delegate didRecieveData:decoded];
        
        //return decoded;
    } 
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) 
    {
        NSLog(@"Failure: %@ With Response: %@", error, [response description]);
        
        NSString *usrMsg;
        
        if ([[error localizedDescription] isEqual: @"The Internet connection appears to be offline."])
        	usrMsg = @"The Internet connection appears to be offline.";
        else
        	usrMsg = @"API server internal error.";
        
        //Alert the user!
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:usrMsg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    
    	[alert show];
    }];
    
    
    //Actually send that bitch out there.
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

- (NSMutableArray *)parseJSONDateRange:(id)json
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
            
            newDay.tithiStart = [NSString stringWithFormat:@"%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.tithiStart", i]]];
    
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

- (void)registerAlertOnDate:(NSDate *)date withMessage:(NSString *)message
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

- (NSArray *)getAlertsOnDate:(NSDate *)date
{
	NSMutableArray *alerts = [[NSMutableArray alloc]init];
    
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:date];
    
    //Get ALL exisiting alerts.
    NSArray *existingAlerts = [[UIApplication sharedApplication]scheduledLocalNotifications];
    
    //Scan through, match day/month/year, if pass add to returned array.
    for (int i = 0; i < [existingAlerts count]; i++)
    {
    	UILocalNotification *notification = (UILocalNotification*)[existingAlerts objectAtIndex:i];
        
        NSDateComponents *alertComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit fromDate:notification.fireDate];
        
		if ([alertComponents year] == [dateComponents year] && 
            [alertComponents month] == [dateComponents month] &&
            [alertComponents day] == [dateComponents day])
        {
            [alerts addObject:notification];
        }
    }
    
    return alerts;
}

- (void)deregisterAlert:(UILocalNotification *)alert
{
	[[UIApplication sharedApplication] cancelLocalNotification:alert];
}

+ (void)saveSettings
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;

	//rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //plistPath = [rootPath stringByAppendingFormat:@"Settings.plist"]; 
    rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:sharedSingleton.settingsDictionary format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDesc];
    
    if(plistData) 
    {
        [plistData writeToFile:plistPath atomically:YES];
	} 
    else 
    {
    	NSLog(@"Error saving application state to plist: %@", errorDesc);
    }
}

+ (void)loadSettings
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;

	//rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //plistPath = [rootPath stringByAppendingFormat:@"Settings.plist"]; 
    
    rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) 
    	plistPath = [[NSBundle mainBundle] pathForResource:@"Settings"ofType:@"plist"];
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    NSDictionary *tempData = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    
    if (!tempData) 
    	NSLog(@"Error reading Settings plist: %@, format: %d", errorDesc, format);
        
    //Load settings.
    sharedSingleton.settingsDictionary = [[NSMutableDictionary alloc]initWithDictionary:tempData];
    
    NSLog(@"Settings: RemoteAPIEndpoint: %@", [sharedSingleton.settingsDictionary objectForKey:@"APIEndpoint"]);
    NSLog(@"Settings: SnapshotSunviewDate: %@", [[sharedSingleton.settingsDictionary objectForKey:@"Snapshot"] objectForKey:@"SunviewDate"]);
    
    //Log location data.
    NSLog(@"Settings: Latitude: %@", [[sharedSingleton.settingsDictionary objectForKey:@"Location"] objectForKey:@"Latitude"]);
    NSLog(@"Settings: Longitude: %@", [[sharedSingleton.settingsDictionary objectForKey:@"Location"] objectForKey:@"Longitude"]);
    NSLog(@"Settings: Altitude: %@", [[sharedSingleton.settingsDictionary objectForKey:@"Location"] objectForKey:@"Altitude"]);
}

- (int)addDayToCache:(DayContainer *)data
{
    int addedKey = -1;

	NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSDayCalendarUnit fromDate:[data date]];
    
    NSMutableDictionary *monthSet = [self retrieveMonthSetFromCache:[data date]];
    
    if (monthSet == nil) //Haven't cached this month yet - time to add it!
    {
    	//Create a new month index container.
        //MonthDataIndexer *newIndex = [MonthDataIndexer alloc];
    	//newIndex.date = [data date];
        //newIndex.dayCount = 1;
    
    	//newIndex.index = [dataCacheIndexer add:newIndex];
        
        NSMutableDictionary *newIndex = [[NSMutableDictionary alloc]init];
        [newIndex setObject:[data date] forKey:@"date"];
        [newIndex setObject:[[NSNumber numberWithInt:[dataCacheIndexer add:newIndex]] description] forKey:@"index"];
        
        addedKey = [[newIndex objectForKey:@"index"] intValue];
        
        NSMutableDictionary *newMonthSet = [[NSMutableDictionary alloc]init];
        //[sharedSingleton.dataCache setObject:newMonthSet forKey:[newIndex objectForKey:@"index"]];
        [dataCache setObject:newMonthSet forKey:[newIndex objectForKey:@"index"]];

        
        monthSet = newMonthSet;
    }
    
    //Add the day to the month set.
    [monthSet setObject:data forKey:[[NSNumber numberWithInt:[dateComponents day]] description]];
    
    //Update disk cache.
    [dataCacheIndexer writeToPList:@"cache_index.plist"];
    [self writeCache:data.date];
    
    return addedKey;
}

- (NSMutableDictionary *)retrieveMonthSetFromCache:(NSDate *)date
{
	int monthIndex = -1;
    
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	//MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
        NSDictionary *monthIndexC = (NSDictionary*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC objectForKey:@"date"]];
        
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

- (int)retrieveMonthIndexFromCache:(NSDate *)date
{
    NSDateComponents *dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:date];

	//Scan ringbuffer for matching month and year.
    NSArray *cachedMonthIndices = [dataCacheIndexer elements];
    for (int i = 0; i < [dataCacheIndexer count]; i++)
    {
    	//MonthDataIndexer *monthIndexC = (MonthDataIndexer*)[cachedMonthIndices objectAtIndex:i];
        NSDictionary *monthIndexC = (NSDictionary*)[cachedMonthIndices objectAtIndex:i];
    	
        NSDateComponents *indexComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] components:NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[monthIndexC objectForKey:@"date"]];
        
        if ([indexComponents year] == [dateComponents year] && [indexComponents month] == [dateComponents month])
        {
        	return i;
        }
    }
    
   	return -1;
}

- (DayContainer *)retrieveDayFromCache:(NSDate *)date
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

- (void)clearCache
{    
    //Clear out the actual cache.
    for (int i = 0; i < [dataCacheIndexer capacity]; i++)
    	[dataCache removeObjectForKey:[[NSNumber numberWithInt:i] description]];
    
    //Nuke index buffer.
	[dataCacheIndexer clear];
}

- (void) writeCache:(NSDate *)date
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;

	int monthIndex = -1; 
    monthIndex = [self retrieveMonthIndexFromCache:date];
    
    if (monthIndex < 0)
    	return; //Date doesn't exist in the cache, so we bail.

	rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dataCache_%i.plist", monthIndex]];
    
    //NSLog(@"PATH: %@", plistPath);
    
    NSDictionary *monthSet = [self retrieveMonthSetFromCache:date];
    NSMutableDictionary *encodedMonthSet = [[NSMutableDictionary alloc] init];
    
    NSArray *keys = [monthSet allKeys];
    
    //Can't directly serialize the DayContainer object, so we iterate over all the entires
    //in our monthSet, encode them as dictionaries using a helper method in DayContainer,
    //stick this in a new dictionary (so as not to destroy the one we're using as an
    //in-memory cache) and write that out.
    for (int i = 0; i < [keys count]; i++)
    {
        if ([[monthSet objectForKey:[keys objectAtIndex:i]] isKindOfClass:[DayContainer class]])
        {
        	DayContainer *container = [monthSet objectForKey:[keys objectAtIndex:i]];
    		NSDictionary *encodedDay = [container encodeAsDictionary];
    		[encodedMonthSet setObject:encodedDay forKey:[keys objectAtIndex: i]];
        }
    }
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:encodedMonthSet format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorDesc];
    
    if(plistData) 
    {
        [plistData writeToFile:plistPath atomically:YES];
	} 
    else 
    {
    	NSLog(@"Error writing cache for month at index %i: %@", monthIndex, errorDesc);
    }
}

- (void)loadCache
{
	NSString *plistPath;
    NSString *rootPath;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;

	//Clear out old data.
    [self clearCache];
	//Load index table first.
    [dataCacheIndexer loadFromPList:@"cache_index.plist"];

	//rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    //Loop over all the months that we might be caching, and attempt to deserialize them.
    //There's no gurantee that any given month will be cached (nothing says we've saved data out in
    //a serial fashion - this is expected behavior, but not enforced) so we need to expect
    //failures and keep on truckin'.
    for (int i = 0; i < [dataCacheIndexer capacity]; i++)
    {
    	//plistPath = [rootPath stringByAppendingFormat:@"dataCache_%i.plist", i]; 
        plistPath = [rootPath stringByAppendingPathComponent:[NSString stringWithFormat:@"dataCache_%i.plist", i]];
    
    	//if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) 
    		//plistPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat: @"dataCache_%i"]ofType:@"plist"];
    
    	NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    
    	NSMutableDictionary *tempData = (NSMutableDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&errorDesc];
    
    	if (!tempData) 
        {
    		NSLog(@"Unable to load cache data for month index %i: %@, format: %d",i, errorDesc, format);
        }
        else
        {
        	//Create a new dictionary, decode all the items in tempData using the DayContainer helper method,
            //store it in the new dictionary and set it as our in-memory cache.
            
            NSArray *keys = [tempData allKeys];
            NSMutableDictionary *decodedMonthSet = [[NSMutableDictionary alloc]init];
            
            for (int j = 0; j < [keys count]; j++)
            {
            	DayContainer *newDay = [[DayContainer alloc]init];
                [newDay decodeFromDictionary:[tempData objectForKey:[keys objectAtIndex:j]]];
            
            	[decodedMonthSet setObject:newDay forKey:[keys objectAtIndex:j]];
            }
        
        	[dataCache setObject:decodedMonthSet forKey:[[NSNumber numberWithInt:i] description]];
        }
    }
}

+ (void)locationUpdate:(CLLocation *)location
{
    //latitude = [location coordinate].latitude;
    //longitude = [location coordinate].longitude;
    //altitude = [location altitude];
    
    NSMutableDictionary *locationDictionary = [sharedSingleton.settingsDictionary objectForKey:@"Location"];
    
    //Check to see if there's a major change between the current location and the previous location.
    //If there's a major jump (this can happen if the app is closed, and then opened up say, after
    //a flight) then we alert the user that they have stale data.
    if (abs([[locationDictionary objectForKey: @"Latitude"] floatValue] - [location coordinate].latitude) > 2 ||
    	abs([[locationDictionary objectForKey: @"Longitude"] floatValue] - [location coordinate].longitude) > 2 ||
        abs([[locationDictionary objectForKey: @"Altitude"] floatValue] - [location altitude]) > 100)
        {
        	//Alert the user!
        	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location changed!" message:@"It seems that you've moved a fair bit since the last time you used the app. Your data might be outdated." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    
    		[alert show];
        }
    
    
    [locationDictionary setValue:[NSNumber numberWithDouble:[location coordinate].latitude] forKey:@"Latitude"];
    [locationDictionary setValue:[NSNumber numberWithDouble:[location coordinate].longitude] forKey:@"Longitude"];
    [locationDictionary setValue:[NSNumber numberWithDouble:[location altitude]] forKey:@"Altitude"];
    
    [MasterDataHandler saveSettings];
    
    NSLog(@"Location update [Latitude: %@, Longitude: %@, Altitude: %@]", 
    	[locationDictionary objectForKey:@"Latitude"],
        [locationDictionary objectForKey:@"Longitude"],
        [locationDictionary objectForKey:@"Altitude"]);
}
 
+ (void)locationError:(NSError *)error 
{
	NSLog(@"Location error: %@", [error description]);
}

@end
