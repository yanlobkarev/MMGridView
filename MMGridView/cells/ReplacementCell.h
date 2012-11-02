#import <Foundation/Foundation.h>
#import "MMGridViewCell.h"

@class MMGridViewCell;

//  Used to replace cuted cell when you calling
//  MMGridView's cutCell4IndexPath: method.

@interface ReplacementCell : MMGridViewCell
@property (nonatomic, readonly, retain) MMGridViewCell *origin;
+ (id)replacementCell4Origin:(MMGridViewCell *)origin;
@end