#import <Foundation/Foundation.h>
#import "MMGridViewCell.h"

@interface MMGridViewCell (Private)
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, assign) MMGridView *gridView;
@end