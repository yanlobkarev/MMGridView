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
@synthesize cellMargin;
@synthesize currentPageIndex;


- (void)dealloc
{
    [scrollView release];
    [layout release];
    [super dealloc];
}


- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
        [self createSubviews];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self createSubviews];
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


- (void)drawRect:(CGRect)rect
{
    if (self.dataSource) {

        self.scrollView.pagingEnabled = layout.pagingEnabled;
        [self.scrollView setContentSize:layout.contentSize];
        [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

        NSMutableSet *paths = layout.visibleIndexPaths;

        for (NSIndexPath *path in paths) {
            MMGridViewCell *cell = [self.dataSource gridView:self cellAtIndexPath:path];
            cell.center = [layout centerForIndexPath:path];
            cell.gridView = self;
            cell.indexPath = path;
            [scrollView addSubview:cell];
        }
    }
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
    [self setNeedsDisplay];
}

- (MMGridViewCell *)cellForIndexPath:(NSIndexPath *)indexPath
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

    newCell.center = [self.layout centerForIndexPath:oldCell.indexPath];
    newCell.indexPath = oldCell.indexPath;

    [scrollView insertSubview:newCell aboveSubview:oldCell];
    [oldCell removeFromSuperview];
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

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_
{
    [self updateCurrentPageIndex];
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)_
{
    [self updateCurrentPageIndex];
}

@end
