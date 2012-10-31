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
    result->dataSource = dataSource;
    result->itemSize = itemSize;
    result->layout = aLayoutType;
    return result;
}

- (NSMutableSet *)visibleIndexPaths
{
    NSMutableSet *paths = [NSMutableSet set];

    NSUInteger sections = 1;
    switch (layout) {
        case MMGridLayoutHorizontal:
        case MMGridLayoutVertical: {
            sections = 1;
            break;
        }
        case MMGridLayoutPagedHorizontal:
        case MMGridLayoutPagedVertical: {
            sections = [dataSource numberOfSectionsInGridLayout:self];
        }

    }

    for (NSUInteger section=0; section<sections; section++) {

        for (NSUInteger row=0; row<[dataSource gridLayout:self numberOfCellsInSection:sections]; row++) {
            [paths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
    return paths;
}

- (CGPoint)_sectionOffset:(NSUInteger)section
{
    switch (layout) {
        case MMGridLayoutPagedHorizontal:   return CGPointMake(scrollView.frame.size.width * section, 0);
        case MMGridLayoutPagedVertical:     return CGPointMake(0, scrollView.frame.size.height * section);
        default:    return CGPointZero;
    }
}

- (CGPoint)centerForIndexPath:(NSIndexPath *)path
{
    CGPoint center = [self _sectionOffset:(NSUInteger)path.section];

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

@end