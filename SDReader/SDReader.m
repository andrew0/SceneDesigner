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

#ifdef __CC_PLATFORM_MAC
#define CGSizeFromString(__s__) NSSizeToCGSize(NSSizeFromString(__s__))
#endif

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

@synthesize sceneSize = _sceneSize;

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
        
        // find project.plist
        NSString *plist = [path stringByAppendingPathComponent:@"project.plist"];
        
        // try to get dictionary
        _dictionary = [[NSDictionary dictionaryWithContentsOfFile:plist] retain];
        
        // try without sceneproj
        if (!_dictionary)
        {
            path = [[NSBundle mainBundle] pathForResource:@"project" ofType:@"plist"];
            _dictionary = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
        }
        
        NSAssert(_dictionary != nil, @"SDReader: could not find project.plist in %@; make sure you are not using json (unsupported)", path);
        
        _array = [[_dictionary objectForKey:@"children"] retain];
        NSAssert(_array != nil, @"SDReader: file %@ does not contain children array", path);
        
        _sceneSize = CGSizeFromString([_dictionary objectForKey:@"sceneSize"]);
        if (_sceneSize.width <= 0)
            _sceneSize.width = 480;
        if (_sceneSize.height <= 0)
            _sceneSize.height = 320;
        
        // search for errors in array
        [self validateArray:_array];
    }
    
    return self;
}

- (void)dealloc
{
    [_dictionary release];
    [_array release];
    [super dealloc];
}

- (void)validateArray:(NSArray *)array
{
    NSMutableArray *names = [NSMutableArray array];
    for (NSDictionary *dict in array)
    {
        NSAssert([dict isKindOfClass:[NSDictionary class]], @"SDReader: children array contains non-dictionary child");
        
        NSString *className = [dict objectForKey:@"className"];
        NSAssert(className != nil, @"SDReader: dictionary does not contain className key");
        NSAssert([className isKindOfClass:[NSString class]], @"SDReader: className value is not a string");
        NSAssert(NSClassFromString(className) != nil, @"SDReader: class named \"%@\" not found", className);
        NSAssert([NSClassFromString(className) isSubclassOfClass:[CCNode class]], @"SDReader: class named \"%@\" not a subclass of CCNode", className);
        
        NSAssert([dict objectForKey:@"children"] != nil, @"SDReader: dictionary does not contain children key");
        NSAssert([[dict objectForKey:@"children"] isKindOfClass:[NSArray class]], @"SDReader: children value is not an array");
        
        NSString *name = [dict objectForKey:@"name"];
        NSAssert(name != nil, @"SDReader: dictionary does not contain name key");
        NSAssert([name isKindOfClass:[NSString class]], @"SDReader: name value is not a string");
        NSAssert(![names containsObject:name], @"SDReader: duplicate name \"%@\"", name);
        
        [names addObject:name];
        
        [self validateArray:[dict objectForKey:@"children"]];
    }
}

- (CCNode *)nodeForDictionary:(NSDictionary *)dict
{
    CCNode *retVal = nil;
    
    NSString *className = [dict objectForKey:@"className"];
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
        retVal.position = CGPointFromString([dict objectForKey:@"position"]);
        retVal.anchorPoint = CGPointFromString([dict objectForKey:@"anchorPoint"]);
        retVal.scaleX = [[dict objectForKey:@"scaleX"] floatValue];
        retVal.scaleY = [[dict objectForKey:@"scaleY"] floatValue];
        retVal.contentSize = CGSizeFromString([dict objectForKey:@"contentSize"]);
        [retVal _setZOrder:[[dict objectForKey:@"zOrder"] integerValue]];
        retVal.rotation = [[dict objectForKey:@"rotation"] floatValue];
        retVal.tag = [[dict objectForKey:@"tag"] integerValue];
        retVal.visible = [[dict objectForKey:@"visible"] boolValue];
        
        id ignoreAnchorPointForPosition;
        if ([dict objectForKey:@"ignoreAnchorPointForPosition"] != nil)
            ignoreAnchorPointForPosition = [dict objectForKey:@"ignoreAnchorPointForPosition"];
        else
            ignoreAnchorPointForPosition = [NSNumber numberWithBool:![[dict objectForKey:@"isRelativeAnchorPoint"] boolValue]];
        
        id isRelativeAnchorPoint = [NSNumber numberWithBool:![ignoreAnchorPointForPosition boolValue]];
        
        if ([retVal respondsToSelector:@selector(setIgnoreAnchorPointForPosition:)])
            [retVal setValue:ignoreAnchorPointForPosition forKey:@"ignoreAnchorPointForPosition"];
        else
            [retVal setValue:isRelativeAnchorPoint forKey:@"isRelativeAnchorPoint"];
    }
    if ([nodeClass isSubclassOfClass:[CCSprite class]])
    {
        CCSprite *sprite = (CCSprite *)retVal;
        
        NSString *path = [dict objectForKey:@"path"];
        CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage:path];
        NSAssert(tex, @"SDReader: Unable to load texture for %@. Try removing your scene project and readding it if you recently added a new image to your project.");
        
        sprite.texture = tex;
        sprite.textureRect = CGRectFromString([dict objectForKey:@"textureRect"]);
        sprite.opacity = [[dict objectForKey:@"opacity"] unsignedCharValue];
        sprite.color = ColorFromNSString([dict objectForKey:@"color"]);
        sprite.flipX = [[dict objectForKey:@"flipX"] boolValue];
        sprite.flipY = [[dict objectForKey:@"flipY"] boolValue];
    }
    if ([nodeClass isSubclassOfClass:[CCLayer class]])
    {
        CCLayer *layer = (CCLayer *)retVal;
#ifdef __CC_PLATFORM_IOS
        layer.isAccelerometerEnabled = [[dict objectForKey:@"isAccelerometerEnabled"] boolValue];
#elif defined(__CC_PLATFORM_MAC)
        layer.isMouseEnabled = [[dict objectForKey:@"isMouseEnabled"] boolValue];
        layer.isKeyboardEnabled = [[dict objectForKey:@"isKeyboardEnabled"] boolValue];
#endif
        layer.isTouchEnabled = [[dict objectForKey:@"isTouchEnabled"] boolValue];
        layer.contentSize = CGSizeFromString([dict objectForKey:@"contentSize"]);
    }
    if ([nodeClass isSubclassOfClass:[CCLayerColor class]])
    {
        CCLayerColor *layer = (CCLayerColor *)retVal;
        [layer setColor:ColorFromNSString([dict objectForKey:@"color"])];
        [layer setOpacity:[[dict objectForKey:@"opacity"] unsignedCharValue]];
    }
    
    NSArray *children = [dict objectForKey:@"children"];
    if ([children count] > 0)
        for (NSDictionary *child in children)
            [retVal addChild:[self nodeForDictionary:child]];
    
    return retVal;
}

- (CCScene *)scene
{
    CCScene *retVal = [CCScene node];
    retVal.contentSize = _sceneSize;
    
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
        NSString *dictName = [child objectForKey:@"name"];
        if ([dictName isEqualToString:name])
            retVal = [self nodeForDictionary:child];
        else
            retVal = [self nodeNamed:name inArray:[child objectForKey:@"children"]];
        
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
        if ([[child objectForKey:@"tag"] integerValue] == tag)
        {
            retVal = [child objectForKey:@"name"];
            break;
        }
        
        NSArray *children = [child objectForKey:@"children"];
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
