#import "MMGridView+Reordering.h"
#import "MMGridViewCell+Private.h"


@implementation MMGridView (Reordering)

- (void)_moveFrom:(NSIndexPath *)from to:(NSIndexPath *)to withDelay:(CGFloat)delay completion:(MMAnimationCompletion)completion
{
    [UIView animateWithDuration:.1 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{

        [self moveCellAt:from to:to];

    } completion:completion];
}

- (void)_didBeginReorderingAnimation {
    [self setAnimating:YES];
    NSLog(@"[Reorder]");
}

- (void)_didEndReorderAnimationWithCompletion:(MMAnimationCompletion)completion
{
    NSLog(@"[/Reorder]");
    [self setAnimating:NO];
    completion(YES);
}

- (void)_didEndShiftingBeforeInsertingCell:(MMGridViewCell *)cell to:(NSIndexPath *)to completion:(MMAnimationCompletion)competion
{
    cell.indexPath = to;
    [self _moveFrom:to to:to withDelay:0.1 completion:^(BOOL f){
        [self _didEndReorderAnimationWithCompletion:competion];
    }];
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

    MMGridViewCell *memCell = [self cell4IndexPath:from];
    if (memCell == nil) {
        [self _raiseNonExistentCellAt:from];
    }

    [self _didBeginReorderingAnimation];

    float delay = .0;
    if ([from greaterOrEqualThan:to]) {

        NSIndexPath *start = from.minusOne;
        for (NSIndexPath *i = start; [i greaterOrEqualThan:to] && [i lessOrEqualThan:start]; i = i.minusOne) {   //   for ( i= from - 1; i >= to; i--)

            [self _moveFrom:i to:i.plusOne withDelay:delay completion:^(BOOL f) {

                if ([i isEqual:to]) {
                    [self _didEndShiftingBeforeInsertingCell:memCell to:to completion:completion];
                }
            }];

            delay += .1;
        }
    } else {

        for (NSIndexPath *i = from.plusOne; [i lessOrEqualThan:to]; i = i.plusOne) {            //  for (i = from + 1; i <= to; i++)

            [self _moveFrom:i to:i.minusOne withDelay:delay completion:^(BOOL f) {

                if ([i isEqual:to]) {
                    [self _didEndShiftingBeforeInsertingCell:memCell to:to completion:completion];
                }

            }];
            delay += .1;
        }
    }
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