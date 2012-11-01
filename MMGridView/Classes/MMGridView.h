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

#import <UIKit/UIKit.h>
#import "MMGridViewCell.h"
#import "MMGridLayout.h"


@class MMGridView;


// ----------------------------------------------------------------------------------

#pragma - MMGridViewDataSource

@protocol MMGridViewDataSource<MMGridLayoutDataSource>
- (CGSize)itemSizeInGridView:(MMGridView *)gridView;
- (MMGridLayoutType)layoutTypeInGridView:(MMGridView *)gridView;
- (MMGridViewCell *)gridView:(MMGridView *)gridView cellAtIndexPath:(NSIndexPath *)indexPath;
@end

// ----------------------------------------------------------------------------------

#pragma - MMGridViewDelegate

@protocol MMGridViewDelegate<NSObject>
@optional
- (void)gridView:(MMGridView *)gridView didSelectCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(MMGridView *)gridView didDoubleTapCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)gridView:(MMGridView *)gridView changedPageToIndex:(NSUInteger)index;
@end

// ----------------------------------------------------------------------------------

#pragma - MMGridView


@interface MMGridView : UIView<UIScrollViewDelegate>
{
    @private
    UIScrollView *scrollView;
    id<MMGridViewDataSource> dataSource;
    id<MMGridViewDelegate> delegate;
    NSUInteger numberOfRows;
    NSUInteger numberOfColumns;
    NSUInteger cellMargin;
    CGSize itemSize;
    NSMutableDictionary *reusable;
}

@property (nonatomic, retain, readonly) UIScrollView *scrollView;
@property (nonatomic, assign) IBOutlet id<MMGridViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<MMGridViewDelegate> delegate;

@property (nonatomic, readonly) BOOL isAnimating;

@property (nonatomic, readonly) MMGridLayout *layout;
@property (nonatomic, readonly) NSUInteger numberOfRows;
@property (nonatomic, readonly) NSUInteger numberOfColumns;
@property (nonatomic, readonly) NSUInteger numberOfPages;
@property (nonatomic, readonly) NSUInteger currentPageIndex;
@property (nonatomic) NSUInteger cellMargin;

- (void)reloadData;
- (NSArray *)allCells;
- (NSArray *)cells4Section:(NSUInteger)section;
- (MMGridViewCell *)cell4IndexPath:(NSIndexPath *)indexPath;
- (id)dequeueReusableCellOfClass:(Class)class;
- (void)replaceCell:(MMGridViewCell *)oldCell withCell:(MMGridViewCell *)newCell;
- (void)moveCellAt:(NSIndexPath *)from to:(NSIndexPath *)to;
- (void)scrollToIndexPathOrigin:(NSIndexPath *)indexPath animated:(BOOL)animated;
@end


typedef void (^MMAnimationCompletion)(BOOL f);

@interface MMGridView (Editing)
- (void)reorderCellFrom:(NSIndexPath *)from to:(NSIndexPath *)to completion:(MMAnimationCompletion)completion;

- (void)deleteCell4IndexPath:(NSIndexPath *)path withCompletion:(MMAnimationCompletion)completion;
@end


@interface NSIndexPath (plus)
- (id)plusOne;
- (id)minusOne;
- (BOOL)greaterOrEqualThan:(NSIndexPath *)path;
- (BOOL)lessOrEqualThan:(NSIndexPath *)path;
@end