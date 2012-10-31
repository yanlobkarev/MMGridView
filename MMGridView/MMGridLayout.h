#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef enum {
    MMGridLayoutPagedHorizontal = 0,
    MMGridLayoutPagedVertical = 1,
    MMGridLayoutHorizontal = 3,         //  in that case item views arranged from top-to-bottom, from left-to-right
    MMGridLayoutVertical = 4
} MMGridLayoutType;


@class MMGridLayout;


@protocol MMGridLayoutDataSource<NSObject>
- (NSUInteger)numberOfSectionsInGridLayout:(MMGridLayout *)layout;
- (NSUInteger)gridLayout:(MMGridLayout *)layout numberOfCellsInSection:(NSUInteger)section;
@end


@interface MMGridLayout : NSObject
@property (nonatomic, readonly) id<MMGridLayoutDataSource> dataSource;
@property (nonatomic, readonly) MMGridLayoutType layout;
@property (nonatomic, readonly) CGSize itemSize;

@property (nonatomic, readonly) NSUInteger numberOfRows;
@property (nonatomic, readonly) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfSections;
@property (nonatomic, readonly) UIScrollView *scrollView;

+ (id)gridLayoutWithType:(MMGridLayoutType)aLayoutType itemSize:(CGSize)itemSize dataSource:(id <MMGridLayoutDataSource>)dataSource andScrollView:(UIScrollView *)scrollView;
- (NSUInteger)currentSectionInScrollView;
- (BOOL)pagingEnabled;
- (CGSize)contentSize;
- (CGPoint)centerForIndexPath:(NSIndexPath *)path;
- (NSMutableSet *)visibleIndexPaths;

@end


