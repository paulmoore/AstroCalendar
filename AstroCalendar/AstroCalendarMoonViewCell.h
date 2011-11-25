//
//  AstroCalendarMoonViewCell.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-01.
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

#import <UIKit/UIKit.h>

/**
 * View for a table cell in an AstroCalendarMoonViewController (the moon calendar).
 */
@interface AstroCalendarMoonViewCell : UITableViewCell
{
    IBOutlet UILabel *dateLabel, *tithiLabel, *fortnightLabel;
}

/** The Activity Indicator which spins when waiting for data from the server. */
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

/**
 * @return The cell height for each AstroCalendarMoonViewCell.
 */
+ (CGFloat)cellHeight;

/**
 * Configure's this cell with the appropriate data to be displayed.
 *
 * @param date The start date of the tithi.
 * @param tithi The name of the tithi.
 * @param fortnight The lunar fortnight (paksha).
 */
- (void)configureWithDate:(NSDate *)date tithi:(NSString *)tithi fortnight:(NSString *)fortnight;

@end
