#import <Foundation/Foundation.h>
#import "MMGridView+Private.h"


typedef void (^MMAnimationCompletion)(BOOL f);


@interface MMGridView (Reordering)
- (void)reorderCellFrom:(NSIndexPath *)from to:(NSIndexPath *)to completion:(MMAnimationCompletion)completion;
@end


@interface NSIndexPath (plus)
- (id)plusOne;
- (id)minusOne;
- (BOOL)greaterOrEqualThan:(NSIndexPath *)path;
- (BOOL)lessOrEqualThan:(NSIndexPath *)path;
@end