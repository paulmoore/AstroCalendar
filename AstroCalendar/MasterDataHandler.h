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

NSMutableDictionary *settingsDictionary;

@interface MasterDataHandler : NSObject

	//////////////////////////////////////////////////////////////
    // Properties												//
    //////////////////////////////////////////////////////////////
    
    // Target URL that API GET requests are sent to. Parameters will
    // be tagged on to the end of this before converting to an NSUrl.
	@property(copy) NSString *apiEndpoint;
    @property(copy) NSDate *snapshot_sunviewDate;



	
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
    
    
@end

