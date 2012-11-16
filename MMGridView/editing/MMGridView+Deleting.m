#import <CoreGraphics/CoreGraphics.h>
#import "MMGridView+Deleting.h"
#import "MMGridViewCell+Private.h"


#define SHRINK_SCALE .005


@implementation MMGridView (Deleting)

- (void)_raiseInvalidInputPath:(NSIndexPath *)path {
    [NSException raise:@"InvalidInputIndexPath" format:@"(path= %@)", path];
}

- (void)_didEndReordering4DisappearedCell:(MMGridViewCell *)cell completion:(MMAnimationCompletion)completion
{
    [cell removeFromSuperview];
    cell.transform = CGAffineTransformIdentity;
    cell.alpha = 1;
    cell.animating = NO;
    [self reuseCell:cell];
    completion(YES);
}

- (void)_didEndDisappearingAnimation4Cell:(MMGridViewCell *)cell completion:(MMAnimationCompletion)completion
{
    NSUInteger section = (NSUInteger) cell.indexPath.section;
    NSUInteger cellsCount = [self cells4Section:section].count;
    NSIndexPath *last = [NSIndexPath indexPathForRow:( cellsCount - 1 ) inSection:section];
    [self reorderCellFrom:cell.indexPath to:last completion:^(BOOL f){

        [self _didEndReordering4DisappearedCell:cell completion:completion];
    }];
}

- (void)deleteCell4IndexPath:(NSIndexPath *)path withCompletion:(MMAnimationCompletion)completion
{
    if (path == nil) {
        [self _raiseInvalidInputPath:path];
    }

    MMGridViewCell *cell = [self cell4IndexPath:path];

    if (cell == nil) {
        [self _raiseNonExistentCellAt:path];
    }

    if (completion == nil) {
        completion = ^(BOOL f){};
    }

    cell.animating = YES;
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self setAnimating:YES];
        cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, SHRINK_SCALE, SHRINK_SCALE);
        cell.alpha = 0;
    } completion:^(BOOL f){
        [self setAnimating:NO];
        [self _didEndDisappearingAnimation4Cell:cell completion:completion];
    }];
}

@end