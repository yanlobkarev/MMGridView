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
#import "MMGridView.h"


@interface MMGridViewCell (Private)
@property (nonatomic, retain) MMGridView *indexPath;
@property (nonatomic, assign) MMGridView *gridView;
@end


@interface MMGridView()

@property (nonatomic, retain) UIScrollView *scrollView;
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


- (NSMutableSet *)_visibleIndexPaths {
    NSMutableSet *paths = [NSMutableSet set];

    NSUInteger sections = 1;
    switch (layout) {
        case MMGridViewLayoutHorizontal:
        case MMGridViewLayoutVertical: {
            sections = 1;
            break;
        }
        case MMGridViewLayoutPagedHorizontal:
        case MMGridViewLayoutPagedVertical: {
            sections = [dataSource numberOfSectionsInGridView:self];
        }

    }

    for (NSUInteger section=0; section<sections; section++) {

        for (NSUInteger row=0; row<[dataSource gridView:self numberOfCellsInSection:sections]; row++) {
            [paths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    return paths;
}

- (CGPoint)_sectionOffset:(NSUInteger)section {
    switch (layout) {
        case MMGridViewLayoutPagedHorizontal: {
            return CGPointMake(scrollView.frame.size.width * section, 0);
        }
        case MMGridViewLayoutPagedVertical: {
            return CGPointMake(0, scrollView.frame.size.height * section);
        }
        default: {
            return CGPointZero;
        }
    }
}

- (CGPoint)_centerForIndexPath:(NSIndexPath *)path {
    CGPoint center = [self _sectionOffset:(NSUInteger)path.section];

    NSUInteger row;
    NSUInteger column;

    if (layout == MMGridViewLayoutHorizontal) {
        row = (NSUInteger) path.row % self.numberOfRows;
        column = (NSUInteger) path.row / self.numberOfRows;
    } else {
        row = (NSUInteger) path.row / self.numberOfColumns;
        column = (NSUInteger) path.row % self.numberOfColumns;
    }

    center.y += (row + 0.5) * itemSize.height;
    center.x += (column + 0.5) * itemSize.width;

    return center;
}

- (CGSize)_contentSize {
    CGSize size = scrollView.frame.size;
    NSUInteger sections = [dataSource numberOfSectionsInGridView:self];
    switch (layout) {
        case MMGridViewLayoutPagedHorizontal: {
            size.width *= sections;
            break;
        }
        case MMGridViewLayoutPagedVertical: {
            size.height *= sections;
            break;
        }
        case MMGridViewLayoutHorizontal: {
            CGFloat columnsWidth = self.numberOfColumns * itemSize.width;
            size.width = MAX(size.width, columnsWidth);
            break;
        }
        case MMGridViewLayoutVertical: {
            CGFloat rowsHeight = self.numberOfRows * itemSize.height;
            size.height = MAX(size.height, rowsHeight);
            break;
        }

    }
    return size;
}

- (void)drawRect:(CGRect)rect
{
    if (self.dataSource) {

        self.scrollView.pagingEnabled = (layout == MMGridViewLayoutPagedHorizontal || layout == MMGridViewLayoutPagedVertical);
        [self.scrollView setContentSize:[self _contentSize]];
        [self.scrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

        NSMutableSet *paths = [self _visibleIndexPaths];

        for (NSIndexPath *path in paths) {
            MMGridViewCell *cell = [self.dataSource gridView:self cellAtIndexPath:path];
            cell.center = [self _centerForIndexPath:path];
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
    [self reloadData];
}


- (NSUInteger)numberOfColumns
{
    switch (layout) {
        case MMGridViewLayoutPagedHorizontal:
        case MMGridViewLayoutPagedVertical:
        case MMGridViewLayoutVertical: {
            return (NSUInteger) scrollView.frame.size.width / (NSUInteger) itemSize.width;
        }
        case MMGridViewLayoutHorizontal: {
            NSUInteger rows = self.numberOfRows;
            NSUInteger count = [dataSource gridView:self numberOfCellsInSection:0];
            NSUInteger columns = count / rows;
            if (count % rows > 0) {
                columns += 1;
            }
            return columns;
        }
        default: return 0;
    }
}

- (NSUInteger)numberOfRows
{
    switch (layout) {
        case MMGridViewLayoutPagedHorizontal:
        case MMGridViewLayoutPagedVertical:
        case MMGridViewLayoutHorizontal: {
            return (NSUInteger) scrollView.frame.size.height / (NSUInteger) itemSize.height;
        }
        case MMGridViewLayoutVertical: {
            NSUInteger columns = self.numberOfColumns;
            NSUInteger count = [dataSource gridView:self numberOfCellsInSection:0];
            NSUInteger rows = count / columns;
            if (count % columns > 0) {
                rows += 1;
            }
            return rows;
        }
        default: return 0;
    }
}

- (void)setCellMargin:(NSUInteger)value
{
    cellMargin = value;
    [self reloadData];
}


- (NSUInteger)numberOfPages
{
    return [dataSource numberOfSectionsInGridView:self];
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
    CGSize pageSize = scrollView.frame.size;
    NSUInteger page = 0;
    switch (layout) {
        case MMGridViewLayoutPagedHorizontal: {
            page = (NSUInteger) floor((scrollView.contentOffset.x - pageSize.width / 2) / pageSize.width) + 1;
            break;
        }
        case MMGridViewLayoutPagedVertical : {
            page = (NSUInteger) floor((scrollView.contentOffset.y - pageSize.height / 2) / pageSize.height) + 1;
            break;
        }
    }

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
