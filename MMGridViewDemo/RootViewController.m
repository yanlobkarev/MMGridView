//
// Copyright (c) 2010-2011 Ren� Sprotte, Provideal GmbH
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

#import "RootViewController.h"
#import "AnyViewController.h"
#import "MMGridViewDefaultCell.h"


@interface RootViewController()
- (void)reload;
- (void)setupPageControl;
@end

@implementation RootViewController

// ----------------------------------------------------------------------------------

#pragma - Object lifecycle

- (void)dealloc
{
    [gridView release];
    [pageControl release];
    [model release];
    [super dealloc];
}


- (void)viewDidUnload
{
    [gridView release];
    gridView = nil;
    [pageControl release];
    pageControl = nil;
    [super viewDidUnload];
}


- (void)viewDidLoad
{
    NSMutableArray *page = [NSMutableArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", @"6", nil];
    model = [[NSMutableArray arrayWithObjects:page, page.mutableCopy, page.mutableCopy, page.mutableCopy, page.mutableCopy, nil] retain];

    // Give us a nice title
    self.title = @"MMGridView Demo";
    
    // Create a reload button
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                                                                  target:self 
                                                                                  action:@selector(reload)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    [reloadButton release];
    
    // setup the page control 
    [self setupPageControl];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait || 
            interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
            interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (void)reload
{
    [gridView reloadData];
}


- (void)setupPageControl
{
    pageControl.numberOfPages = gridView.numberOfPages;
    pageControl.currentPage = gridView.currentPageIndex;
}

// ----------------------------------------------------------------------------------

#pragma - MMGridViewDataSource

- (CGSize)itemSizeInGridView:(MMGridView *)_
{
    return CGSizeMake(106, 92);
}

- (MMGridLayoutType)layoutTypeInGridView:(MMGridView *)_ {
    return layoutType;
}

- (NSUInteger)numberOfSectionsInGridLayout:(MMGridLayout *)layout
{
    return model.count;
}

- (NSMutableArray *)_pageAt:(NSUInteger)page {
    return [model objectAtIndex:page];
}

- (NSUInteger)gridLayout:(MMGridLayout *)layout numberOfCellsInSection:(NSUInteger)section {
    return [self _pageAt:section].count;
}

- (NSString *)_str4IndexPath:(NSIndexPath *)path {
    return [[self _pageAt:(NSUInteger)path.section] objectAtIndex:(NSUInteger)path.row];
}

- (MMGridViewCell *)gridView:(MMGridView *)_ cellAtIndexPath:(NSIndexPath *)indexPath
{
    MMGridViewDefaultCell *cell = [gridView dequeueReusableCellOfClass:[MMGridViewDefaultCell class]];
    if (cell == nil) {
        cell = [[[MMGridViewDefaultCell alloc] initWithFrame:CGRectMake(0, 0, 106, 92)] autorelease];
    }
    cell.textLabel.text = [self _str4IndexPath:indexPath];
    cell.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell-image.png"]];
    return cell;
}

// ----------------------------------------------------------------------------------

#pragma - MMGridViewDelegate

- (MMGridViewCell *)_replacementCell {
    MMGridViewDefaultCell *cell = [[[MMGridViewDefaultCell alloc] initWithFrame:CGRectNull] autorelease];
    cell.textLabel.text = [NSString stringWithFormat:@"<< Replacement >>"];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundView.backgroundColor = [UIColor redColor];
    cell.frame = CGRectMake(0, 0, 106, 92);
    return cell;
}

- (void)_removeStr4IndexPath:(NSIndexPath *)path {
    [[self _pageAt:(NSUInteger)path.section] removeObjectAtIndex:(NSUInteger)path.row];
}

- (void)gridView:(MMGridView *)_ didSelectCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [gridView deleteCell4IndexPath:indexPath withCompletion:^(BOOL f){
        NSLog(@"~ we did delete cell at indexPath: %@ ~", indexPath);
        [self _removeStr4IndexPath:indexPath];
    }];
//    AnyViewController *c = [[AnyViewController alloc] initWithNibName:@"AnyViewController" bundle:nil];
//    [self.navigationController pushViewController:c animated:YES];
//    [c release];
}


- (void)gridView:(MMGridView *)_ didDoubleTapCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:[NSString stringWithFormat:@"Cell at index %@ was double tapped.", indexPath]
                                                   delegate:nil 
                                          cancelButtonTitle:@"Cool!" 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}


- (void)gridView:(MMGridView *)theGridView changedPageToIndex:(NSUInteger)index
{
    [self setupPageControl];
}

@end
