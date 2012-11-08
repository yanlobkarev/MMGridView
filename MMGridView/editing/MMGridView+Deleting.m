#import "MMGridView+Deleting.h"


@implementation MMGridView (Deleting)

- (void)_raiseInvalidInputPath:(NSIndexPath *)path {
    [NSException raise:@"InvalidInputIndexPath" format:@"(path= %@)", path];
}

- (void)_didEndReordering4DisappearedCell:(MMGridViewCell *)cell completion:(MMAnimationCompletion)completion
{
    [cell removeFromSuperview];
    cell.transform = CGAffineTransformIdentity;
    cell.alpha = 1;
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

    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self setAnimating:YES];
        cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, .05, .05);
    } completion:^(BOOL f){
        [self setAnimating:NO];
        cell.alpha = 0;
        [self _didEndDisappearingAnimation4Cell:cell completion:completion];
    }];
}

@end