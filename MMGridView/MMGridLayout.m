#import <CoreGraphics/CoreGraphics.h>
#import "MMGridLayout.h"


@implementation MMGridLayout
@synthesize scrollView;
@synthesize dataSource;
@synthesize itemSize;
@synthesize layout;

+ (id)gridLayoutWithType:(MMGridLayoutType)aLayoutType itemSize:(CGSize)itemSize dataSource:(id <MMGridLayoutDataSource>)dataSource andScrollView:(UIScrollView *)scrollView
{
    MMGridLayout *result = [[MMGridLayout new] autorelease];
    result->scrollView = [scrollView retain];
    result->dataSource = [dataSource retain];
    result->itemSize = itemSize;
    result->layout = aLayoutType;
    return result;
}

- (void)dealloc
{
    [scrollView release];
    [dataSource release];
    [super dealloc];
}

#pragma mark Visible-Index-Paths

- (CGRect)_visibleRect
{
    CGRect rect = scrollView.bounds;
    rect.origin = scrollView.contentOffset;
    return rect;
}

- (CGRect)_rect4Section:(NSUInteger)section {
    CGRect rect = scrollView.bounds;
    switch (layout) {
        case  MMGridLayoutPagedHorizontal: {
            rect.origin.x = section * rect.size.width;
            break;
        }
        case  MMGridLayoutPagedVertical: {
            rect.origin.y = section * rect.size.height;
            break;
        }
        default: {
            rect.size = scrollView.contentSize;
        }
    }
    return rect;
}

- (NSMutableIndexSet *)_visibleSections {

    NSMutableIndexSet *visibleSections = [NSMutableIndexSet indexSet];
    CGRect visibleRect = [self _visibleRect];

    for (NSUInteger section = 0; section < [dataSource numberOfSectionsInGridLayout:self]; section++) {
        CGRect sectionRect = [self _rect4Section:section];
        if (CGRectIntersectsRect(sectionRect, visibleRect)) {
            [visibleSections addIndex:section];
        }
    }
    return visibleSections;
}

- (CGRect)rect4IndexPath:(NSIndexPath *)path
{
    CGPoint center = [self center4IndexPath:path];
    CGRect rect;
    rect.origin.x = center.x - itemSize.width/2;
    rect.origin.y = center.y - itemSize.height/2;
    rect.size = itemSize;
    return rect;
}

- (NSMutableIndexSet *)_visibleIndexesInSection:(NSUInteger)section {

    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
    CGRect visibleRect = [self _visibleRect];

    for (NSUInteger index=0; index<[dataSource gridLayout:self numberOfCellsInSection:section]; index++) {

        CGRect itemRect = [self rect4IndexPath:[NSIndexPath indexPathForRow:index inSection:section]];
        if (CGRectIntersectsRect(visibleRect, itemRect)) {
            [indices addIndex:index];
        }
    }

    return indices;
}

- (NSMutableSet *)visibleIndexPaths
{
    NSMutableSet *paths = [NSMutableSet set];
    NSMutableIndexSet *sections = [self _visibleSections];

    NSUInteger section = sections.firstIndex;
    while (section != NSNotFound) {

        NSMutableIndexSet *indices = [self _visibleIndexesInSection:section];
        NSUInteger index = indices.firstIndex;
        while (index != NSNotFound) {

            [paths addObject:[NSIndexPath indexPathForRow:index inSection:section]];
            index = [indices indexGreaterThanIndex:index];
        }
        section = [sections indexGreaterThanIndex:section];
    }
    return paths;
}

#pragma mark All-Another-Stuff

- (CGPoint)_sectionOffset:(NSInteger)section
{
    switch (layout) {
        case MMGridLayoutPagedHorizontal:   return CGPointMake(scrollView.frame.size.width * section, 0);
        case MMGridLayoutPagedVertical:     return CGPointMake(0, scrollView.frame.size.height * section);
        default:    return CGPointZero;
    }
}

