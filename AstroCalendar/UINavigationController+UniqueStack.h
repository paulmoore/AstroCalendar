//
//  UINavigationController+UniqueStack.h
//  AstroCalendar
//
//  Created by Paul Moore on 11-11-04.
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
 * A UniqueStack UINavigationController adds functionality to handle instances where duplicate
 * UIViewControllers could get pushed onto the stack.
 */
@interface UINavigationController (UniqueStack)

/**
 * Pushes or pops to a UIViewController in navigation stack if an instance of the given class
 * already exists in the navigation stack.
 *
 * @param cType The Class type of the UINavigationController to pop to.
 * @param animated True if this controller should animate the controller into view.
 * @return Returns the instance of UINavigationController that was popped, or nil if no such instance exists.
 */
- (UIViewController *)pushUniqueControllerOfType:(Class)cType animated:(BOOL)isAnimated;

@end
