/*
 SDReader.m
 
 Copyright (c) 2012 andrew0
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 
 3. This notice may not be removed or altered from any source
 distribution.
 */

#import "SDReader.h"

static inline ccColor3B ColorFromNSString(NSString *string)
{
    ccColor3B color;
    sscanf([string cStringUsingEncoding:NSUTF8StringEncoding], "{%u, %u, %u}", &color.r, &color.g, &color.b);
    return color;
}

@interface CCNode (Private)
- (void)_setZOrder:(NSInteger)z;
@end

@interface SDReader ()
- (void)validateArray:(NSArray *)array;
- (CCNode *)nodeForDictionary:(NSDictionary *)dict;
- (CCNode *)nodeNamed:(NSString *)name inArray:(NSArray *)array;
- (NSString *)nameForTag:(NSInteger)tag inArray:(NSArray *)array;
@end

@implementation SDReader

+ (id)readerWithFile:(NSString *)file
{
    return [[[self alloc] initWithFile:file] autorelease];
}

+ (id)readerWithURL:(NSURL *)url
{
    return [self readerWithFile:[url path]];
}

- (id)init
{
    NSAssert(NO, @"SDReader: use designated initializer initWithFile:");
    return nil;
}

- (id)initWithFile:(NSString *)file
{
    self = [super init];
    if (self)
    {
        // try to get full path of file
        NSString *path = [[NSBundle mainBundle] pathForResource:[file stringByDeletingPathExtension] ofType:[file pathExtension]];
        
        // try to get dictionary
        _array = [[NSArray arrayWithContentsOfFile:path] retain];
        if (_array == nil)
        {
            NSAssert(NO, @"SDReader: file %@ non-existant or not a property list", path);
            return nil;
        }
        
        // search for errors in array
        [self validateArray:_array];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)validateArray:(NSArray *)array
{
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *dict in array)
    {
        NSAssert([dict isKindOfClass:[NSDictionary class]], @"SDReader: children array contains non-dictionary child");
        
        NSString *className = [dict valueForKey:@"className"];
        NSAssert(className != nil, @"SDReader: dictionary does not contain className key");
        NSAssert([className isKindOfClass:[NSString class]], @"SDReader: className value is not a string");
        NSAssert(NSClassFromString(className) != nil, @"SDReader: class named \"%@\" not found", className);
        NSAssert([NSClassFromString(className) isSubclassOfClass:[CCNode class]], @"SDReader: class named \"%@\" not a subclass of CCNode", className);
        
        NSAssert([dict valueForKey:@"children"] != nil, @"SDReader: dictionary does not contain children key");
        NSAssert([[dict valueForKey:@"children"] isKindOfClass:[NSArray class]], @"SDReader: children value is not an array");
        
        NSString *name = [dict valueForKey:@"name"];
        NSAssert(name != nil, @"SDReader: dictionary does not contain name key");
        NSAssert([name isKindOfClass:[NSString class]], @"SDReader: name value is not a string");
        NSAssert(![names containsObject:name], @"SDReader: duplicate name \"%@\"", name);
        
        [self validateArray:[dict valueForKey:@"children"]];
    }
}

