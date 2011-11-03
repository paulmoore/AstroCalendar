//
//  AstroCalendarSelectDateViewController.m
//  AstroCalendar
//
//  Created by Paul Moore on 11-10-28.
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

#import "AstroCalendarSelectDateViewController.h"
#import "AstroCalendarMoonViewController.h"

@implementation AstroCalendarSelectDateViewController

@synthesize navController;

- (id)initWithNavController:(UINavigationController *)controller andIsEndDate:(BOOL)isEndDate
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
            [nextButton setTitle:@"View Calendar" forState:UIControlStateNormal];
        }
        else
        {
            self.title = @"Select Start Date";
            [nextButton setTitle:@"Next" forState:UIControlStateNormal];
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
        UIViewController *showResults = [[AstroCalendarMoonViewController alloc] init];
        [self.navController pushViewController:showResults animated:YES];
    }
    else
    {
        UIViewController *selectEndDate = [[AstroCalendarSelectDateViewController alloc] initWithNavController:self.navController andIsEndDate:YES];
        [self.navController pushViewController:selectEndDate animated:YES];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.navController = nil;
    datePicker = nil;
    yearField = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
