//
//  SDNode.m
//  SceneDesigner
//

#import "SDNode.h"
#import "CCNode+Additions.h"
#import <objc/objc-runtime.h>

@interface NSObject (Additions)
+ (BOOL)hasProperty:(NSString *)property;
@end

@implementation NSObject (Additions)
+ (BOOL)hasProperty:(NSString *)property
{
    BOOL retVal = NO;
    
    // iterate through all properties and check for given property
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList(self, &count);
    for (unsigned int i = 0; i < count; i++)
    {
        objc_property_t prop = properties[i];
        const char *name = property_getName(prop);
        
        NSString *propertyKey = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        if ([property isEqualToString:propertyKey])
        {
            retVal = YES;
            break;
        }
    }
    
    // free memory
    if (properties)
        free(properties);
    
    // recursively check superclasses if not found yet
    if (!retVal && [self superclass] != [NSObject class])
        return [[self superclass] hasProperty:property];
    
    return retVal;
}
@end

#pragma mark -

NSString *CCNodeDidReorderChildren = @"CCNodeDidReorderChildren";
NSString *SDNodeUTI = @"org.scenedesigner.node";

@interface SDNode ()
- (void)registerForKVO;
- (void)unregisterForKVO;
@end

@implementation SDNode

@synthesize node = _node;
@synthesize name = _name;
@dynamic positionX, positionY;
@dynamic anchorPointX, anchorPointY;
@dynamic contentSizeWidth, contentSizeHeight;

- (id)init
{
    self = [super init];
    if (self)
    {
        _undoKeyDictionary = [[NSMutableDictionary alloc] init];
        
        // value is the undo action name
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
        [dict setValue:@"" forKey:@"name"];
        [dict setValue:@"" forKey:@"position"];
        [dict setValue:@"" forKey:@"anchorPoint"];
        [dict setValue:@"" forKey:@"contentSize"];
        [dict setValue:@"" forKey:@"scaleX"];
        [dict setValue:@"" forKey:@"scaleY"];
        [dict setValue:@"" forKey:@"zOrder"];
        [dict setValue:@"" forKey:@"rotation"];
        [dict setValue:@"" forKey:@"tag"];
        [dict setValue:@"" forKey:@"visible"];
        [dict setValue:@"" forKey:@"isRelativeAnchorPoint"];
        [self registerKeysFromDictionary:dict];
        
        // default name
        [self setName:@"node"];
    }
    
    return self;
}

+ (Class)representedClass
{
    return [CCNode class];
}

+ (id)node
{
    CCNode *retVal = [CCNode node];
    retVal.SDNode = [[[self alloc] init] autorelease];
    [retVal.SDNode setNode:retVal];
    return retVal;
}

+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict
{
    [node.SDNode setName:[dict valueForKey:@"name"]];
    node.position = NSPointToCGPoint(NSPointFromString([dict valueForKey:@"position"]));
    node.anchorPoint = NSPointToCGPoint(NSPointFromString([dict valueForKey:@"anchorPoint"]));
    node.scaleX = [[dict valueForKey:@"scaleX"] floatValue];
    node.scaleY = [[dict valueForKey:@"scaleY"] floatValue];
    node.contentSize = NSSizeToCGSize(NSSizeFromString([dict valueForKey:@"contentSize"]));
    node.rotation = [[dict valueForKey:@"rotation"] floatValue];
    node.tag = [[dict valueForKey:@"tag"] integerValue];
    node.visible = [[dict valueForKey:@"visible"] boolValue];
    node.isRelativeAnchorPoint = [[dict valueForKey:@"isRelativeAnchorPoint"] boolValue];
    node.zOrder = [[dict valueForKey:@"zOrder"] integerValue];
    
    // add children
    NSArray *children = [dict objectForKey:@"children"];
    
    if (children == nil || ![children isKindOfClass:[NSArray class]])
        [NSException raise:@"SDNode" format:@"<%s> children key nonexistant or not array in dictionary:\n%@", __FUNCTION__, dict];
    
    for (NSDictionary *child in children)
    {
        Class childClass = [[SDUtils sharedUtils] customClassFromCocosClass:NSClassFromString([child valueForKey:@"className"])];
        if (childClass && [childClass isSubclassOfClass:[SDNode class]])
        {
            CCNode *newNode = [childClass nodeWithDictionaryRepresentation:child];
            [node addChild:newNode];
        }
    }
}

