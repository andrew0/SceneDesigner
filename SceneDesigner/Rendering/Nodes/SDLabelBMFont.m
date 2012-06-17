//
//  SDLabelBMFont.m
//  SceneDesigner
//

#import "SDLabelBMFont.h"
#import "ColorFunctions.h"

@implementation SDLabelBMFont

@dynamic colorObject;

- (id)initWithString:(NSString*)theString fntFile:(NSString*)fntFile width:(float)width alignment:(CCTextAlignment)alignment imageOffset:(CGPoint)offset
{
    self = [super initWithString:theString fntFile:fntFile width:width alignment:alignment imageOffset:offset];
    if (self)
        SDNODE_INIT();
    
    return self;
}

- (void)dealloc
{
    SDNODE_DEALLOC();
    [super dealloc];
}

- (id)initWithString:(NSString*)theString fntFile:(NSString*)fntFile width:(float)width alignment:(CCTextAlignment)alignment
{
    self = [super initWithString:theString fntFile:fntFile width:width alignment:alignment];
    return self;
}

- (void)setOpacity:(GLubyte)opacity
{
    if ([self opacity] != opacity)
    {
        NSUndoManager *um = [self undoManager];
        [(CCLabelBMFont *)[um prepareWithInvocationTarget:self] setOpacity:[self opacity]];
        [um setActionName:NSLocalizedString(@"opacity adjustment", nil)];
        [super setOpacity:opacity];
    }
}

- (void)setString:(NSString *)label
{
    if (![label isEqualToString:[self string]])
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setString:[self string]];
        [um setActionName:NSLocalizedString(@"label string adjustment", nil)];
        [super setString:label];
    }
}

- (void)setFntFile:(NSString *)fntFile
{
    if (![[self fntFile] isEqualToString:fntFile])
    {
        NSUndoManager *um = [self undoManager];
        [[um prepareWithInvocationTarget:self] setFntFile:[self fntFile]];
        [um setActionName:NSLocalizedString(@"label font adjustment", nil)];
        [super setFntFile:fntFile];
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

- (id)_initWithDictionaryRepresentation:(NSDictionary *)dict
{
    self = [self initWithString:[dict valueForKey:@"string"] fntFile:[dict valueForKey:@"fntFile"]];
    if (self)
    {
        self.opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
        self.color = ColorFromNSString([dict valueForKey:@"color"]);
    }
    
    return self;
}

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [dict setValue:[self fntFile] forKey:@"fntFile"];
    [dict setValue:[self string] forKey:@"string"];
    [dict setValue:[NSNumber numberWithUnsignedChar:self.opacity] forKey:@"opacity"];
    [dict setValue:NSStringFromColor(self.color) forKey:@"color"];
    
    return [dict autorelease];
}

SDNODE_FUNC_SRC

@end
