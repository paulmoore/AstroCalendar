//
//  DateRangeRequest.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-18.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateRangeRequest : NSObject

@property (nonatomic, strong) NSDate *startDate, *endDate;

- (id)initWithStartDate:(NSDate *)start endDate:(NSDate *)end;

- (int)numDays;

- (void)clear;

@end
