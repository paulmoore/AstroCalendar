//
//  DayContainer.h
//  AstroCalendar
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

/**
 * A DayContainer contains all necessary data for a given gregorian calendar day.
 */
@interface DayContainer : NSObject

/** The date this container represents. */
@property(copy) NSDate *date;
/** The sunrise for this day. */
@property(copy) NSDate *sunrise;
/** The sunset for this day. */
@property(copy) NSDate *sunset;
/** The moonrise for this day. */
@property(copy) NSDate *moonrise;
/** The moonset for this day. */
@property(copy) NSDate *moonset;
/** The tithi (lunar day) of this day. */
@property(copy) NSString *tithi;
/** The fortnight (paksha) of this day. */
@property(copy) NSString *fortnight;
/** The lunar month (nakshatra) of this day. */
@property(copy) NSString *lunarMonth;
/** The time when a second tithi starts (on the same day) **/
@property(copy) NSString *tithiStart;


/**
 * Encodes the properties of this instance as a NSDictionary,
 * where the keys are the string names of the properties.
 *
 * @return An NSDictionary containing all the properties of this instance of DayContainer.
 */
- (NSDictionary *)encodeAsDictionary;

/**
 * Populates this instance's properties with values from an
 * NSDictionary. Each property name is a key in the dictionary.
 *
 * @param dictionary The NSDictionary containing the key-value representation of the DayContainer instance.
 */
- (void)decodeFromDictionary: (NSDictionary *)dictionary;

/**
 * Compares two DayContainers based on their date property.
 * When sorting an array, the order will be oldest date to
 * newest date (or, past -> future).
 *
 * @param container The container the compare this one to.
 */
-(NSComparisonResult)compare:(DayContainer *)container;
    
@end
