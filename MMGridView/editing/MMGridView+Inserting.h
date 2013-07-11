#import <Foundation/Foundation.h>
#import "MMGridView.h"
#import "MMGridView+Reordering.h"

@interface MMGridView (Inserting)
- (void)insertCellAt:(NSIndexPath *)at completion:(MMAnimationCompletion)completion;
@end