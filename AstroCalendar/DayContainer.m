//
//  DayContainer.m
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

#import "DayContainer.h"

@implementation DayContainer

@synthesize date;
@synthesize sunrise;
@synthesize sunset;
@synthesize moonrise;
@synthesize moonset;
@synthesize tithi;
@synthesize fortnight;
@synthesize lunarMonth;
@synthesize tithiStart;

- (NSDictionary *)encodeAsDictionary
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
    [dict setValue:[self date] forKey:@"date"];
    [dict setValue:[self sunrise] forKey:@"sunrise"];
    [dict setValue:[self sunset] forKey:@"sunset"];
    [dict setValue:[self moonrise] forKey:@"moonrise"];
    [dict setValue:[self moonset] forKey:@"moonset"];
    [dict setValue:[self tithi] forKey:@"tithi"];
    [dict setValue:[self fortnight] forKey:@"fortnight"];
    [dict setValue:[self lunarMonth] forKey:@"lunarmonth"];
    [dict setValue:[self tithiStart] forKey:@"tithistart"];
        
    return dict;
}

- (void)decodeFromDictionary:(NSDictionary *)dictionary
{
    self.date = [dictionary objectForKey:@"date"];
    self.sunrise = [dictionary objectForKey:@"sunrise"];
    self.sunset = [dictionary objectForKey:@"sunset"];
    self.moonrise = [dictionary objectForKey:@"moonrise"];
    self.moonset = [dictionary objectForKey:@"moonset"];
    self.tithi = [dictionary objectForKey:@"tithi"];
    self.fortnight = [dictionary objectForKey:@"fortnight"];
    self.lunarMonth = [dictionary objectForKey:@"lunarmonth"];
    self.tithiStart = [dictionary objectForKey:@"tithistart"];
}

-(NSComparisonResult)compare:(DayContainer *)container 
{    
    return [self.date compare:container.date];
}

@end
