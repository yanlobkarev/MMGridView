//
// Copyright (c) 2010-2011 René Sprotte, Provideal GmbH
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <CoreGraphics/CoreGraphics.h>
#import "MMGridViewCell+Private.h"
#import "MMGridView.h"


@interface MMGridView()

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, assign) MMGridLayout *layout;
@property (nonatomic) NSUInteger currentPageIndex;

- (void)reuseCell:(MMGridViewCell *)cell;
- (void)createSubviews;
- (void)cellWasSelected:(MMGridViewCell *)cell;
- (void)cellWasDoubleTapped:(MMGridViewCell *)cell;
- (void)updateCurrentPageIndex;
@end


@implementation MMGridView

@synthesize layout;
@synthesize scrollView;
@synthesize dataSource;
@synthesize delegate;
@synthesize isAnimating;
@synthesize cellMargin;
@synthesize currentPageIndex;


- (void)dealloc
{
    [scrollView release];
    [layout release];
    [reusable removeAllObjects];
    [reusable release];
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        [self createSubviews];
        reusable = [NSMutableDictionary new];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self createSubviews];
        reusable = [NSMutableDictionary new];
    }
    
    return self;
}


- (void)createSubviews
{
    cellMargin = 3;
    numberOfRows = 3;
    numberOfColumns = 2;
    currentPageIndex = 0;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; 
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor clearColor];
    
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.scrollView.alwaysBounceHorizontal = NO;
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    [self addSubview:self.scrollView];
    
    [self reloadData];
}

- (void)setAnimating:(BOOL)animating {
    isAnimating = animating;
}

- (void)_layoutCells
{
    if (self.dataSource == nil) return;

    self.scrollView.pagingEnabled = self.layout.pagingEnabled;
    [self.scrollView setContentSize:layout.contentSize];

    NSMutableSet *visiblePaths = layout.visibleIndexPaths;
    NSArray *cells = [self allCells];

    for (MMGridViewCell *cell in cells) {
        if ([visiblePaths containsObject:cell.indexPath]) {

            cell.center = [layout center4IndexPath:cell.indexPath];
            [visiblePaths removeObject:cell.indexPath];
        } else {

            //  since it cell is not visible
            //  we remove 'em
            [self reuseCell:cell];
            [cell removeFromSuperview];
        }
    }

    //  left index-paths are cells
    //  which missed on screen
    //  so we should add them
    for (NSIndexPath *path in visiblePaths) {

        MMGridViewCell *cell = [dataSource gridView:self cellAtIndexPath:path];
        cell.center = [layout center4IndexPath:path];
        cell.gridView = self;
        cell.indexPath = path;
        [scrollView addSubview:cell];
    }
}

- (void)drawRect:(CGRect)rect
{
    [self _layoutCells];
}

- (void)setDataSource:(id<MMGridViewDataSource>)aDataSource
{
    dataSource = aDataSource;
    itemSize = [dataSource itemSizeInGridView:self];
    self.layout = nil;
    [self reloadData];
}

- (void)setCellMargin:(NSUInteger)value
{
    cellMargin = value;
    [self reloadData];
}

- (MMGridLayout *)layout
{
    if (layout == nil) {
        MMGridLayoutType layoutType = [dataSource layoutTypeInGridView:self];
        self.layout = [[MMGridLayout gridLayoutWithType:layoutType itemSize:itemSize dataSource:dataSource andScrollView:scrollView] retain];
    }
    return layout;
}

- (NSUInteger)numberOfRows
{
    return self.layout.numberOfRows;
}

- (NSUInteger)numberOfColumns
{
    return self.layout.numberOfColumns;
}

- (NSUInteger)numberOfPages
{
    return self.layout.numberOfSections;
}


- (void)reloadData
{
    self.layout = nil;
    [[self allCells] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self _layoutCells];
}

- (NSArray *)allCells
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@", MMGridViewCell.class, self];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    return results;
}

- (NSArray *)cells4Section:(NSUInteger)section {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@ AND indexPath.section == %d", MMGridViewCell.class, self, section];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    return results;
}

