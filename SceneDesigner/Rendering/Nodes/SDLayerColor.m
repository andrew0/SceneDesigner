//
//  SDLayerColor.m
//  SceneDesigner
//

#import "SDLayerColor.h"
#import "ColorFunctions.h"

@implementation SDLayerColor

@synthesize isAccelerometerEnabled = _isAccelerometerEnabled;
@dynamic colorObject;

- (id)initWithColor:(ccColor4B)color width:(GLfloat)w  height:(GLfloat)h
{
    self = [super initWithColor:color width:w height:h];
    if (self)
        SDNODE_INIT();
    
    return self;
}

- (void)dealloc
{
    SDNODE_DEALLOC();
    [super dealloc];
}

- (id)_initWithDictionaryRepresentation:(NSDictionary *)dict
{
    ccColor3B color = ColorFromNSString([dict valueForKey:@"color"]);
    GLubyte opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
    self = [self initWithColor:ccc4(color.r, color.g, color.b, opacity) width:0 height:0];
    if (self)
    {
        self.isAccelerometerEnabled = [[dict valueForKey:@"isAccelerometerEnabled"] boolValue];
        self.isTouchEnabled = [[dict valueForKey:@"isTouchEnabled"] boolValue];
        self.isMouseEnabled = [[dict valueForKey:@"isMouseEnabled"] boolValue];
        self.isKeyboardEnabled = [[dict valueForKey:@"isKeyboardEnabled"] boolValue];
        self.contentSize = NSSizeToCGSize(NSSizeFromString([dict valueForKey:@"contentSize"]));
    }
    
    return self;
}

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

- (void)setIsAccelerometerEnabled:(BOOL)isAccelerometerEnabled
{
    if (isAccelerometerEnabled != _isAccelerometerEnabled)
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setIsAccelerometerEnabled:_isAccelerometerEnabled];
        [um setActionName:NSLocalizedString(@"accelerometer toggling", nil)];
        _isAccelerometerEnabled = isAccelerometerEnabled;
    }
}

- (void)setIsTouchEnabled:(BOOL)isTouchEnabled
{
    if (isTouchEnabled != isTouchEnabled_)
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setIsTouchEnabled:isTouchEnabled_];
        [um setActionName:NSLocalizedString(@"touch toggling", nil)];
        isTouchEnabled_ = isTouchEnabled;
    }
}

- (void)setIsKeyboardEnabled:(BOOL)isKeyboardEnabled
{
    if (isKeyboardEnabled != isKeyboardEnabled_)
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setIsKeyboardEnabled:isKeyboardEnabled_];
        [um setActionName:NSLocalizedString(@"keyboard toggling", nil)];
        isKeyboardEnabled_ = isKeyboardEnabled;
    }
}

- (void)setIsMouseEnabled:(BOOL)isMouseEnabled
{
    if (isMouseEnabled != isMouseEnabled_)
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setIsMouseEnabled:isMouseEnabled_];
        [um setActionName:NSLocalizedString(@"mouse toggling", nil)];
        isMouseEnabled_ = isMouseEnabled;
    }
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
        NSUndoManager *um = [self undoManager];
        [(CCLayerColor *)[um prepareWithInvocationTarget:self] setColor:[self color]];
        [um setActionName:NSLocalizedString(@"color adjustment", nil)];
        
        [self willChangeValueForKey:@"colorObject"];
        [super setColor:color];
        [self didChangeValueForKey:@"colorObject"];
    }
}

- (void)setOpacity:(GLubyte)opacity
{
    if (opacity != [self opacity])
    {
        NSUndoManager *um = [self undoManager];
        [(CCLayerColor *)[um prepareWithInvocationTarget:self] setOpacity:[self opacity]];
        [um setActionName:NSLocalizedString(@"opacity adjustment", nil)];
        [super setOpacity:opacity];
    }
}

SDNODE_FUNC_SRC

@end
