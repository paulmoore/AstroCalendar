//
//  AstroCalendarSelectDateViewController.m
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

#import "AstroCalendarSelectDateViewController.h"
#import "AstroCalendarMoonViewController.h"
#import "AstroCalendarSunViewController.h"
#import "AstroCalendarHelpViewController.h"
#import "MasterDataHandler.h"
#import "DateRangeRequest.h"
#import "UINavigationController+UniqueStack.h"

@implementation AstroCalendarSelectDateViewController

@synthesize navController, startDate;

- (id)initWithNavController:(UINavigationController *)controller andIsEndDate:(BOOL)isEndDate givenStartDate:(NSDate*)givenStartDate
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self = [super initWithNibName:@"AstroCalendarSelectDateViewController_iPhone" bundle:nil];
    }
    else
    {
        self = [super initWithNibName:@"AstroCalendarSelectDateViewController_iPad" bundle:nil];
    }
    if (self)
    {
        isSelectEnd = isEndDate;
        if (isEndDate)
        {
            self.title = @"Select End Date";
            self.startDate = givenStartDate;
        }
        else
        {
            self.title = @"Select Start Date";
        }
        self.navController = controller;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - IBAction listeners

- (IBAction)didSelectNext:(id)sender
{
    if (isSelectEnd)
    {
        // Display the Moon Calendar, and make a request for the selected data.
        AstroCalendarMoonViewController *moonController = (AstroCalendarMoonViewController *)[self.navController pushUniqueControllerOfType:[AstroCalendarMoonViewController class] animated:YES];
        if (!moonController)
        {
            moonController = [[AstroCalendarMoonViewController alloc] init];
            [self.navController pushViewController:moonController animated:YES];
        }
        // Make the Date request: start date -> end date.
        DateRangeRequest *request = [[DateRangeRequest alloc] initWithStartDate:self.startDate endDate:[datePicker date]];
        // Don't attempt to load a 'backwards' time interval.
        if ([request numDays] > 0)
        {
            [moonController loadDates:request];
        }
    }
    else
    {
        // We don't want to check if a select date controller is already in the nav stack, because there should be one for each date in the interval.
        AstroCalendarSelectDateViewController *selectEndDate = [[AstroCalendarSelectDateViewController alloc] initWithNavController:self.navController andIsEndDate:YES givenStartDate:[datePicker date]];
        [self.navController pushViewController:selectEndDate animated:YES];
        // Let the end date selector know what start date was selected.
        //selectEndDate.startDate = [datePicker date];
    }
}

#pragma mark - Toolbar Button Actions

- (void)didSelectSunCalendarFromToolbar
{
    if (! [self.navController pushUniqueControllerOfType:[AstroCalendarSunViewController class] animated:YES])
    {
        UIViewController *sunController = [[AstroCalendarSunViewController alloc] initWithNavController:self.navController];
        [self.navController pushViewController:sunController animated:YES];
    }
}

- (void)didSelectMoonCalendarFromToolbar
{
    if (! [self.navController pushUniqueControllerOfType:[AstroCalendarMoonViewController class] animated:YES])
    {
        UIViewController *moonController = [[AstroCalendarMoonViewController alloc] initWithNavController:self.navController];
        [self.navController pushViewController:moonController animated:YES];
    }
}

- (void)didSelectHelpFromToolbar
{
    if (! [self.navController pushUniqueControllerOfType:[AstroCalendarHelpViewController class] animated:YES])
    {
        UIViewController *helpController = [[AstroCalendarHelpViewController alloc] initWithNavController:self.navController];
        [self.navController pushViewController:helpController animated:YES];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (isSelectEnd)
    {
        [nextButton setTitle:@"View Calendar" forState:UIControlStateNormal];
        
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *maximumDateOffset = [[NSDateComponents alloc]init];
        
        //Due to an API limitation, we can only successfuly retrieve an interval of 3 months.
        [maximumDateOffset setMonth: 3];
        [datePicker setMaximumDate: [gregorian dateByAddingComponents: maximumDateOffset toDate: startDate options:0]];
        [datePicker setMinimumDate: startDate]; //We don't want to count backwards in time!
    }
    else
    {
        [nextButton setTitle:@"Select End Date" forState:UIControlStateNormal];
    }
    
    UIBarButtonItem *moonButton = [[UIBarButtonItem alloc] initWithTitle:@"Moon Calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectMoonCalendarFromToolbar)];
    UIBarButtonItem *sunButton = [[UIBarButtonItem alloc] initWithTitle:@"Sun Calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectSunCalendarFromToolbar)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectHelpFromToolbar)];
    NSArray *barButtons = [NSArray arrayWithObjects:moonButton, sunButton, helpButton, nil];
    [self setToolbarItems:barButtons animated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.navController = nil;
    datePicker = nil;
    nextButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
