//
//  AstroCalendarMoonViewController.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-01.
//  Copyright (c) 2011 University of British Columbia. All rights reserved.
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
 * View Controller for a Moon Calendar.
 * Displays information such as 'start time', 'tithi', and 'paksha' in a table view.
 */
@interface AstroCalendarMoonViewController : UITableViewController

/** Parent view controller. */
@property (nonatomic, weak) UINavigationController *navController;

/**
 * Inits an AstroCalendarMoonViewController with a parent Navigation Controller.
 *
 * @param controller The parent Navigation Controller.
 * @return An instance of AstroCalendarMoonViewController.
 */
- (id)initWithNavController:(UINavigationController *)controller;

/**
 * Selector for when the 'Sun Calendar' button is taped from the Toolbar.
 * Transitions to the Sun Calendar view.
 */
- (void)didSelectSunCalendarFromToolbar;

/**
 * Selector for when the 'Option's button is taped from the Toolbar.
 * Transitions to Options (not yet implemented).
 */
- (void)didSelectOptionsFromToolbar;

@end