- (CGPoint)center4IndexPath:(NSIndexPath *)path
{
    CGPoint center = [self _sectionOffset:path.section];

    NSUInteger row;
    NSUInteger column;

    if (layout == MMGridLayoutHorizontal) {
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

- (CGSize)contentSize
{
    CGSize size = scrollView.frame.size;
    NSUInteger sections = [dataSource numberOfSectionsInGridLayout:self];
    switch (layout) {
        case MMGridLayoutPagedHorizontal: {
            size.width *= sections;
            break;
        }
        case MMGridLayoutPagedVertical: {
            size.height *= sections;
            break;
        }
        case MMGridLayoutHorizontal: {
            CGFloat columnsWidth = self.numberOfColumns * itemSize.width;
            size.width = MAX(size.width, columnsWidth);
            break;
        }
        case MMGridLayoutVertical: {
            CGFloat rowsHeight = self.numberOfRows * itemSize.height;
            size.height = MAX(size.height, rowsHeight);
            break;
        }

    }
    return size;
}



- (NSUInteger)numberOfColumns
{
    switch (layout) {
        case MMGridLayoutPagedHorizontal:
        case MMGridLayoutPagedVertical:
        case MMGridLayoutVertical: {
            return (NSUInteger) scrollView.frame.size.width / (NSUInteger) itemSize.width;
        }
        case MMGridLayoutHorizontal: {
            NSUInteger rows = self.numberOfRows;
            NSUInteger count = [dataSource gridLayout:self numberOfCellsInSection:0];
            NSUInteger columns = count / rows;
            if (count % rows > 0) {
                columns += 1;
            }
            return columns;
        }
        default: return 0;
    }
}

- (NSUInteger)numberOfSections
{
    return [dataSource numberOfSectionsInGridLayout:self];
}

- (BOOL)pagingEnabled
{
    return (layout == MMGridLayoutPagedHorizontal || layout == MMGridLayoutPagedVertical);
}

- (NSUInteger)numberOfRows
{
    switch (layout) {
        case MMGridLayoutPagedHorizontal:
        case MMGridLayoutPagedVertical:
        case MMGridLayoutHorizontal: {
            return (NSUInteger) scrollView.frame.size.height / (NSUInteger) itemSize.height;
        }
        case MMGridLayoutVertical: {
            NSUInteger columns = self.numberOfColumns;
            NSUInteger count = [dataSource gridLayout:self numberOfCellsInSection:0];
            NSUInteger rows = count / columns;
            if (count % columns > 0) {
                rows += 1;
            }
            return rows;
        }
        default: return 0;
    }
}

- (NSUInteger)currentSectionInScrollView
{
    CGSize pageSize = scrollView.frame.size;
    switch (layout) {
        case MMGridLayoutPagedHorizontal: {
            return (NSUInteger) floor((scrollView.contentOffset.x - pageSize.width / 2) / pageSize.width) + 1;
        }
        case MMGridLayoutPagedVertical : {
            return (NSUInteger) floor((scrollView.contentOffset.y - pageSize.height / 2) / pageSize.height) + 1;
        }
        default: {
            return 0;
        }
    }
}

- (NSUInteger)cellsCount4Section:(NSUInteger)section {
    return [dataSource gridLayout:self numberOfCellsInSection:section];
}

- (BOOL)isValidIndexPath:(NSIndexPath *)indexPath {
    if (indexPath != nil) {
        if (indexPath.section < [dataSource numberOfSectionsInGridLayout:self]) {
            if (indexPath.row < [dataSource gridLayout:self numberOfCellsInSection:(NSUInteger)indexPath.section]) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSIndexPath *)indexPath4Point:(CGPoint)point {

    for (NSUInteger section = 0; section<[dataSource numberOfSectionsInGridLayout:self]; section++) {

        CGRect rect = [self _rect4Section:section];
        if (CGRectContainsPoint(rect, point)) {

            NSUInteger rows = self.numberOfRows;
            NSUInteger cols = self.numberOfColumns;
            for (NSUInteger index = 0; index < rows*cols; index++) {

                NSIndexPath *path = [NSIndexPath indexPathForRow:index inSection:section];
                rect = [self rect4IndexPath:path];
                if (CGRectContainsPoint(rect, point)) {

                    return path;
                }
            }
        }
    }

    return nil;
}

@end