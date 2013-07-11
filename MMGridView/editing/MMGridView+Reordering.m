#import "MMGridView+Reordering.h"
#import "MMGridViewCell+Private.h"


@implementation MMGridView (Reordering)

- (void)_didBeginReorderingAnimation {
    [self setAnimating:YES];
    NSLog(@"[Reorder]");
}

- (void)_didEndShiftAnimationWithCompletion:(MMAnimationCompletion)completion
{
    NSLog(@"[/Reorder]");
    [self setAnimating:NO];
    completion(YES);
}

- (void)reorderCellFrom:(NSIndexPath *)from to:(NSIndexPath *)to completion:(MMAnimationCompletion)completion
{
    if (from == nil || to == nil) {
        [self _raiseInvalidInputIndexPaths:from and:to];
    }

    if (from.section != to.section) {
        [NSException raise:@"~ Cannot reorder from one page to another ~" format:@"...yet"];
    }

    void (^emptyCompletion)(BOOL) = ^(BOOL f) {
    };

    if (completion == nil) {
        completion = emptyCompletion;
    }

    if ([from isEqual:to]) {
        completion(NO);
        return;
    }

    MMGridViewCell *fromCell = [self cell4IndexPath:from];
    if (fromCell == nil) {
        [self _raiseNonExistentCellAt:from];
    }

    [self _didBeginReorderingAnimation];
    NSMutableArray *animatingCells = [NSMutableArray array];

    if ([from greaterOrEqualThan:to]) {

        for (MMGridViewCell *cell in [self cellsGreaterOrEqualThan:to lessOrEqualThan:from.minusOne]) {  //   for ( i= from - 1; i >= to; i--)

            cell.indexPath = cell.indexPath.plusOne;
            cell.animating = YES;
            [animatingCells insertObject:cell atIndex:0];
        }

    } else {

        for (MMGridViewCell *cell in [self cellsGreaterOrEqualThan:from.plusOne lessOrEqualThan:to]) {  //  for (i = from + 1; i <= to; i++)

            cell.indexPath = cell.indexPath.minusOne;
            cell.animating = YES;
            [animatingCells addObject:cell];
        }

    }

    fromCell.indexPath = to;
    fromCell.animating = YES;
    [animatingCells insertObject:fromCell atIndex:0];

    float delay = .0;
    for (MMGridViewCell *cell in animatingCells) {

        if (cell == animatingCells.lastObject) {

            [self _adjustCellPosition:cell withDelay:delay completion:^(BOOL f){

                [self _didEndShiftAnimationWithCompletion:completion];
            }];
        } else {

            [self _adjustCellPosition:cell withDelay:delay completion:nil];
        }
        delay += .1;
    }
}

- (void)_adjustCellPosition:(MMGridViewCell *)cell withDelay:(CGFloat)delay completion:(MMAnimationCompletion)completion {

    [UIView animateWithDuration:.1 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self adjustPosition4CellAt:cell.indexPath];

    } completion:^(BOOL f){

        cell.animating = NO;
        if (completion != nil) {
            completion(f);
        }
    }];
}

@end


@implementation NSIndexPath (plus)

- (id)plusOne {
    return [NSIndexPath indexPathForRow:(self.row + 1) inSection:self.section];
}

- (id)minusOne {
    return [NSIndexPath indexPathForRow:(self.row - 1) inSection:self.section];
}

- (BOOL)greaterOrEqualThan:(NSIndexPath *)path {
    switch ([self compare:path]) {
        case NSOrderedDescending:
        case NSOrderedSame: {
            return YES;
        }
        default: return NO;
    }
}

- (BOOL)lessOrEqualThan:(NSIndexPath *)path {
    switch ([self compare:path]) {
        case NSOrderedAscending:
        case NSOrderedSame: {
            return YES;
        }
        default: return NO;
    }
}

@end