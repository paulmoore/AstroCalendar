//
//  SectionData.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-16.
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
 * A SectionData object is a simple data container for cached section data.
 *
 * @see AstroCalendarMoonViewController
 */
@interface SectionData : NSObject

/** The number of rows (lunar days) in this section. */
@property (readonly) int numRows;

/** The section number (lunar month). */
@property (readonly) int sectionNum;

@property (readonly) int startIndex;

/** The section name (lunar month name + year). */
@property (readonly, copy) NSString *sectionName;

/**
 * Inits this SectionData instance with the given section information.
 *
 * @param index The section number.
 * @param monthName The name of the lunar month.
 * @param monthYear The year (as an NSDate) of the lunar month.
 * @param rows The number of rows in this section.
 * @return An instance of SectionData initialized with the given information.
 */
- (id)initWithSectionNum:(int)index monthName:(NSString *)name monthYear:(NSDate *)year startIndex:(int)start;

- (void)addRow;

@end
