//
//  AstroCalendarDayViewController.m
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-02.
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

#import "AstroCalendarDayViewController.h"
#import "AstroCalendarMoonViewController.h"
#import "AstroCalendarSunViewController.h"
#import "AstroCalendarHelpViewController.h"
#import "AstroCalendarSelectDateViewController.h"
#import "MasterDataHandler.h"
#import "UINavigationController+UniqueStack.h"

static dispatch_once_t pred = 0;
__strong static NSDateFormatter *formatter = nil;

@implementation AstroCalendarDayViewController

@synthesize navController, date;

- (id)initWithNavController:(UINavigationController *)controller
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        self = [super initWithNibName:@"AstroCalendarDayViewController_iPhone" bundle:nil];
    }
    else
    {
        self = [super initWithNibName:@"AstroCalendarDayViewController_iPad" bundle:nil];
    }
    if (self)
    {
        self.navController = controller;
        self.title = @"Day Details";
    }
    return self;
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)displayDate:(NSDate *)theDate
{
    self.date = theDate;
    if ([self isViewLoaded])
    {
        [[MasterDataHandler sharedManager] askApiForDates:self.date endDate:self.date delegate:self];
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

- (void)didSelectSelectDatesFromToolbar
{
    if (! [self.navController pushUniqueControllerOfType:[AstroCalendarSelectDateViewController class] animated:YES])
    {
        UIViewController *selectController = [[AstroCalendarSelectDateViewController alloc] initWithNavController:self.navController andIsEndDate:NO givenStartDate:nil];
        [self.navController pushViewController:selectController animated:YES];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *moonButton = [[UIBarButtonItem alloc] initWithTitle:@"Moon Calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectMoonCalendarFromToolbar)];
    UIBarButtonItem *sunButton = [[UIBarButtonItem alloc] initWithTitle:@"Sun Calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectSunCalendarFromToolbar)];
    UIBarButtonItem *selectButton = [[UIBarButtonItem alloc] initWithTitle:@"Select Dates" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectSelectDatesFromToolbar)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectHelpFromToolbar)];
    NSArray *buttons = [NSArray arrayWithObjects:moonButton, sunButton, selectButton, helpButton, nil];
    [self setToolbarItems:buttons animated:YES];
    
    if (self.date)
    {
        [[MasterDataHandler sharedManager] askApiForDates:self.date endDate:self.date delegate:self];
    }
}

- (void)didRecieveData:(NSArray *)data
{
    dispatch_once(&pred, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"hh:mm a"];
    });
        
    DayContainer *day = (DayContainer *)[data firstObject];
    sunriseLabel.text = [formatter stringFromDate:day.sunrise];
    sunsetLabel.text = [formatter stringFromDate:day.sunset];
    moonriseLabel.text = [formatter stringFromDate:day.moonrise];
    moonsetLabel.text = [formatter stringFromDate:day.moonset];

    static dispatch_once_t pred2 = 0;
    __strong static NSDateFormatter *titleFormatter = nil;
    dispatch_once(&pred2, ^{
        titleFormatter = [[NSDateFormatter alloc] init];
        [titleFormatter setDateStyle:NSDateFormatterMediumStyle];
        [titleFormatter setTimeStyle:NSDateFormatterNoStyle];
    });
    dateLabel.text = [titleFormatter stringFromDate:self.date];
    self.date = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.navController = nil;
    self.date = nil;
    sunsetLabel = nil;
    sunriseLabel = nil;
    moonsetLabel = nil;
    moonriseLabel = nil;
    dateLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
