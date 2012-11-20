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
#import <QuartzCore/QuartzCore.h>
#import "MMGridViewCell+Private.h"
#import "MMGridView+Private.h"
#import "MMGridView.h"
#import "ReplacementCell.h"


@interface MMGridView()
- (void)createSubviews;
- (void)cellWasSelected:(MMGridViewCell *)cell;
- (void)cellWasDoubleTapped:(MMGridViewCell *)cell;
- (void)updateCurrentPageIndex;
@end



@implementation MMGridView

@synthesize scrollView=scrollView;
@synthesize layout;
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

            if (cell.animating == NO) {
                cell.center = [layout center4IndexPath:cell.indexPath];
            }
            [visiblePaths removeObject:cell.indexPath];
        } else {

            //  since this cell is not visible
            //  we remove 'em
            if (cell.animating == NO) {
                [self reuseCell:cell];
                [cell removeFromSuperview];
            }
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
    [layout release];
    layout = nil;
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
        [layout release];
        layout = [[MMGridLayout gridLayoutWithType:layoutType itemSize:itemSize dataSource:dataSource andScrollView:scrollView] retain];
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

- (void)updateAppearance {
    self.layout  = nil;
    [self layout];
    [self _layoutCells];
}

- (void)reloadData
{
    [layout release];
    layout = nil;
    [[self allCells] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self _layoutCells];
}

- (NSArray *)allCells
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@ AND indexPath.isHovered == %d", MMGridViewCell.class, self, NO];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    return results;
}

- (NSArray *)cells4Section:(NSUInteger)section {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@ AND indexPath.section == %d AND indexPath.isHovered == %d", MMGridViewCell.class, self, section, NO];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    return results;
}

- (id)cell4IndexPath:(NSIndexPath *)indexPath
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

- (void)reloadCellAtIndexPath:(NSIndexPath *)path
{
    MMGridViewCell *cell = [self cell4IndexPath:path];

    if (cell == nil) {
        [self _raiseNonExistentCellAt:path];
    }

    MMGridViewCell *fresh = [dataSource gridView:self cellAtIndexPath:path];
    fresh.gridView = self;
    fresh.indexPath = cell.indexPath;
    fresh.center = cell.center;
    [scrollView insertSubview:fresh aboveSubview:cell];

    [self reuseCell:cell];
    [cell removeFromSuperview];
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

    if (fromCell.indexPath.isHovered == NO) {
        fromCell.center = [self.layout center4IndexPath:to];
    }
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

    if (page != currentPageIndex) {

        [self willChangeValueForKey:@"currentPageIndex"];
        currentPageIndex = page;
        [self didChangeValueForKey:@"currentPageIndex"];

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

    [cell.layer removeAllAnimations];
    cell.transform = CGAffineTransformIdentity;
    cell.alpha = 1;

    [reusable removeObjectForKey:key];
    return cell;
}

#pragma mark Cut & Paste

- (void)_raiseTryingToCutHoveredCellAt:(NSIndexPath *)at
{
    [NSException raise:@"TryingToCutHoveredCellException" format:@"...at %@", at];
}

- (MMGridViewCell *)cutCellFromIndexPath:(NSIndexPath *)path
{
    if (path.isHovered == YES) {
        [self _raiseTryingToCutHoveredCellAt:path];
    }

    MMGridViewCell *cell = [self cell4IndexPath:path];

    if (cell == nil) {
        [self _raiseNonExistentCellAt:path];
    }

    ReplacementCell *replacement = [ReplacementCell replacementCell4Origin:cell];
    [scrollView addSubview:replacement];

    cell.indexPath = cell.indexPath.hover;
    return cell;
}

- (NSArray *)_replacements4Cell:(MMGridViewCell *)cell
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self isKindOfClass: %@) AND gridView == %@ AND origin == %@", ReplacementCell.class, self, cell];
    NSArray *results = [scrollView.subviews filteredArrayUsingPredicate:predicate];
    return results;
}

- (void)_raiseTryingToPasteNotHoveredCellFrom:(NSIndexPath *)from
{
    [NSException raise:@"TryingToPasteNotHoveredCellException" format:@"...at %@", from];
}

- (void)_raiseTryingToPasteAtHoveredPath:(NSIndexPath *)at {
    [NSException raise:@"TryingToPasteCellAtHoveredPathException" format:@"...at %@", at];
}

- (void)pasteCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)at
{
    if (cell == nil) {
        [self _raiseNonExistentCellAt:at];
    }

    if (cell.indexPath.isHovered == NO) {
        [self _raiseTryingToPasteNotHoveredCellFrom:cell.indexPath];
    }

    if (at.isHovered) {
        [self _raiseTryingToPasteAtHoveredPath:at];
    }

    cell.indexPath = at;
    cell.gridView = self;

    NSArray *replacements = [self _replacements4Cell:cell];
    [replacements makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end


@implementation NSIndexPath (Hovered)

- (NSIndexPath *)hover {
    if ([self isHovered]) {
        return self;
    }
    return [self indexPathByAddingIndex:NSNotFound];    //  [0, 1] -> [0, 1, NSNotFound]
}

- (NSIndexPath *)unhover {
    if ([self isHovered] == NO) {
        return self;
    }
    return [self indexPathByRemovingLastIndex];         //  [0, 1, NSNotFound] -> [0, 1]
}

- (NSInteger)section
{
    return [self indexAtPosition:0];
}

- (NSInteger)row
{
    return [self indexAtPosition:1];
}

- (BOOL)isHovered
{
    return self.length > 2;
}

@end
