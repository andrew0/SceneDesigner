//
//  SDSprite.m
//  SceneDesigner
//

#import "SDSprite.h"
#import "ColorFunctions.h"
#import "SDDocument.h"

@implementation SDSprite

@synthesize path = _path;
@synthesize data = _data;
@dynamic textureRectX;
@dynamic textureRectY;
@dynamic textureRectWidth;
@dynamic textureRectHeight;
@dynamic colorObject;

- (void)dealloc
{
    SDNODE_DEALLOC();
    self.path = nil;
    self.data = nil;
    [super dealloc];
}

- (id)initWithFile:(NSString *)filename rect:(CGRect)rect
{
    NSData *data = [NSData dataWithContentsOfFile:filename];
    NSString *newPath = [[SDUtils sharedUtils] uniqueResourceNameForString:[filename lastPathComponent]];
    self = [self initWithData:data key:newPath];
    self.textureRect = rect;
    self.path = newPath;
    
    return self;
}

- (id)initWithFile:(NSString*)filename
{
    NSData *data = [NSData dataWithContentsOfFile:filename];
    NSString *newPath = [[SDUtils sharedUtils] uniqueResourceNameForString:[filename lastPathComponent]];
    self = [self initWithData:data key:newPath];
    self.path = newPath;
    
    return self;
}

- (id)initWithData:(NSData *)data key:(NSString *)key
{
    NSBitmapImageRep *image = [[[NSBitmapImageRep alloc] initWithData:data] autorelease];
    self = [self initWithCGImage:[image CGImage] key:key];
    if (self)
    {
        SDNODE_INIT();
        
        // reuse object to save memory
        SDDocument *doc = [self document];
        NSDictionary *resources = [doc resources];
        for (NSString *key in resources)
        {
            NSData *object = [resources objectForKey:key];
            NSAssert([object isKindOfClass:[NSData class]], @"");
            if ([object isEqualToData:data])
            {
                self.data = object;
                break;
            }
        }
        
        if (!_data)
            self.data = data;
        
        self.path = key;
    }
    
    return self;
}

- (id)_initWithDictionaryRepresentation:(NSDictionary *)dict
{
    NSData *data = [dict objectForKey:@"data"];
    NSString *path = [dict objectForKey:@"path"];
    if (data)
    {
        self = [self initWithData:data key:[path lastPathComponent]];
        self.path = path;
    }
    else if (path)
    {
        SDDocument *doc = [self document];
        if ([doc fileURL])
        {
            NSString *newPath = [[[[doc fileURL] path] stringByAppendingPathComponent:@"resources"] stringByAppendingPathComponent:[path lastPathComponent]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:newPath])
                path = newPath;
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSLog(@"could not find sprite at path %@", path);
            return nil;
        }
        
        // use data so we can copy/paste if the file is deleted before saving
        self = [self initWithFile:path];
    }
    else
    {
        NSLog(@"error loading sprite with dictionary representation %@", dict);
        return nil;
    }
    
    if (self)
    {
        self.path = [dict objectForKey:@"path"];    
        self.textureRect = NSRectToCGRect(NSRectFromString([dict objectForKey:@"textureRect"]));
        self.opacity = [[dict objectForKey:@"opacity"] unsignedCharValue];
        self.color = ColorFromNSString([dict objectForKey:@"color"]);
        self.flipX = [[dict objectForKey:@"flipX"] boolValue];
        self.flipY = [[dict objectForKey:@"flipY"] boolValue];
    }
    
    return self;
}

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:6];
    
    [dict setObject:self.path forKey:@"path"];
    [dict setObject:NSStringFromRect(NSRectFromCGRect(self.textureRect)) forKey:@"textureRect"];
    [dict setObject:[NSNumber numberWithUnsignedChar:self.opacity] forKey:@"opacity"];
    [dict setObject:NSStringFromColor(self.color) forKey:@"color"];
    [dict setObject:[NSNumber numberWithBool:self.flipX] forKey:@"flipX"];
    [dict setObject:[NSNumber numberWithBool:self.flipY] forKey:@"flipY"];
    NSAssert(_data, @"data not set");
    [dict setObject:_data forKey:@"data"];
    
    return dict;
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
    if (color.r != self.color.r || color.g != self.color.g || color.b != self.color.b)
    {
        NSUndoManager *um = [self undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setColor:[self color]];
        [um setActionName:NSLocalizedString(@"color adjustment", nil)];
        
        [self willChangeValueForKey:@"colorObject"];
        [super setColor:color];
        [self didChangeValueForKey:@"colorObject"];
    }
}

- (void)setFlipX:(BOOL)fx
{
    if ([self flipX] != fx)
    {
        NSUndoManager *um = [self undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setFlipX:[self flipX]];
        [um setActionName:NSLocalizedString(@"flip X axis", nil)];
        [super setFlipX:fx];
    }
}

- (void)setFlipY:(BOOL)fy
{
    if ([self flipY] != fy)
    {
        NSUndoManager *um = [self undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setFlipY:[self flipY]];
        [um setActionName:NSLocalizedString(@"flip Y axis", nil)];
        [super setFlipY:fy];
    }
}

- (void)setOpacity:(GLubyte)opacity
{
    if ([self opacity] != opacity)
    {
        NSUndoManager *um = [self undoManager];
        [(CCSprite *)[um prepareWithInvocationTarget:self] setOpacity:[self opacity]];
        [um setActionName:NSLocalizedString(@"opacity adjustment", nil)];
        [super setOpacity:opacity];
    }
}

- (void)setTextureRect:(CGRect)rect
{
    if (!CGRectEqualToRect([self textureRect], rect))
    {
        NSUndoManager *um = [self undoManager];
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