+ (id)nodeWithDictionaryRepresentation:(NSDictionary *)dict
{
    CCNode *retVal = [self node];
    if (retVal)
        [self setupNode:retVal withDictionaryRepresentation:dict];
    
    return retVal;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:12];
    [dict setValue:NSStringFromClass([_node class]) forKey:@"className"];
    [dict setValue:((self.name != nil) ? self.name : @"") forKey:@"name"];
    [dict setValue:NSStringFromPoint(NSPointFromCGPoint(_node.position)) forKey:@"position"];
    [dict setValue:NSStringFromPoint(NSPointFromCGPoint(_node.anchorPoint)) forKey:@"anchorPoint"];
    [dict setValue:[NSNumber numberWithFloat:_node.scaleX] forKey:@"scaleX"];
    [dict setValue:[NSNumber numberWithFloat:_node.scaleY] forKey:@"scaleY"];
    [dict setValue:NSStringFromSize(NSSizeFromCGSize(_node.contentSize)) forKey:@"contentSize"];
    [dict setValue:[NSNumber numberWithInteger:_node.zOrder] forKey:@"zOrder"];
    [dict setValue:[NSNumber numberWithFloat:_node.rotation] forKey:@"rotation"];
    [dict setValue:[NSNumber numberWithInteger:_node.tag] forKey:@"tag"];
    [dict setValue:[NSNumber numberWithBool:_node.visible] forKey:@"visible"];
    [dict setValue:[NSNumber numberWithBool:_node.isRelativeAnchorPoint] forKey:@"isRelativeAnchorPoint"];
    
    NSMutableArray *children = [NSMutableArray array];
    if ([[_node children] count] > 0)
        for (CCNode *child in [_node children])
            if ([child isKindOfClass:[CCNode class]] && [child isSDNode])
                [children addObject:[child.SDNode dictionaryRepresentation]];
    
    [dict setValue:children forKey:@"children"];
    
    return dict;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSDictionary *dict = [aDecoder decodeObjectForKey:@"dictionaryRepresentation"];
    if (!dict)
        return nil;
    
    self = [self init];
    if (self)
    {
        CCNode *node = [[[self class] representedClass] node];
        node.SDNode = self;
        self.node = node;
        // XXX: very hacky, have to do this because node property is not retained
        [node retain];
        
        [[self class] setupNode:node withDictionaryRepresentation:dict];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[self dictionaryRepresentation] forKey:@"dictionaryRepresentation"];
}

- (void)dealloc
{
    [self setNode:nil];
    [_undoKeyDictionary release];
    [self setName:nil];
    [super dealloc];
}

- (void)registerKeysFromDictionary:(NSDictionary *)dict
{
    [_undoKeyDictionary addEntriesFromDictionary:dict];
    
    // update current node
    [self unregisterForKVO];
    [self registerForKVO];
}

#pragma mark -
#pragma mark KVO

