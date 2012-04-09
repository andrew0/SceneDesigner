//
//  SDLayerColor.m
//  SceneDesigner
//

#import "SDLayerColor.h"
#import "ColorFunctions.h"
#import "CCNode+Additions.h"

@implementation SDLayerColor

@dynamic colorObject;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setValue:@"" forKey:@"color"];
        [dict setValue:@"" forKey:@"opacity"];
        [self registerKeysFromDictionary:dict];
    }
    
    return self;
}

+ (Class)representedClass
{
    return [CCLayerColor class];
}

+ (id)node
{
    CCLayerColor *retVal = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255) width:0 height:0];
    retVal.SDNode = [[[self alloc] init] autorelease];
    [retVal.SDNode setNode:retVal];
    return retVal;
}

+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict
{
    [super setupNode:node withDictionaryRepresentation:dict];
    
    CCLayerColor *layer = (CCLayerColor *)node;
    [layer setColor:ColorFromNSString([dict valueForKey:@"color"])];
    [layer setOpacity:[[dict valueForKey:@"opacity"] unsignedCharValue]];
}

- (NSDictionary *)dictionaryRepresentation
{
    CCLayerColor *layer = (CCLayerColor *)_node;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryRepresentation]];
    [dict setValue:NSStringFromColor([layer color]) forKey:@"color"];
    [dict setValue:[NSNumber numberWithUnsignedChar:[layer opacity]] forKey:@"opacity"];
    
    return dict;
}

- (NSColor *)colorObject
{
    ccColor3B color = [(CCLayerColor *)_node color];
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
        
        [(CCLayerColor *)_node setColor:ccc3(r, g, b)];
    }
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"colroObject"])
    {
        NSSet *affectingKeys = [NSSet setWithObject:@"color"];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKeys];
    }
    
    return keyPaths;
}

@end
