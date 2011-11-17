//
//  MonthDataIndexer.h
//  HTTPRequestTest
//
//  Created by Stephen Smithbower on 11-11-14.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MonthDataIndexer : NSObject

	@property(copy) NSDate *date;
    @property(copy) NSDate *cachedDate;
    @property int index;
    @property int dayCount;

@end
