//
//  MasterDataHandler.h
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-01.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFJSONRequestOperation.h"
#import "DayContainer.h"
#import "RingBuffer.h"
#import "MonthDataIndexer.h"

NSMutableDictionary *settingsDictionary;

@interface MasterDataHandler : NSObject

	//////////////////////////////////////////////////////////////
    // Properties												//
    //////////////////////////////////////////////////////////////
    @property(assign) NSMutableDictionary *dataCache;
    @property(assign) RingBuffer *dataCacheIndexer;

	
    //////////////////////////////////////////////////////////////
    // Class Methods											//
    //////////////////////////////////////////////////////////////
    
    //Returns an array of DayContainer objects with their populated
    //data.
    //
    //startDate: The (inclusive) start date to begin polling information.
    //endDate: The (inclusive) end date to stop polling information.
	//-(NSArray*)getDateRange:(NSDate*)startDate: (NSDate*)endDate;




	
    //////////////////////////////////////////////////////////////
    // Instance Methods											//
    //////////////////////////////////////////////////////////////
    
    //Asynchronously asks the API for missing data. Fills in the
    //data cache, and sets up a delegate to return the results
    //as necessary.
	-(void)askApiForDates:(NSDate*) startDate: (NSDate*) endDate;
	
    -(NSArray*)parseJSONDateRange: (id)json;
    
    -(void)registerAlertOnDate: (NSDate*) date: (NSString*) message;

    -(void)saveSettings;
    -(void)loadSettings;
    
	-(int)addDayToCache: (DayContainer*) data;
    -(NSMutableDictionary*)retrieveMonthSetFromCache: (NSDate*) date;
    -(DayContainer*)retrieveDayFromCache: (NSDate*) date;
    -(int)retrieveMonthIndexFromCache:(NSDate*)date;
    -(void)clearCache;
    
    -(void)writeCache: (NSDate*)date;
    -(void)loadCache;
    
@end

