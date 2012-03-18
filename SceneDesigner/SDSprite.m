//
//  SDSprite.m
//  SceneDesigner
//

#import "SDSprite.h"
#import "ColorFunctions.h"

@implementation SDSprite

@synthesize path = _path;
@dynamic textureRectX;
@dynamic textureRectY;
@dynamic textureRectWidth;
@dynamic textureRectHeight;
@dynamic colorObject;

- (void)dealloc
{
    self.path = nil;
    [super dealloc];
}

- (id)initWithFile:(NSString *)filename rect:(CGRect)rect
{
    self = [super initWithFile:filename rect:rect];
    if (self)
        self.path = filename;
    
    return self;
}

- (id)initWithFile:(NSString*)filename
{
    self = [super initWithFile:filename];
    if (self)
        self.path = filename;
    
    return self;
}

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
    
    [dict setValue:self.path forKey:@"path"];
    [dict setValue:NSStringFromRect(NSRectFromCGRect(self.textureRect)) forKey:@"textureRect"];
    [dict setValue:[NSNumber numberWithUnsignedChar:self.opacity] forKey:@"opacity"];
    [dict setValue:NSStringFromColor(self.color) forKey:@"color"];
    [dict setValue:[NSNumber numberWithBool:self.flipX] forKey:@"flipX"];
    [dict setValue:[NSNumber numberWithBool:self.flipY] forKey:@"flipY"];
    
    return dict;
}

+ (id)_setupFromDictionaryRepresentation:(NSDictionary *)dict
{
    NSString *path = [dict valueForKey:@"path"];
    if (path == nil || ![[NSFileManager defaultManager] fileExistsAtPath:path])
        return nil;
    
    SDSprite *retVal = [self spriteWithFile:path];
    
    retVal.path = [dict valueForKey:@"path"];    
    retVal.textureRect = NSRectToCGRect(NSRectFromString([dict valueForKey:@"textureRect"]));
    retVal.opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
    retVal.color = ColorFromNSString([dict valueForKey:@"color"]);
    retVal.flipX = [[dict valueForKey:@"flipX"] boolValue];
    retVal.flipY = [[dict valueForKey:@"flipY"] boolValue];
    
    return retVal;
}

- (CGFloat)textureRectX
{
    return self.textureRect.origin.x;
}

- (void)setTextureRectX:(CGFloat)textureRectX
{
    if (textureRectX != self.textureRect.origin.x)
    {
        CGRect rect = self.textureRect;
        rect.origin.x = textureRectX;
        self.textureRect = rect;
    }
}

- (CGFloat)textureRectY
{
    return self.textureRect.origin.y;
}

- (void)setTextureRectY:(CGFloat)textureRectY
{
    if (textureRectY != self.textureRect.origin.y)
    {
        CGRect rect = self.textureRect;
        rect.origin.y = textureRectY;
        self.textureRect = rect;
    }
}

- (CGFloat)textureRectWidth
{
    return self.textureRect.size.width;
}

- (void)setTextureRectWidth:(CGFloat)textureRectWidth
{
    if (textureRectWidth != self.textureRect.size.width)
    {
        CGRect rect = self.textureRect;
        rect.size.width = textureRectWidth;
        self.textureRect = rect;
    }
}

- (CGFloat)textureRectHeight
{
    return self.textureRect.size.height;
}

- (void)setTextureRectHeight:(CGFloat)textureRectHeight
{
    if (textureRectHeight != self.textureRect.size.height)
    {
        CGRect rect = self.textureRect;
        rect.size.height = textureRectHeight;
        self.textureRect = rect;
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
    if (color.r != self.color.r && color.g != self.color.g && color.b != self.color.b)
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

- (void)setFlipX:(BOOL)fx
{
    if ([self flipX] != fx)
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setFlipX:[self flipX]];
        [um setActionName:NSLocalizedString(@"flip X axis", nil)];
        [super setFlipX:fx];
    }
}

- (void)setFlipY:(BOOL)fy
{
    if ([self flipY] != fy)
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setFlipY:[self flipY]];
        [um setActionName:NSLocalizedString(@"flip Y axis", nil)];
        [super setFlipY:fy];
    }
}

- (void)setOpacity:(GLubyte)opacity
{
    if ([self opacity] != opacity)
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setOpacity:[self opacity]];
        [um setActionName:NSLocalizedString(@"opacity adjustment", nil)];
        [super setOpacity:opacity];
        
        [self forceRedraw];
    }
}

- (void)setTextureRect:(CGRect)rect
{
    if (!CGRectEqualToRect([self textureRect], rect))
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [[um prepareWithInvocationTarget:self] setTextureRect:[self textureRect]];
        [um setActionName:NSLocalizedString(@"texture rect adjustment", nil)];
        
        [self willChangeValueForKey:@"textureRectX"];
        [self willChangeValueForKey:@"textureRectX"];
        [self willChangeValueForKey:@"textureRectWidth"];
        [self willChangeValueForKey:@"textureRectHeight"];
        [super setTextureRect:rect];
        [self didChangeValueForKey:@"textureRectX"];
        [self didChangeValueForKey:@"textureRectY"];
        [self didChangeValueForKey:@"textureRectWidth"];
        [self didChangeValueForKey:@"textureRectHeight"];
    }
}

SDNODE_FUNC_SRC

@end
