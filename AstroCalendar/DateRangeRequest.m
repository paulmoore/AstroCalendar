//
//  DateRangeRequest.m
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-18.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import "DateRangeRequest.h"

@implementation DateRangeRequest

@synthesize startDate, endDate;

- (id)initWithStartDate:(NSDate *)start endDate:(NSDate *)end
{
    self = [super init];
    if (self)
    {
        self.startDate = start;
        self.endDate = end;
    }
    return self;
}

- (int)numDays
{
    NSTimeInterval interval = [self.endDate timeIntervalSinceDate:self.startDate];
    return interval/60/60/24;
}

- (void) clear
{
    self.startDate = nil;
    self.endDate = nil;
}

@end
