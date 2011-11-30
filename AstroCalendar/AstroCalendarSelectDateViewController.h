//
//  AstroCalendarSelectDateViewController.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-10-28.
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
 * View Controller for selecting a day.
 * Has functionality for selecting either a 'start date' or 'end date' to obtain a date range.
 */
@interface AstroCalendarSelectDateViewController : UIViewController
{
    IBOutlet UIDatePicker *datePicker;
    
    IBOutlet UIButton *nextButton;
    
    BOOL isSelectEnd;
}

/** Parent Navigation Controller. */
@property (nonatomic, weak) UINavigationController *navController;

@property (nonatomic, weak) NSDate *startDate;

/**
 * Inits an AstroCalendarSelectDateViewController with a parent Navigation Controller.
 *
 * @param controller The parent Navigation Controller.
 * @param isEndDate Wether or not this view represents selecting an 'end date'.
 * @param givenStartDate Used as a starting point for the maximum and minimum date that
 *		  can be selected if this view represents selecting an 'end date'.
 * @return An instance of AstroCalendarSelectDateViewController.
 */
- (id)initWithNavController:(UINavigationController *)controller andIsEndDate:(BOOL)isEndDate givenStartDate:(NSDate*)givenStartDate;

/**
 * Selector for when the user selects the the 'Next' button.
 * Depending on if this is an 'end date' controller, either transitions to another date selector, or a moon calendar.
 * @param sender The sender of the event.
 * @return nil.
 */
- (IBAction)didSelectNext:(id)sender;

/**
 * Selector for when the 'Sun Calendar' Toolbar button is tapped.
 * Transitions to the AstroCalendarSunViewController.
 */
- (void)didSelectSunCalendarFromToolbar;

/**
 * Selector for when the 'Moon Calendar' Toolbar button is tapped.
 * Transitions to the AstroCalendarMoonViewController.
 */
- (void)didSelectMoonCalendarFromToolbar;

/**
 * Selector for when the 'Help' Toolbar button is tapped.
 * Transitions to Help (not yet implemented).
 */
- (void)didSelectHelpFromToolbar;

@end
