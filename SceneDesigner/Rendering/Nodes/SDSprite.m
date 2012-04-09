//
//  SDSprite.m
//  SceneDesigner
//

#import "SDSprite.h"
#import "ColorFunctions.h"
#import "CCNode+Additions.h"

@implementation SDSprite

@synthesize path = _path;
@dynamic textureRectX;
@dynamic textureRectY;
@dynamic textureRectWidth;
@dynamic textureRectHeight;
@dynamic colorObject;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
        [dict setValue:@"" forKey:@"flipX"];
        [dict setValue:@"" forKey:@"flipY"];
        [dict setValue:@"" forKey:@"opacity"];
        [dict setValue:@"" forKey:@"color"];
        [dict setValue:@"" forKey:@"textureRect"];
        [self registerKeysFromDictionary:dict];
    }
    
    return self;
}

+ (Class)representedClass
{
    return [CCSprite class];
}

+ (CCSprite *)spriteWithFile:(NSString *)filename
{
    CCSprite *retVal = [CCSprite spriteWithFile:filename];
    retVal.SDNode = [[[self alloc] init] autorelease];
    [retVal.SDNode setNode:retVal];
    [(SDSprite *)retVal.SDNode setPath:filename];
    return retVal;
}

+ (id)node
{
    return [self spriteWithFile:@"no_image.png"];
}

+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict
{
    [super setupNode:node withDictionaryRepresentation:dict];
    
    CCSprite *sprite = (CCSprite *)node;
    sprite.texture = [[CCTextureCache sharedTextureCache] addImage:[dict valueForKey:@"path"]];
    [(SDSprite *)sprite.SDNode setPath:[dict valueForKey:@"path"]];
    sprite.textureRect = NSRectToCGRect(NSRectFromString([dict valueForKey:@"textureRect"]));
    sprite.opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
    sprite.color = ColorFromNSString([dict valueForKey:@"color"]);
    sprite.flipX = [[dict valueForKey:@"flipX"] boolValue];
    sprite.flipY = [[dict valueForKey:@"flipY"] boolValue];
}

- (NSDictionary *)dictionaryRepresentation
{
    CCSprite *sprite = (CCSprite *)_node;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryRepresentation]];
    [dict setValue:self.path forKey:@"path"];
    [dict setValue:NSStringFromRect(NSRectFromCGRect(sprite.textureRect)) forKey:@"textureRect"];
    [dict setValue:[NSNumber numberWithUnsignedChar:sprite.opacity] forKey:@"opacity"];
    [dict setValue:NSStringFromColor(sprite.color) forKey:@"color"];
    [dict setValue:[NSNumber numberWithBool:sprite.flipX] forKey:@"flipX"];
    [dict setValue:[NSNumber numberWithBool:sprite.flipY] forKey:@"flipY"];
    
    return dict;
}

- (void)dealloc
{
    self.path = nil;
    [super dealloc];
}

- (CGFloat)textureRectX
{
    return [(CCSprite *)_node textureRect].origin.x;
}

- (void)setTextureRectX:(CGFloat)textureRectX
{
    if (textureRectX != [self textureRectX])
    {
        CGRect rect = [(CCSprite *)_node textureRect];
        rect.origin.x = textureRectX;
        [(CCSprite *)_node setTextureRect:rect];
    }
}

- (CGFloat)textureRectY
{
    return [(CCSprite *)_node textureRect].origin.y;
}

- (void)setTextureRectY:(CGFloat)textureRectY
{
    if (textureRectY != [self textureRectY])
    {
        CGRect rect = [(CCSprite *)_node textureRect];
        rect.origin.y = textureRectY;
        [(CCSprite *)_node setTextureRect:rect];
    }
}

- (CGFloat)textureRectWidth
{
    return [(CCSprite *)_node textureRect].size.width;
}

- (void)setTextureRectWidth:(CGFloat)textureRectWidth
{
    if (textureRectWidth != [self textureRectWidth])
    {
        CGRect rect = [(CCSprite *)_node textureRect];
        rect.size.width = textureRectWidth;
        [(CCSprite *)_node setTextureRect:rect];
    }
}

- (CGFloat)textureRectHeight
{
    return [(CCSprite *)_node textureRect].size.height;
}

- (void)setTextureRectHeight:(CGFloat)textureRectHeight
{
    if (textureRectHeight != [self textureRectHeight])
    {
        CGRect rect = [(CCSprite *)_node textureRect];
        rect.size.height = textureRectHeight;
        [(CCSprite *)_node setTextureRect:rect];
    }
}

- (NSColor *)colorObject
{
    ccColor3B color = [(CCSprite *)_node color];
    return [NSColor colorWithDeviceRed:color.r/255.0f green:color.g/255.0f blue:color.b/255.0f alpha:1.0f];
}

- (void)setColorObject:(NSColor *)colorObject
{
    if (![colorObject isEqualTo:[self colorObject]])
    {
        NSColor *color = [colorObject colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        
		CGFloat r, g, b;
		r = [color redComponent] * 255;
		g = [color greenComponent] * 255;
		b = [color blueComponent] * 255;
        
        [(CCSprite *)_node setColor:ccc3(r, g, b)];
    }
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSMutableSet *keyPaths = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingValueForKey:key]];
    
    if ([key isEqualToString:@"textureRectX"] || [key isEqualToString:@"textureRectY"] || [key isEqualToString:@"textureRectWidth"] || [key isEqualToString:@"textureRectHeight"])
        [keyPaths addObject:@"textureRect"];
    else if ([key isEqualToString:@"colorObject"])
        [keyPaths addObject:@"color"];
    
    return keyPaths;
}

@end
