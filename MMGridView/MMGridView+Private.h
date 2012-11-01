#import <Foundation/Foundation.h>
#import "MMGridView.h"


@interface MMGridView (Private)
- (void)_raiseInvalidInputIndexPaths:(id)one and:(id)second;
- (void)_raiseNonExistentCellAt:(id)path;
- (void)reuseCell:(MMGridViewCell *)cell;
- (void)setAnimating:(BOOL)animating;
@end

