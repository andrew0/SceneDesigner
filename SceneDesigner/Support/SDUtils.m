//
//  SDUtils.m
//  SceneDesigner
//

#import "SDUtils.h"
#import "SDDocument.h"
#import "SDNode.h"
#import "SDDrawingView.h"
#import "SDWindowController.h"

@implementation SDUtils

+ (id)sharedUtils
{
    static dispatch_once_t pred;
    static id shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _classesDicitonary = [[NSMutableDictionary alloc] initWithCapacity:5];
        [_classesDicitonary setObject:@"CCNode" forKey:@"SDNode"];
        [_classesDicitonary setObject:@"CCSprite" forKey:@"SDSprite"];
        [_classesDicitonary setObject:@"CCLayer" forKey:@"SDLayer"];
        [_classesDicitonary setObject:@"CCLayerColor" forKey:@"SDLayerColor"];
        [_classesDicitonary setObject:@"CCLabelBMFont" forKey:@"SDLabelBMFont"];
    }
    
    return self;
}

- (Class)customClassFromCocosClass:(Class)cocosClass
{
    NSArray *classes = [_classesDicitonary allKeysForObject:NSStringFromClass(cocosClass)];
    if ([classes count] > 0)
        return NSClassFromString([classes objectAtIndex:0]);
    
    return nil;
}

- (Class)cocosClassFromCustomClass:(Class)customClass
{
    return NSClassFromString([_classesDicitonary objectForKey:NSStringFromClass(customClass)]);
}

- (SDDocument *)currentDocument
{
    SDDocument *doc = [[NSDocumentController sharedDocumentController] currentDocument];
    if (![doc isKindOfClass:[SDDocument class]])
        return nil;
    
    return doc;
}

- (SDWindowController *)currentWindowController
{
    SDWindowController *wc = nil;
    
    NSArray *windows = [NSApp orderedWindows];
    if ([windows count] > 0)
    {
        for (NSWindow *window in windows)
        {
            NSWindowController *controller = [window windowController];
            if ([controller isKindOfClass:[SDWindowController class]])
            {
                wc = (SDWindowController *)controller;
                break;
            }
        }
    }
    
    return wc;
}

- (NSUndoManager *)currentUndoManager
{
    return [[self currentDocument] undoManager];
}

- (NSArray *)allNamesOfChildrenOfNode:(CCNode *)node
{
    NSMutableArray *array = [NSMutableArray array];
    for (CCNode<SDNodeProtocol> *child in [node children])
    {
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)] && [child name] != nil && ![[child name] isEqualToString:@""])
            [array addObject:[child name]];
        
        if ([[child children] count] > 0)
            [array addObjectsFromArray:[self allNamesOfChildrenOfNode:child]];
    }
    
    return [NSArray arrayWithArray:array];
}

- (NSString *)uniqueNameForString:(NSString *)string
{
    SDDocument *doc = [self currentDocument];
    NSArray *names = [self allNamesOfChildrenOfNode:[doc drawingView]];
    
    NSString *newString = [[string copy] autorelease];
    NSUInteger i = 1;
    while ([names containsObject:newString])
    {
        NSAssert(i < NSUIntegerMax, @"can't use same name %lu times", (unsigned long)NSUIntegerMax);
        newString = [string stringByAppendingFormat:@"%lu", (unsigned long)i++];
    }
    
    return newString;
}

- (NSArray *)allowedImageTypes
{
    return [NSArray arrayWithObjects:@"png", @"gif", @"jpg", @"jpeg", @"tif", @"tiff", @"bmp", @"ccz", @"pvr", nil];
}

@end
