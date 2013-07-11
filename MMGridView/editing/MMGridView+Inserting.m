#import "MMGridView+Inserting.h"
#import "MMGridViewCell+Private.h"


#define SHRINK_SCALE .005


@implementation MMGridView (Inserting)

//  todo: copy-pasted from `Deleting`
- (void)_raiseInvalidInputPath:(NSIndexPath *)path {
    [NSException raise:@"InvalidInputIndexPath" format:@"(path= %@)", path];
}

- (void)_didEndShiftAnimationWithCompletion:(MMAnimationCompletion)completion forCell:(MMGridViewCell *)cell {

    cell.transform = CGAffineTransformScale(CGAffineTransformIdentity, SHRINK_SCALE, SHRINK_SCALE);

    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{

        [self setAnimating:YES];
        cell.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
    } completion:^(BOOL f){

        [self setAnimating:NO];
        cell.animating = NO;
        completion(YES);
    }];
}


- (void)insertCellAt:(NSIndexPath *)at completion:(MMAnimationCompletion)completion {

    if (at == nil) {
        [self _raiseInvalidInputPath:at];
    }

    MMGridViewCell *cell = [self.dataSource gridView:self cellAtIndexPath:at];

    if (cell == nil) {
        [self _raiseNonExistentCellAt:at];
    }

    if (completion == nil) {
        completion = ^(BOOL f){};
    }

    NSArray *cells = [self cells4Section:(NSUInteger)at.section];
    NSNumber *last = [cells valueForKeyPath:@"@max.indexPath.row"];
    NSInteger lastRow= (last != nil) ? (last.integerValue + 1) : 0;
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:lastRow inSection:at.section];

    [self setAnimating:YES];

    cell.animating = YES;
    cell.alpha = 0;

    /*  logic copy-pasted from MMGridView   */
    cell.center = [self.layout center4IndexPath:lastIndex];
    cell.gridView = self;
    cell.indexPath = lastIndex;
    [scrollView addSubview:cell];

    [self reorderCellFrom:lastIndex to:at completion:^(BOOL f){

        [self _didEndShiftAnimationWithCompletion:completion forCell:cell];
    }];
}

@end
