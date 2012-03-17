//
//  SDGLView.m
//  SceneDesigner
//

#import "SDGLView.h"

@implementation SDGLView

- (void)awakeFromNib
{
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:10.0f];
    [shadow setShadowColor:[NSColor grayColor]];
    [self setShadow:shadow];
    [shadow release];
}

- (void)updateProjection
{
    CGSize size = [[CCDirector sharedDirector] winSizeInPixels];
    
    [self setFrameSize:NSSizeFromCGSize(size)];
    
    CGPoint offset = ccp(-NSMinX([self visibleRect]), -NSMinY([self visibleRect]));
    glViewport(offset.x, offset.y, size.width, size.height);
    kmGLMatrixMode(KM_GL_PROJECTION);
    kmGLLoadIdentity();
    
    kmMat4 orthoMatrix;
    kmMat4OrthographicProjection(&orthoMatrix, 0, size.width, 0, size.height, -1024, 1024);
    kmGLMultMatrix( &orthoMatrix );
    
    kmGLMatrixMode(KM_GL_MODELVIEW);
    kmGLLoadIdentity();
    
    [[CCDirector sharedDirector] drawScene];
    [[self superview] setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent 
{
    [[self enclosingScrollView] scrollWheel:theEvent];
    [super scrollWheel:theEvent];
}

@end
