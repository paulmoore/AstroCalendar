//
//  AstroCalendarMoonViewCell.m
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

#import "AstroCalendarMoonViewCell.h"

@implementation AstroCalendarMoonViewCell

@synthesize activityIndicator;

+ (CGFloat)cellHeight
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        return 44.0;
    }
    return 88.0;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (void)prepareForReuse
{
    dateLabel.text = @"";
    tithiLabel.text = @"";
    fortnightLabel.text = @"";
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self.activityIndicator startAnimating];
}

- (void)configureWithDate:(NSDate *)date tithi:(NSString *)tithi fortnight:(NSString *)fortnight
{
    static dispatch_once_t pred = 0;
    __strong static NSDateFormatter *formatter = nil;
    dispatch_once(&pred, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yy hh:mm a"];
    });
    // Display the cell data for the Moon Day.
    dateLabel.text = [formatter stringFromDate:date];
    tithiLabel.text = tithi;
    fortnightLabel.text = fortnight;
    
    if ([fortnight isEqualToString:@"Full Moon"])
    {
        self.contentView.backgroundColor = [UIColor redColor];
    }
    else if ([fortnight isEqualToString:@"New Moon"])
    {
        self.contentView.backgroundColor = [UIColor greenColor];
    }
    
    // Stop the Activity Indicator from animating, the data has been loaded.
    [self.activityIndicator stopAnimating];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
