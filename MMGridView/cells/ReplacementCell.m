#import "ReplacementCell.h"
#import "MMGridViewCell.h"
#import "MMGridViewCell+Private.h"

@implementation ReplacementCell

@synthesize origin;

+ (id)replacementCell4Origin:(MMGridViewCell *)origin
{
    if (origin == nil) return nil;

    ReplacementCell *replacement = [[ReplacementCell new] autorelease];
    replacement->origin = [origin retain];
    replacement.hidden = YES;
    replacement.userInteractionEnabled = NO;
    replacement.frame = CGRectMake(0, 0, 2, 2);
    replacement.center = origin.center;
    replacement.indexPath = origin.indexPath;
    replacement.gridView = origin.gridView;
    return replacement;
}

- (void)dealloc
{
    [origin release];
    [super dealloc];
}

@end