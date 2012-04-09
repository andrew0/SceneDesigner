//
//  SDLabelBMFont.m
//  SceneDesigner
//

#import "SDLabelBMFont.h"
#import "ColorFunctions.h"
#import "CCNode+Additions.h"

@implementation SDLabelBMFont

@dynamic colorObject;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
        [dict setValue:@"" forKey:@"string"];
        [dict setValue:@"" forKey:@"fntFile"];
        [dict setValue:@"" forKey:@"color"];
        [dict setValue:@"" forKey:@"opacity"];
        [self registerKeysFromDictionary:dict];
    }
    
    return self;
}

+ (Class)representedClass
{
    return [CCLabelBMFont class];
}

+ (id)node
{
    CCLabelBMFont *retVal = [CCLabelBMFont labelWithString:nil fntFile:nil];
    retVal.SDNode = [[[self alloc] init] autorelease];
    [retVal.SDNode setNode:retVal];
    return retVal;
}

+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict
{
    [super setupNode:node withDictionaryRepresentation:dict];
    
    CCLabelBMFont *label = (CCLabelBMFont *)node;
    [label setString:[dict valueForKey:@"string"]];
    [label setFntFile:[dict valueForKey:@"fntFile"]];
    [label setColor:ColorFromNSString([dict valueForKey:@"color"])];
    [label setOpacity:[[dict valueForKey:@"opacity"] unsignedCharValue]];
}

- (NSDictionary *)dictionaryRepresentation
{
    CCLabelBMFont *label = (CCLabelBMFont *)_node;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryRepresentation]];
    [dict setValue:[label string] forKey:@"string"];
    [dict setValue:[label fntFile] forKey:@"fntFile"];
    [dict setValue:NSStringFromColor([label color]) forKey:@"color"];
    [dict setValue:[NSNumber numberWithUnsignedChar:[label opacity]] forKey:@"opacity"];
    
    return dict;
}

- (NSColor *)colorObject
{
    ccColor3B color = [(CCLabelBMFont *)_node color];
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
        
        [(CCLabelBMFont *)_node setColor:ccc3(r, g, b)];
    }
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSMutableSet *keyPaths = [NSMutableSet setWithSet:[super keyPathsForValuesAffectingValueForKey:key]];
    
    if ([key isEqualToString:@"colorObject"])
        [keyPaths addObject:@"color"];
    
    return keyPaths;
}

@end
