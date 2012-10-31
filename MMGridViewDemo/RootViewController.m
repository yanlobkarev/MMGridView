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
    return MMGridLayoutPagedVertical;
}

- (NSUInteger)numberOfSectionsInGridLayout:(MMGridLayout *)layout
{
    return 5;
}

- (NSUInteger)gridLayout:(MMGridLayout *)layout numberOfCellsInSection:(NSUInteger)section {
    return 5;
}


- (MMGridViewCell *)gridView:(MMGridView *)_ cellAtIndexPath:(NSIndexPath *)indexPath
{
    MMGridViewDefaultCell *cell = [[[MMGridViewDefaultCell alloc] initWithFrame:CGRectNull] autorelease];
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d[%d]", indexPath.section, indexPath.row];
    cell.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell-image.png"]];
    cell.frame = CGRectMake(0, 0, 106, 92);
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

- (void)gridView:(MMGridView *)_ didSelectCell:(MMGridViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [gridView replaceCell:cell withCell:[self _replacementCell]];
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
