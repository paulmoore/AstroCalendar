//
//  MasterDataHandler.h
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

#import <Foundation/Foundation.h>
#import "../../AFNetworking/AFNetworking/AFNetworking.h"
#import "../../AFNetworking/AFNetworking/AFJSONRequestOperation.h"
#import "DayContainer.h"
#import "RingBuffer.h"
#import "MasterDataHandlerDelegate.h"
#import "CoreLocationControllerDelegate.h"

@interface MasterDataHandler : NSObject <CoreLocationControllerDelegate>

#pragma mark -
#pragma mark Properties

/** Stores a key-value index of all cached months. Each month is
	itself a dictionary. */    
@property(strong) NSMutableDictionary *dataCache;

/** Maintains an index into the dataCache for a particular month,
	so that a fixed number of months can be maintained at any 
    given time. */
@property(strong) RingBuffer *dataCacheIndexer;

/** Manages callbacks from CoreLocationServices for GPS updates. */
@property(strong) CoreLocationController *locationController;

/** Stores all global settings as a key-value pairing. */
@property(strong) NSMutableDictionary *settingsDictionary;

#pragma mark -
#pragma mark Class Methods

/**
 * Singleton access method.
 *
 * @see: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
 * @return Returns the instance of this singleton.
 */
+ (MasterDataHandler *)sharedManager;

/**
 * Saves applications settings to a Settings.plist file.
 */
+ (void)saveSettings;

/** 
 * Loads application settings from a Settings.plist file.
 */
+ (void)loadSettings;

/**
* Responds to CoreLocation updates, caching the most recent
* latitude, longitude, and altitude for our user. This data
* is required to make API calls for date information.
*/
+ (void)locationUpdate:(CLLocation *)location;
    
/**
* Responds to CoreLocation failed updates. This information
* is outputted to NSLog for debugging purposes, but is
* otherwise ignored (we keep the cached information around).
*/
+ (void)locationError:(NSError *)error;

#pragma mark -
#pragma mark Instance Methods


/**
 * Queries the data handler for the specified date range.
 * This method decides whether data can be retrived from the
 * cache or needs to be pulled fresh from the API.
 *
 * @param startDate The (inclusive) date to begin polling information.
 * @param endDate The (inclusive) date to stop polling information.
 */
-(void) getDates:(NSDate *) startDate endDate:(NSDate *)endDate delegate:(id<MasterDataHandlerDelegate>)delegate;
 
/**
 * Queries the API for the specified date range.
 *
 * @param startDate The (inclusive) date to begin polling information.
 * @param endDate The (inclusive) date to stop polling information.
 */
- (void)askApiForDates:(NSDate *)startDate endDate:(NSDate *)endDate delegate:(id<MasterDataHandlerDelegate>)delegate;
	
/**
 * Parses a JSON response from the API server to create a new
 * Day dataset. Returns an array containing all the days in
 * the JSON response.
 *
 * @return Returns an array of DayContainers representing the JSON response.
 */
- (NSMutableArray *)parseJSONDateRange:(id)json;
    
/**
 * Registers a customer alert (displaying the message) on the given
 * date (includes time).
 *
 * @param date The date to register the alert to.
 * @param message The message to register in the alert.
 */
- (void)registerAlertOnDate:(NSDate *)date withMessage:(NSString *)message;

    
/**
 * Adds a given day dataset to the cache. If the specified
 * month isn't already cached, it overrides the oldest cached
 * month.
 *
 * @param data The Day to cache.
 * @return Returns some unique identifier within the cache?
 */
- (int)addDayToCache:(DayContainer *)data;

/**
 * Retrieves a dictionary of cached days for a given month if
 * it exists, otherwise returns nil.
 *
 * @param date The month.
 * @return Returns a dictionary of Days keyed to their dates.
 */
- (NSMutableDictionary *)retrieveMonthSetFromCache:(NSDate *)date;

/**
 * Returns the cached information for a given date if it exists,
 * otherwise returns nil.
 *
 * @param date The date to retrieve.
 * @return Returns the DayContainer for the specified date.
 */
- (DayContainer *)retrieveDayFromCache:(NSDate *)date;

/**
 * Retrives the index for the specified month within the cache.
 *
 * @param date The month.
 * @return Returns the index of the specified month within the cache.
 */
- (int)retrieveMonthIndexFromCache:(NSDate *)date;

/**
 * Nuke the entire cash - we can leave plists, they'll get
 * overridden anyway.
 */
- (void)clearCache;
    
/**
* Writes the month set of data for the given index to a
* plist on the device.
*/
- (void)writeCache:(NSDate*)date;

/**
* Reads in the entire cache from plists on disk, and puts
* them in to the in-memory cache.
*/
- (void)loadCache;
    
/**
* Lists all the alerts that this application has registered
* on a particular date (unique Day, Month, Year).
*
* @param date The day/month/year on which to get the list of registered alerts.
* @return An array of alerts scheduled on the given date. This array might be empty if no alerts are scheduled.
*/
- (NSArray *)getAlertsOnDate:(NSDate *)date;
    
/**
 * Unregisters the given alert.
 *
 * @param alert The local notification to unregister.
 */
- (void)deregisterAlert:(UILocalNotification *)alert;
    
@end
