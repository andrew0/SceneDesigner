//
//  SDLayerColor.m
//  SceneDesigner
//

#import "SDLayerColor.h"
#import "ColorFunctions.h"

@implementation SDLayerColor

@synthesize isAccelerometerEnabled = _isAccelerometerEnabled;
@dynamic colorObject;

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    [dict setValue:[NSNumber numberWithBool:[self isAccelerometerEnabled]] forKey:@"isAccelerometerEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isTouchEnabled]] forKey:@"isTouchEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isMouseEnabled]] forKey:@"isMouseEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isKeyboardEnabled]] forKey:@"isKeyboardEnabled"];
    [dict setValue:NSStringFromColor([self color]) forKey:@"color"];
    [dict setValue:[NSNumber numberWithUnsignedChar:[self opacity]] forKey:@"opacity"];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (id)_setupFromDictionaryRepresentation:(NSDictionary *)dict
{
    ccColor3B color = ColorFromNSString([dict valueForKey:@"color"]);
    GLubyte opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
    SDLayerColor *retVal = [self layerWithColor:ccc4(color.r, color.g, color.b, opacity)];
    retVal.isAccelerometerEnabled = [[dict valueForKey:@"isAccelerometerEnabled"] boolValue];
    retVal.isTouchEnabled = [[dict valueForKey:@"isTouchEnabled"] boolValue];
    retVal.isMouseEnabled = [[dict valueForKey:@"isMouseEnabled"] boolValue];
    retVal.isKeyboardEnabled = [[dict valueForKey:@"isKeyboardEnabled"] boolValue];
    
    return retVal;
}

- (NSColor *)colorObject
{
    ccColor3B color = self.color;
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
        
        [self setColor:ccc3(r, g, b)];
    }
}

- (void)setColor:(ccColor3B)color
{
    if (color.r != self.color.r || color.g != self.color.g || color.b != self.color.b)
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setColor:[self color]];
        [um setActionName:NSLocalizedString(@"color adjustment", nil)];
        
        [self willChangeValueForKey:@"colorObject"];
        [super setColor:color];
        [self didChangeValueForKey:@"colorObject"];
        
        [self forceRedraw];
    }
}

- (void)setOpacity:(GLubyte)opacity
{
    if (opacity != [self opacity])
    {
        [super setOpacity:opacity];
        [self forceRedraw];
    }
}

SDNODE_FUNC_SRC

@end
