//
//  SDDocument.m
//  SceneDesigner
//

#import "SDDocument.h"
#import "SDWindowController.h"
#import "SDDrawingView.h"
#import "SDNode.h"
#import "AppDelegate.h"
#import "JSONKit.h"

@implementation SDDocument

@synthesize drawingView = _drawingView;
@dynamic allResourceNames;

- (id)init
{
    self = [super init];
    if (self)
    {
        _sceneSizeToSet = NSMakeSize(-1, -1);
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

// TODO: put this logic in makeWindowControllers and set drawing view in init
- (void)setDrawingView:(SDDrawingView *)drawingView
{
    if (drawingView != _drawingView)
    {
        [_drawingView release];
        _drawingView = [drawingView retain];
        
        [[self undoManager] disableUndoRegistration];
        
        if (_sceneSizeToSet.width > 0)
            [_drawingView setSceneWidth:_sceneSizeToSet.width];
        
        if (_sceneSizeToSet.height > 0)
            [_drawingView setSceneHeight:_sceneSizeToSet.height];
        
        if ([[self windowControllers] count] > 0)
        {
            SDWindowController *wc = (SDWindowController *)[[self windowControllers] objectAtIndex:0];
            
            for (CCNode<SDNodeProtocol> *node in _nodesToAdd)
                [wc addNodeToLayer:node];
        }
        else
        {
            CCLOG(@"%s - no window controllers found", __FUNCTION__);
        }
        
        [[self undoManager] enableUndoRegistration];
        
        [_nodesToAdd release];
        _nodesToAdd = nil;
    }
}

- (void)makeWindowControllers
{
    SDWindowController *wc = [[SDWindowController alloc] initWithWindowNibName:@"SDDocument"];
    [self addWindowController:wc];
    [wc release];
}

- (NSString *)displayName
{
    // Apple's HIG say that untitled documents should say "untitled," not "Untitled"
    // NSDocument violates this, however. [self fileURL] will be nil if the file
    // is unsaved, which means it's untitled. In that case, we replace the first
    // character with a lowercase version
    
    NSMutableString *displayName = [NSMutableString stringWithString:[super displayName]];
    
    if ([self fileURL] == nil)
    {
        NSString *firstCharacter = [[displayName substringToIndex:1] lowercaseString];
        [displayName deleteCharactersInRange:NSMakeRange(0, 1)];
        [displayName insertString:firstCharacter atIndex:0];
    }
    
	return [NSString stringWithString:displayName];
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[[_drawingView children] count]];
    
    for (CCNode<SDNodeProtocol> *child in [_drawingView children])
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
            [array addObject:[child dictionaryRepresentation]];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setValue:NSStringFromSize(NSMakeSize([_drawingView sceneWidth], [_drawingView sceneHeight])) forKey:@"sceneSize"];
    [dict setValue:array forKey:@"children"];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSArray *)allResourceNames
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryRepresentation]];
    NSDictionary *resources = [self dataFromDictionaryRepresentation:dict];
    return [resources allKeys];
}

- (NSDictionary *)dataFromDictionaryRepresentation:(NSDictionary *)dict
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    id data = [dict objectForKey:@"data"];
    id key = [dict objectForKey:@"path"];
    
    if (data && key && [data isKindOfClass:[NSData class]] && [key isKindOfClass:[NSString class]])
        [ret setObject:data forKey:[key lastPathComponent]];
    
    NSArray *children = [dict objectForKey:@"children"];
    if (children)
    {
        for (NSDictionary *child in children)
        {
            NSDictionary *childData = [self dataFromDictionaryRepresentation:child];
            for (NSString *k in [childData allKeys])
                if (![ret objectForKey:k])
                    [ret setObject:[childData objectForKey:k] forKey:k];
        }
    }
    
    return ret;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError
{
    // create directories
    NSFileWrapper *mainDirectory = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil] autorelease];
    NSFileWrapper *resourcesDirectory = [[[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil] autorelease];
    [resourcesDirectory setPreferredFilename:@"resources"];
    
    // make nsdata
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[self dictionaryRepresentation]];
    NSDictionary *resources = [self dataFromDictionaryRepresentation:dict];
    [[SDUtils sharedUtils] removeObjectsWithKey:@"data" fromDictionaryRepresentation:dict];
    
    NSData *data;
    if ([typeName isEqualToString:@"JSON"])
    {
        data = [dict JSONData];
        [mainDirectory addRegularFileWithContents:data preferredFilename:@"project.json"];
    }
    else
    {
        data = [NSPropertyListSerialization dataWithPropertyList:dict format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
        [mainDirectory addRegularFileWithContents:data preferredFilename:@"project.plist"];
    }
    
    // add resources
    for (NSString *key in [resources allKeys])
        [resourcesDirectory addRegularFileWithContents:[resources objectForKey:key] preferredFilename:key];
    
    // add resources to main directory
    [mainDirectory addFileWrapper:resourcesDirectory];
    
    return mainDirectory;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError
{
    [[SDUtils sharedUtils] setLoadingDocument:self];
    
    [[self undoManager] disableUndoRegistration];
    
    NSDictionary *files = [fileWrapper fileWrappers];
    
    NSFileWrapper *resources = [files objectForKey:@"resources"];
    if (!resources)
    {
        NSLog(@"%s project file has no resources folder", __FUNCTION__);
        return NO;
    }
    
    NSFileWrapper *json = [files objectForKey:@"project.json"];
    NSFileWrapper *propertyList = [files objectForKey:@"project.plist"];
    
    NSDictionary *dict;
    if (json)
        dict = [[json regularFileContents] objectFromJSONData];
    else if (propertyList)
        dict = [NSPropertyListSerialization propertyListWithData:[propertyList regularFileContents] options:NSPropertyListImmutable format:NULL error:outError];
    else
    {
        NSLog(@"%s project file has no project.json or project.plist", __FUNCTION__);
        return NO;
    }
    
    // ensure that file is a dictionary
    if (![dict isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"%s property list or JSON not a dictionary", __FUNCTION__);
        return NO;
    }
    
    // get scene size from dictionary
    NSString *size = [dict valueForKey:@"sceneSize"];
    if (!size || ![size isKindOfClass:[NSString class]])
    {
        NSLog(@"%s sceneSize is not a string", __FUNCTION__);
        return NO;
    }
    
    _sceneSizeToSet = NSSizeFromString(size);
    
    // get children array from dictionary and ensure it is an array
    NSArray *children = [dict valueForKey:@"children"];
    if (children == nil || ![children isKindOfClass:[NSArray class]])
    {
        NSLog(@"%s children is not an array", __FUNCTION__);
        return NO;
    }
    
    // add nodes to drawing view
    _nodesToAdd = [[NSMutableArray arrayWithCapacity:[children count]] retain];
    for (NSDictionary *child in children)
    {
        Class childClass = [[SDUtils sharedUtils] customClassFromCocosClass:NSClassFromString([child objectForKey:@"className"])];
        
        if (childClass && [childClass isSubclassOfClass:[CCNode class]] && [childClass conformsToProtocol:@protocol(SDNodeProtocol)])
        {
            CCNode<SDNodeProtocol> *node = [[[childClass alloc] initWithDictionaryRepresentation:child] autorelease];
            if (node)
                [_nodesToAdd addObject:node];
        }
    }
    
    [[self undoManager] enableUndoRegistration];
    
    [[SDUtils sharedUtils] setLoadingDocument:nil];
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

@end
