#import <Foundation/Foundation.h>
#import "MMGridView.h"
#import "MMGridView+Reordering.h"


@interface MMGridView (Deleting)
- (void)deleteCell4IndexPath:(NSIndexPath *)path withCompletion:(MMAnimationCompletion)completion;
@end