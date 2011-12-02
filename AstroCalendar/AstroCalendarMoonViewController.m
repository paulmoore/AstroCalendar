//
//  AstroCalendarMoonViewController.m
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

#import "AstroCalendarMoonViewController.h"
#import "AstroCalendarMoonViewCell.h"
#import "AstroCalendarDayViewController.h"
#import "AstroCalendarSunViewController.h"
#import "AstroCalendarSelectDateViewController.h"
#import "AstroCalendarHelpViewController.h"
#import "UINavigationController+UniqueStack.h"
#import "DateRangeRequest.h"
#import "MasterDataHandler.h"
#import "DayContainer.h"
#import "SectionData.h"

@implementation AstroCalendarMoonViewController

@synthesize navController, lunarData, sectionsData, dateRequest;

- (id)initWithNavController:(UINavigationController *)controller
{
    self = [super init];
    if (self)
    {
        // Custom initialization
        self.navController = controller;
        self.title = @"Moon Calendar";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)loadDates:(DateRangeRequest *)request
{
    self.dateRequest = request;
    self.lunarData = nil;
    
    // If the view has been loaded, make the request.
    if ([self isViewLoaded])
    {
        [self.tableView reloadData];
        [[MasterDataHandler sharedManager] getDates:request.startDate endDate:request.endDate delegate:self];
    }
}

- (void)didRecieveData:(NSArray *)data
{
    // Delegate was called after this view was unloaded, return.
    if (![self isViewLoaded])
    {
        return;
    }
    
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:2];
    
    // Insert the appropriate sections based on the lunar months.
    int index = 0;
    NSString *currentMonth = nil;
    SectionData *currentSection = nil;
    for (DayContainer *day in data)
    {
        NSString *nextMonth = day.lunarMonth;
        // We need to add a new section if we have reached a new lunar month.
        if (!currentMonth || ![currentMonth isEqualToString:nextMonth])
        {
            currentSection = [[SectionData alloc] initWithSectionNum:[sections count] monthName:nextMonth monthYear:day.date startIndex:index];
            [sections addObject:currentSection];
            currentMonth = nextMonth;
        }
        // Add a row to whatever the current section is.
        [currentSection addRow];
        index++;
    }
    self.sectionsData = sections;
    
    // Set the data we recieved from the data handler.
    self.lunarData = data;
    
    [self.tableView reloadData];
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

- (void)didSelectSelectDatesFromToolbar
{
    if (! [self.navController pushUniqueControllerOfType:[AstroCalendarSelectDateViewController class] animated:YES])
    {
        UIViewController *selectController = [[AstroCalendarSelectDateViewController alloc] initWithNavController:self.navController andIsEndDate:NO givenStartDate:nil];
        [self.navController pushViewController:selectController animated:YES];
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

- (void)didSelectRefreshFromToolbar
{
    [[MasterDataHandler sharedManager] clearCache];
    if (self.dateRequest)
    {
        [self loadDates:self.dateRequest];
    }
    else
    {
        NSDate *today = [NSDate date];
        NSDate *oneMonthFromToday = [today dateByAddingDays:31];
        DateRangeRequest *request = [[DateRangeRequest alloc] initWithStartDate:today endDate:oneMonthFromToday];
        [self loadDates:request];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Setup this View Controller's Toolbar.
    UIBarButtonItem *sunButton = [[UIBarButtonItem alloc] initWithTitle:@"Sun Calendar" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectSunCalendarFromToolbar)];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"Help" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectHelpFromToolbar)];
    UIBarButtonItem *selectDatesButton = [[UIBarButtonItem alloc] initWithTitle:@"Select Dates" style:UIBarButtonItemStyleBordered target:self action:@selector(didSelectSelectDatesFromToolbar)];
    NSArray *barButtons = [NSArray arrayWithObjects:sunButton, selectDatesButton, helpButton, nil];
    [self setToolbarItems:barButtons animated:YES];
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(didSelectRefreshFromToolbar)];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    if (self.dateRequest)
    {
        [[MasterDataHandler sharedManager] getDates:self.dateRequest.startDate endDate:self.dateRequest.endDate delegate:self];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.navController = nil;
    self.lunarData = nil;
    self.sectionsData = nil;
    if (self.dateRequest)
    {
        [self.dateRequest clear];
        self.dateRequest = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSArray *sections = self.sectionsData;
    if (sections)
    {
        return [sections count];
    }
    // Return 1, the sections are added dynamically when the data is loaded.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSArray *sections = self.sectionsData;
    if (sections)
    {
        SectionData *sectionData = [sections objectAtIndex:section];
        return sectionData.numRows;
    }
    // Approximate the number of days if a request has been been made.
    if (self.dateRequest)
    {
        return [self.dateRequest numDays];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AstroCalendarMoonViewCell";
    
    // Reuse, or create, a new cell.
    AstroCalendarMoonViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
    {
        NSString *nibName;
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        {
            nibName = @"AstroCalendarMoonViewCell_iPhone";
        }
        else
        {
            nibName = @"AstroCalendarMoonViewCell_iPad";
        }
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        cell = [nibObjects objectAtIndex:0];
    }
    
    // Configure the cell...
    NSArray *data = self.lunarData;
    if (data)
    {
        int dataIndex = ((SectionData *)[self.sectionsData objectAtIndex:indexPath.section]).startIndex + indexPath.row;
        DayContainer *day = (DayContainer *)[data objectAtIndex:dataIndex];
        [cell configureWithDate:day.date tithi:day.tithi fortnight:day.fortnight];
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    // TODO View Moon Day details?
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *sections = self.sectionsData;
    if (sections)
    {
        SectionData *sectionData = [sections objectAtIndex:section];
        return sectionData.sectionName;
    }
    return @"(Loading...)";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [AstroCalendarMoonViewCell cellHeight];
}

@end
