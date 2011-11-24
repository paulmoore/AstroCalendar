//
//  MasterDataHandler.h
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

#import <Foundation/Foundation.h>
#import "../../AFNetworking/AFNetworking/AFNetworking.h"
#import "../../AFNetworking/AFNetworking/AFJSONRequestOperation.h"
#import "DayContainer.h"
#import "RingBuffer.h"
#import "MonthDataIndexer.h"
#import "MasterDataHandlerDelegate.h"

NSMutableDictionary *settingsDictionary;

@interface MasterDataHandler : NSObject
{
    @private
    double longitude, latitude;
}

    #pragma mark -
    #pragma mark Properties
    
    //@property(strong) NSMutableDictionary *dataCache;

    #pragma mark -
    #pragma mark Class Methods

    /**
     * Singleton access method.
     *
     * @see: https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/CocoaObjects.html#//apple_ref/doc/uid/TP40002974-CH4-SW32
     * @return Returns the instance of this singleton.
     */
    +(MasterDataHandler *)sharedManager;

    #pragma mark -
    #pragma mark Instance Methods

	+(RingBuffer*) getDataCacheIndexer;
    +(void) setDataCacheIndexer:(RingBuffer *)dataCacheIndexer;
    
    +(NSMutableDictionary*) getDataCache;
    +(void) setDataCache:(NSMutableDictionary *)dictionary;

    /**
     * Queries the data handler for the specified date range.
     *
     * @param startDate The (inclusive) start date to begin polling information.
     * @param endDate The (inclusive) end date to stop polling information.
     */
    -(void)askApiForDates:(NSDate *)startDate endDate:(NSDate *)endDate delegate:(id<MasterDataHandlerDelegate>)delegate;
	
    /**
     * Parses a JSON response from the API server to create a new
     * Day dataset. Returns an array containing all the days in
     * the JSON response.
     *
     * @return Returns an array of DayContainers representing the JSON response.
     */
    -(NSArray*)parseJSONDateRange: (id)json;
    
    /**
     * Registers a customer alert (displaying the message) on the given
     * date (includes time).
     *
     * @param date The date to register the alert to.
     * @param message The message to register in the alert.
     */
    -(void)registerAlertOnDate: (NSDate*) date: (NSString*) message;

    /**
     * Saves applications settings to a Settings.plist file.
     */
    -(void)saveSettings;

    /** 
     * Loads application settings from a Settings.plist file.
     */
    -(void)loadSettings;
    
    /**
     * Adds a given day dataset to the cache. If the specified
     * month isn't already cached, it overrides the oldest cached
     * month.
     *
     * @param data The Day to cache.
     * @return Returns some unique identifier within the cache?
     */
	-(int)addDayToCache: (DayContainer*) data;

    /**
     * Retrieves a dictionary of cached days for a given month if
     * it exists, otherwise returns nil.
     *
     * @param date The month.
     * @return Returns a dictionary of Days keyed to their dates.
     */
    -(NSMutableDictionary*)retrieveMonthSetFromCache: (NSDate*) date;

    /**
     * Returns the cached information for a given date if it exists,
     * otherwise returns nil.
     *
     * @param date The date to retrieve.
     * @return Returns the DayContainer for the specified date.
     */
    -(DayContainer*)retrieveDayFromCache: (NSDate*) date;

    /**
     * Retrives the index for the specified month within the cache.
     *
     * @param date The month.
     * @return Returns the index of the specified month within the cache.
     */
    -(int)retrieveMonthIndexFromCache:(NSDate*)date;

    /**
     * Nuke the entire cash - we can leave plists, they'll get
     * overridden anyway.
     */
    -(void)clearCache;
    
    /**
     * Writes the month set of data for the given index to a
     * plist on the device.
     */
    -(void)writeCache: (NSDate*)date;

    /**
     * Reads in the entire cache from plists on disk, and puts
     * them in to the in-memory cache.
     */
    -(void)loadCache;
    
@end
