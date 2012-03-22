//
//  SDOutlineViewDataSource.m
//  SceneDesigner
//

#import "SDOutlineViewDataSource.h"
#import "SDDocument.h"
#import "SDDrawingView.h"
#import "SDNode.h"
#import "cocos2d.h"

@implementation SDOutlineViewDataSource

- (id)init
{
    self = [super init];
    if (self)
    {
        _array = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadDictionary:) name:@"NSOutlineViewWillReloadDataNotification" object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_array release];
    [super dealloc];
}

- (void)reloadDictionary:(NSNotification *)notification
{
    SDDocument *document = [_windowController document];
    if ([document isKindOfClass:[SDDocument class]])
        [_array setArray:[[self dictionaryForNode:[document drawingView]] objectForKey:CHILDREN_KEY]];
}

- (NSDictionary *)dictionaryForNode:(CCNode *)node
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:3];
    [dict setValue:NSStringFromClass([node superclass]) forKey:CLASS_NAME_KEY];
    [dict setValue:node forKey:NODE_KEY];
    
    NSMutableArray *array = [NSMutableArray array];
    if ([[node children] count] > 0)
        for (CCNode<SDNodeProtocol> *child in [node children])
            if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
                [array addObject:[self dictionaryForNode:child]];
    
    [dict setValue:array forKey:CHILDREN_KEY];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)sortArrayByZOrder:(NSMutableArray *)array
{
    NSComparisonResult (^comparator)(id obj1, id obj2) = ^NSComparisonResult(id obj1, id obj2) {
        CCNode *node1 = [obj1 objectForKey:NODE_KEY];
        CCNode *node2 = [obj2 objectForKey:NODE_KEY];
        
        CCNode *parent = [node1 parent];
        if ([node2 parent] != parent)
            return NSOrderedSame;
        
        // children array is automatically sorted by z order
        return [[NSNumber numberWithInteger:[[parent children] indexOfObject:node1]] compare:[NSNumber numberWithInteger:[[parent children] indexOfObject:node2]]];
    };
    
    [array sortUsingComparator:comparator];
    
    // reverse the array
    // we could use [[array reverseObjectEnumerator] allObjects], but that is not
    // guaranteed to be in the correct order
    if ([array count] > 1)
    {
        NSUInteger count = floorf([array count]/2.0f);
        NSUInteger maxIndex = [array count] - 1;
        for (NSUInteger i = 0; i < count; i++)
        {
            [array exchangeObjectAtIndex:i withObjectAtIndex:maxIndex];
            maxIndex--;
        }
    }
    
    // use recursion to sort children
    for (NSDictionary *dict in array)
    {
        if ([dict isKindOfClass:[NSDictionary class]])
        {
            NSMutableArray *children = [dict objectForKey:CHILDREN_KEY];
            if (children != nil && [children count] > 0)
                [self sortArrayByZOrder:children];
        }
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item != nil) ? [[item objectForKey:CHILDREN_KEY] count] : [_array count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
    {
        if ([_array count] > index)
        {
            [self sortArrayByZOrder:_array];
            return [_array objectAtIndex:index];
        }
        else
            return nil;
    }
    
    if (![item isKindOfClass:[NSDictionary class]])
        return nil;
    
    NSMutableArray *array = [item objectForKey:CHILDREN_KEY];
    [self sortArrayByZOrder:array];
    
    if ([array count] <= index)
        return nil;
    
    return [array objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (item != nil && [[item objectForKey:CHILDREN_KEY] count] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item objectForKey:CLASS_NAME_KEY];
}

@end
