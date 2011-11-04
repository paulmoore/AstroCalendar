//
//  MasterDataHandler.m
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-01.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import "MasterDataHandler.h"

@implementation MasterDataHandler

static MasterDataHandler *sharedSingleton = nil;

@synthesize apiEndpoint;

static double longitude, latitude;


// Singleton pattern initializer. There should only ever be ONE instance of MasterDataHandler
// available to the application, so that only a single entry point to the data is visible.
// @see: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
+ (MasterDataHandler*)sharedManager
{
    if (sharedSingleton == nil) 
    {
        sharedSingleton = [[super allocWithZone:NULL] init];
        
        //TODO: This should get loaded from a config file - NOT hardcoded.
        sharedSingleton.apiEndpoint =  @"http://localhost/apitest/api.php";
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
 
- (void)release
{
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
    [dateFormatter setDateFormat:@"MM-dd-yyyy"];
	
	//Builds up our URL request string.
	NSString *urlString = [NSString stringWithFormat:@"%@?requestType=all,startDate=%@,endDate=%@,latitude=%d,longitude=%d", sharedSingleton.apiEndpoint, [dateFormatter stringFromDate:startDate], [dateFormatter stringFromDate:endDate], latitude, longitude];
    
    NSLog(urlString);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    
    
    //Build the async request.
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) 
    {
    	NSLog(@"Success!");
        
        NSArray *decoded = [MasterDataHandler parseJSONDateRange: JSON];
        
        for(DayContainer *container in decoded) 
        {
    		NSLog(@"Date: %@", container.date);
            NSLog(@"Sunrise: %@", container.sunrise);
            NSLog(@"Sunset: %@", container.sunset);
            NSLog(@"Moonrise: %@", container.moonrise);
            NSLog(@"Moonset: %@", container.moonset);
            NSLog(@"Fortnight: %@", container.fortnight);
            NSLog(@"LunarMonth: %@\n", container.lunarMonth);
		}
        
        
    } 
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) 
    {
        NSLog(@"Failure: %@", error);
    }];
    
    
    //Actually send that bitch out there.
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:operation];
}



-(NSArray*)parseJSONDateRange: (id)json
{
	int dayCount = [[json valueForKeyPath:@"count"] intValue];
    
    //Helps us out for conversion to NSDates.
    NSCalendar *helperCalendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    
    //Formatting for storing times.
    NSDateFormatter *helperFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [helperFormatter setDateFormat:@"MM-dd-yyyyHH-mm-ss"];
    
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
        
        	newDay.sunrise = [NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.sunrise", i]]];
        
        	newDay.sunset = [NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.sunset", i]]];
        
        	newDay.moonrise = [NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.moonrise", i]]];
        
        	newDay.moonset = [NSString stringWithFormat:@"01-01-2000%@", [json valueForKeyPath:[NSString stringWithFormat:@"%i.payload.moonset", i]]];
        
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
	
}

-(void) loadSettings
{
}


@end