- (CCNode *)nodeForDictionary:(NSDictionary *)dict
{
    CCNode *retVal = nil;
    
    NSString *className = [dict valueForKey:@"className"];
    if ([className isEqualToString:@"CCNode"])
        retVal = [CCNode node];
    else if ([className isEqualToString:@"CCSprite"])
        retVal = [CCSprite node];
    else if ([className isEqualToString:@"CCLayer"])
        retVal = [CCLayer node];
    else if ([className isEqualToString:@"CCLayerColor"])
        retVal = [CCLayerColor node];
    
    Class nodeClass = NSClassFromString(className);
    if ([nodeClass isSubclassOfClass:[CCNode class]])
    {
        retVal.position = CGPointFromString([dict valueForKey:@"position"]);
        retVal.anchorPoint = CGPointFromString([dict valueForKey:@"anchorPoint"]);
        retVal.scaleX = [[dict valueForKey:@"scaleX"] floatValue];
        retVal.scaleY = [[dict valueForKey:@"scaleY"] floatValue];
        retVal.contentSize = CGSizeFromString([dict valueForKey:@"contentSize"]);
        [retVal _setZOrder:[[dict valueForKey:@"zOrder"] integerValue]];
        retVal.rotation = [[dict valueForKey:@"rotation"] floatValue];
        retVal.tag = [[dict valueForKey:@"tag"] integerValue];
        retVal.visible = [[dict valueForKey:@"visible"] boolValue];
        retVal.isRelativeAnchorPoint = [[dict valueForKey:@"isRelativeAnchorPoint"] boolValue];
    }
    if ([nodeClass isSubclassOfClass:[CCSprite class]])
    {
        CCSprite *sprite = (CCSprite *)retVal;
        
        NSString *path = [dict valueForKey:@"path"];
        NSURL *url = [NSURL URLWithString:path];
        NSAssert([[NSFileManager defaultManager] fileExistsAtPath:path], @"SDReader: could not find sprite \"%@\"", [url relativeString]);
        
        sprite.texture = [[CCTextureCache sharedTextureCache] addImage:[url relativeString]];
        sprite.textureRect = CGRectFromString([dict valueForKey:@"textureRect"]);
        sprite.opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
        sprite.color = ColorFromNSString([dict valueForKey:@"color"]);
        sprite.flipX = [[dict valueForKey:@"flipX"] boolValue];
        sprite.flipY = [[dict valueForKey:@"flipY"] boolValue];
    }
    if ([nodeClass isSubclassOfClass:[CCLayer class]])
    {
        CCLayer *layer = (CCLayer *)retVal;
#ifdef __CC_PLATFORM_IOS
        layer.isAccelerometerEnabled = [[dict valueForKey:@"isAccelerometerEnabled"] boolValue];
#elif defined(__CC_PLATFORM_MAC)
        layer.isMouseEnabled = [[dict valueForKey:@"isMouseEnabled"] boolValue];
        layer.isKeyboardEnabled = [[dict valueForKey:@"isKeyboardEnabled"] boolValue];
#endif
        layer.isTouchEnabled = [[dict valueForKey:@"isTouchEnabled"] boolValue];
        layer.contentSize = CGSizeFromString([dict valueForKey:@"contentSize"]);
    }
    if ([nodeClass isSubclassOfClass:[CCLayerColor class]])
    {
        CCLayerColor *layer = (CCLayerColor *)retVal;
        [layer setColor:ColorFromNSString([dict valueForKey:@"color"])];
        [layer setOpacity:[[dict valueForKey:@"opacity"] unsignedCharValue]];
    }
    
    NSArray *children = [dict valueForKey:@"children"];
    if ([children count] > 0)
        for (NSDictionary *child in children)
            [retVal addChild:[self nodeForDictionary:child]];
    
    return retVal;
}

- (CCScene *)scene
{
    CCScene *retVal = [CCScene node];
    for (NSDictionary *child in _array)
    {
        CCNode *node = [self nodeForDictionary:child];
        if (node)
            [retVal addChild:node];
    }
    
    return retVal;
}

- (CCNode *)nodeNamed:(NSString *)name inArray:(NSArray *)array
{
    CCNode *retVal = nil;
    
    for (NSDictionary *child in array)
    {
        NSString *dictName = [child valueForKey:@"name"];
        if ([dictName isEqualToString:name])
            retVal = [self nodeForDictionary:child];
        else
            retVal = [self nodeNamed:name inArray:[child valueForKey:@"children"]];
        
        if (retVal != nil)
            break;
    }
        
    return retVal;
}

- (CCNode *)nodeNamed:(NSString *)name
{
    return [self nodeNamed:name inArray:_array];
}

- (NSString *)nameForTag:(NSInteger)tag inArray:(NSArray *)array
{
    NSString *retVal = @"";
    
    for (NSDictionary *child in array)
    {
        if ([[child valueForKey:@"tag"] integerValue] == tag)
        {
            retVal = [child valueForKey:@"name"];
            break;
        }
        
        NSArray *children = [child valueForKey:@"children"];
        if ([children count] > 0)
            retVal = [self nameForTag:tag inArray:children];
    }
    
    return retVal;
}

- (CCNode *)nodeForTag:(NSInteger)tag
{
    return [self nodeNamed:[self nameForTag:tag inArray:_array]];
}

@end
