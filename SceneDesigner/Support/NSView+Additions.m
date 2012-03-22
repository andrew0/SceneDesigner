//
//  NSView+Additions.m
//  SceneDesigner
//

#import "NSView+Additions.h"

@implementation NSView (Additions)

+ (NSView *)viewFromNibNamed:(NSString *)nibName withOwner:(id)owner
{
    if ([nibName isEqualToString:@""] || nibName == nil)
        return nil;
    
    NSNib *nib = [[[NSNib alloc] initWithNibNamed:nibName bundle:nil] autorelease];
    NSArray *topLevelObjects;
    if (![nib instantiateNibWithOwner:owner topLevelObjects:&topLevelObjects])
        return nil;
    
    for (NSView *view in topLevelObjects)
        if ([view isKindOfClass:[NSView class]])
            return view;
    
    return nil;
}

@end