- (void)registerForKVO
{
    for (NSString *key in [_undoKeyDictionary allKeys])
    {
        @try
        {
            [_node addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        }
        @catch (id exception)
        {
            [self addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        }
    }
}

- (void)unregisterForKVO
{
    for (NSString *key in [_undoKeyDictionary allKeys])
        [_node removeObserver:self forKeyPath:key];
}

- (NSUndoManager *)undoManager
{
    return [[[[[[CCDirector sharedDirector] view] window] windowController] document] undoManager];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    if (oldValue == [NSNull null])
        oldValue = nil;
    
    // if old value exists, add it to undo stack for the document's undo manager
    [[[self undoManager] prepareWithInvocationTarget:object] setValue:oldValue forKeyPath:keyPath];
    
    // set action name if applicable
    NSString *actionName = [_undoKeyDictionary valueForKey:keyPath];
    if (actionName != nil && [actionName isKindOfClass:[NSString class]] && ![actionName isEqualToString:@""])
        [[self undoManager] setActionName:actionName];
}

- (void)setNode:(CCNode *)node
{
    if (node != _node)
    {
        [self unregisterForKVO];
        _node = node;
//        [_node release];
//        _node = [node retain];
        [self registerForKVO];
    }
}

#pragma mark -
#pragma mark Custom Setters/Getters

- (void)setName:(NSString *)name
{
    NSString *uniqueName = [[SDUtils sharedUtils] uniqueNameForString:name];
    if (![uniqueName isEqualToString:[self name]])
    {
        [_name release];
        _name = [uniqueName copy];
    }
}

- (CGFloat)positionX
{
    return [_node position].x;
}

- (void)setPositionX:(CGFloat)positionX
{
    if (positionX != [self positionX])
    {
        CGPoint position = [_node position];
        position.x = positionX;
        [_node setPosition:position];
    }
}

- (CGFloat)positionY
{
    return [_node position].y;
}

- (void)setPositionY:(CGFloat)positionY
{
    if (positionY != [self positionX])
    {
        CGPoint position = [_node position];
        position.y = positionY;
        [_node setPosition:position];
    }
}

- (CGFloat)anchorPointX
{
    return [_node anchorPoint].x;
}

- (void)setAnchorPointX:(CGFloat)anchorPointX
{
    if (anchorPointX != [self anchorPointX])
    {
        CGPoint anchorPoint = [_node anchorPoint];
        anchorPoint.x = anchorPointX;
        [_node setAnchorPoint:anchorPoint];
    }
}

- (CGFloat)anchorPointY
{
    return [_node anchorPoint].y;
}

- (void)setAnchorPointY:(CGFloat)anchorPointY
{
    if (anchorPointY != [self anchorPointY])
    {
        CGPoint anchorPoint = [_node anchorPoint];
        anchorPoint.y = anchorPointY;
        [_node setAnchorPoint:anchorPoint];
    }
}

- (CGFloat)contentSizeWidth
{
    return [_node contentSize].width;
}

- (void)setContentSizeWidth:(CGFloat)contentSizeWidth
{
    if (contentSizeWidth != [self contentSizeWidth])
    {
        CGSize size = [_node contentSize];
        size.width = contentSizeWidth;
        [_node setContentSize:size];
    }
}

- (CGFloat)contentSizeHeight
{
    return [_node contentSize].height;
}

- (void)setContentSizeHeight:(CGFloat)contentSizeHeight
{
    if (contentSizeHeight != [self contentSizeHeight])
    {
        CGSize size = [_node contentSize];
        size.height = contentSizeHeight;
        [_node setContentSize:size];
    }
}

#pragma mark -
#pragma mark KVC

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSMutableSet *keyPaths = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingValueForKey:key]];
    
    // some properties (such as positionX and positionY) are dynamic variables, and are affected by their corresponding
    // (e.g. position) properties. adding them to the set of keyPaths allows bindings and KVC to work properly with them
    if ([key isEqualToString:@"positionX"] || [key isEqualToString:@"positionY"])
        [keyPaths addObject:@"position"];
    else if ([key isEqualToString:@"anchorPointX"] || [key isEqualToString:@"anchorPointY"])
        [keyPaths addObject:@"anchorPoint"];
    else if ([key isEqualToString:@"contentSizeWidth"] || [key isEqualToString:@"contentSizeHeight"])
        [keyPaths addObject:@"contentSize"];
    
    // SDNodes are used as proxies for bindings to CCNodes, so if the key is part of the represented node, then it must
    // be added to the keyPaths
    if ([[self representedClass] hasProperty:key])
        [keyPaths addObject:[NSString stringWithFormat:@"node.%@", key]];
    
    return keyPaths;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    @try
    {
        [_node setValue:value forKey:key];
    }
    @catch (id exception) {}
}

- (id)valueForUndefinedKey:(NSString *)key
{
    id retVal = nil;
    
    @try
    {
        retVal = [_node valueForKey:key];
    }
    @catch (id exception) {}
    
    return retVal;
}

#pragma mark -
#pragma mark Copy/Paste Support

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [NSArray arrayWithObject:SDNodeUTI];
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
    if ([type isEqualToString:SDNodeUTI])
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    
    return nil;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard
{
    return [NSArray arrayWithObject:SDNodeUTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard
{
    if ([type isEqualToString:SDNodeUTI])
        return NSPasteboardReadingAsKeyedArchive;
    
    return 0;
}

#pragma mark -

- (NSArray *)snapPoints
{
    if (floorf([_node rotation]) != [_node rotation] || (int)floorf([_node rotation]) % 360 != 0 || [_node scaleX] != 1 || [_node scaleY] != 1 || ![_node visible])
        return [NSArray array];
    
    CGSize s = [_node contentSize];
    CGPoint p1 = [_node convertToWorldSpace:ccp(0,0)]; /*bl*/
    CGPoint p2 = [_node convertToWorldSpace:ccp(s.width,0)]; /*br*/
    CGPoint p3 = [_node convertToWorldSpace:ccp(s.width,s.height)]; /*tr*/
    CGPoint p4 = [_node convertToWorldSpace:ccp(0,s.height)]; /*tl*/
    
    NSMutableArray *snapPoints = [NSMutableArray arrayWithCapacity:4];
    [snapPoints addObject:[NSValue value:&p1 withObjCType:@encode(CGPoint)]];
    [snapPoints addObject:[NSValue value:&p2 withObjCType:@encode(CGPoint)]];
    [snapPoints addObject:[NSValue value:&p3 withObjCType:@encode(CGPoint)]];
    [snapPoints addObject:[NSValue value:&p4 withObjCType:@encode(CGPoint)]];

    return snapPoints;
}

@end