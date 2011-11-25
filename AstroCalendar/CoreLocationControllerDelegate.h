//
//  CoreLocationControllerDelegate.h
//  AstroCalendar
//
//  Created by Stephen Smithbower on 11-11-24.
//  University of British Columbia.
//
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
#import <CoreLocation/CoreLocation.h>

/**
 * Protocol defines an interface that allows any implementing object to handle
 * GPS updates.
 *
 * locationUpdate is raised when new GPS data is availble.
 * locationError is raised when CoreLocation is unable to provide location information.
 */
@protocol CoreLocationControllerDelegate

@required
+ (void)locationUpdate:(CLLocation *)location; // Our location updates are sent here
    
+ (void)locationError:(NSError *)error; // Any errors are sent here

@end


/**
 * Designed to handle CoreLocation updates (see CoreLocationControllerDelegate).
 * This raises the appropriate alerts when new data is available.
 */
@interface CoreLocationController : NSObject <CLLocationManagerDelegate> 
{
	CLLocationManager *locationManager;
	id delegate;
}
 
@property(nonatomic, retain, strong) CLLocationManager *locationManager;
@property(nonatomic, retain, strong) id delegate;

@end