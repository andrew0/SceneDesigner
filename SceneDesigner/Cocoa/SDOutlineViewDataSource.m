//
//  SDOutlineViewDataSource.m
//  SceneDesigner
//

#import "SDOutlineViewDataSource.h"
#import "SDDocument.h"
#import "SDDrawingView.h"
#import "SDNode.h"
#import "cocos2d.h"
#import "SDOutlineView.h"
#import "CCNode+Additions.h"

@implementation SDOutlineViewDataSource

- (CCArray *)childrenOfNode:(CCNode *)node
{
    if (!node)
        return nil;
    
    // create copy of children since we're going to mutate it
    CCArray *children = [node children];
    CCArray *retVal = [[children copy] autorelease];
    
    // remove all nodes that are not SDNodes
    for (id child in children)
        if (![child isKindOfClass:[CCNode class]] || ![child isSDNode])
            [retVal removeObject:child];
    
    // reverse the array
    // we could use [[array reverseObjectEnumerator] allObjects], but that is not
    // guaranteed to be in the correct order
    if ([retVal count] > 1)
    {
        NSUInteger count = floorf([retVal count]/2.0f);
        NSUInteger maxIndex = [retVal count] - 1;
        for (NSUInteger i = 0; i < count; i++)
        {
            [retVal exchangeObjectAtIndex:i withObjectAtIndex:maxIndex];
            maxIndex--;
        }
    }
    
    return retVal;
}

- (CCArray *)drawingViewChildren
{
    // ensure document is SDDocument
    SDDocument *document = [_windowController document];
    if (![document isKindOfClass:[SDDocument class]])
        return nil;
    
    return [self childrenOfNode:[document drawingView]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
        return [[self drawingViewChildren] count];
    
    if (![item isKindOfClass:[CCNode class]] || ![item isSDNode])
        return 0;
    
    return [[self childrenOfNode:item] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    // if there is no item (no parent), then get nodes from root
    if (!item)
    {
        CCArray *rootChildren = [self drawingViewChildren];
        return ([rootChildren count] > index) ? [rootChildren objectAtIndex:index] : nil;
    }
    
    if (![item isKindOfClass:[CCNode class]] || ![item isSDNode])
        return nil;
    
    CCArray *childrenOfItem = [self childrenOfNode:item];
    return ([childrenOfItem count] > index) ? [childrenOfItem objectAtIndex:index] : nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (!item || ![item isKindOfClass:[CCNode class]] || ![item isSDNode])
        return NO;
    
    return [[self childrenOfNode:item] count] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (!item || ![item isKindOfClass:[CCNode class]] || ![item isSDNode])
        return @"fail";
    
    // get class name and append name if applicable
    NSMutableString *string = [NSMutableString stringWithString:NSStringFromClass([item class])];
    NSString *name = [[item SDNode] name];
    if (name != nil && ![name isEqualToString:@""])
    {
        [string appendString:@" - "];
        [string appendString:name];
    }
    
    return [NSString stringWithString:string];
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{}

@end
