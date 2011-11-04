//
//  DayContainer.h
//  AstroCalendar
//
//  Created by Stephen Smithbower on 11-11-01.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DayContainer : NSObject

	@property(copy) NSDate *date;
	@property(copy) NSDate *sunrise;
	@property(copy) NSDate *sunset;
	@property(copy) NSDate *moonrise;
	@property(copy) NSDate *moonset;
    @property(copy) NSString *tithi;
    @property(copy) NSString *fortnight;
    @property(copy) NSString *lunarMonth;

@end