- (MMGridViewCell *)cell4IndexPath:(NSIndexPath *)indexPath
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@ AND indexPath == %@", MMGridViewCell.class, self, indexPath];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    switch (results.count) {
        case 0: return nil;
        case 1: return results.lastObject;
        default: {
            NSLog(@"~ WTF! There is more than one cells:\n%@;\n with that path: %@ ~", results, indexPath);
            return results.lastObject;
        }
    }
}

- (void)replaceCell:(MMGridViewCell *)oldCell withCell:(MMGridViewCell *)newCell
{
    if (oldCell.superview != scrollView) return;
    if (oldCell.indexPath == nil) return;
    if (newCell == nil) return;

    newCell.center = [self.layout center4IndexPath:oldCell.indexPath];
    newCell.indexPath = oldCell.indexPath;

    [scrollView insertSubview:newCell aboveSubview:oldCell];
    [oldCell removeFromSuperview];
}

- (void)_raiseInvalidInputIndexPaths:(id)one and:(id)second {
    [NSException raise:@"~ InvalidInputException." format:@"params: %@ and %@", one, second];
}

- (void)_raiseNonExistentCellAt:(id)path {
    [NSException raise:@"~ NonExistentCellException." format:@"at: %@", path];
}

- (void)moveCellAt:(NSIndexPath *)from to:(NSIndexPath *)to {

    if (from == nil || to == nil) {
        [self _raiseInvalidInputIndexPaths:from and:to];
    }

    MMGridViewCell *fromCell = [self cell4IndexPath:from];

    if (fromCell == nil) {
        [self _raiseNonExistentCellAt:from];
    }

    fromCell.center = [self.layout center4IndexPath:to];
    fromCell.indexPath = to;
}

- (void)scrollToIndexPathOrigin:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    CGRect rect = [self.layout rect4IndexPath:indexPath];
    [scrollView setContentOffset:rect.origin animated:animated];
}

- (void)cellWasSelected:(MMGridViewCell *)cell
{
    if (delegate && [delegate respondsToSelector:@selector(gridView:didSelectCell:atIndexPath:)]) {
        [delegate gridView:self didSelectCell:cell atIndexPath:cell.indexPath];
    }
}


- (void)cellWasDoubleTapped:(MMGridViewCell *)cell
{
    if (delegate && [delegate respondsToSelector:@selector(gridView:didDoubleTapCell:atIndexPath:)]) {
        [delegate gridView:self didDoubleTapCell:cell atIndexPath:cell.indexPath];
    }
}

- (void)updateCurrentPageIndex
{
    NSUInteger page = [layout currentSectionInScrollView];

    if (page != self.currentPageIndex) {
        self.currentPageIndex = page;
        if (delegate && [delegate respondsToSelector:@selector(gridView:changedPageToIndex:)]) {
            [self.delegate gridView:self changedPageToIndex:self.currentPageIndex];
        }
    }
}

// ----------------------------------------------------------------------------------

#pragma - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)_
{
    [self _layoutCells];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_
{
    [self updateCurrentPageIndex];
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)_
{
    [self updateCurrentPageIndex];
}

#pragma mark Reusing cells

- (void)reuseCell:(MMGridViewCell *)cell {
    NSString *key = NSStringFromClass(cell.class);
    [reusable setObject:cell forKey:key];
}

- (id)dequeueReusableCellOfClass:(Class)class {
    NSString *key = NSStringFromClass(class);
    MMGridViewCell *cell = [[[reusable objectForKey:key] retain] autorelease];
    [reusable removeObjectForKey:key];
    return cell;
}

@end


@implementation MMGridView (Editing)

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

    if (from == to) {
        completion(NO);
        return;
    }

    MMGridViewCell *memCell = [self cell4IndexPath:from];

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
    NSUInteger cellsCount = [self.layout cellsCount4Section:section];
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

    if (path == nil) {
        [self _raiseNonExistentCellAt:path];
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