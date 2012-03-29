//
//  SDGLView.m
//  SceneDesigner
//

#import "SDGLView.h"
#import "SDSprite.h"
#import "SDWindowController.h"
#import "SDDrawingView.h"
#import "SDDocument.h"

@implementation SDGLView

- (void)awakeFromNib
{
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (void)dealloc
{
    [self unregisterDraggedTypes];
    [super dealloc];
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
    
    [[self superview] setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent 
{
    [[self enclosingScrollView] scrollWheel:theEvent];
    [super scrollWheel:theEvent];
}

#pragma mark Dragging Destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType] && sourceMask & NSDragOperationLink) 
        return NSDragOperationLink;
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender 
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceMask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType] && sourceMask & NSDragOperationLink)
    {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *newFiles = [NSMutableArray arrayWithArray:files];
        NSArray *allowedTypes = [[SDUtils sharedUtils] allowedImageTypes];
        
        for (NSString *file in files)
            if (![allowedTypes containsObject:[file pathExtension]])
                [newFiles removeObject:file];
        
        NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
        
        [[[SDUtils sharedUtils] currentUndoManager] beginUndoGrouping];
        for (NSString *path in files)
        {
            SDWindowController *wc = [[SDUtils sharedUtils] currentWindowController];
            CCNode *parent = [[[[SDUtils sharedUtils] currentDocument] drawingView] selectedNode];
            
            SDSprite *sprite = [SDSprite spriteWithFile:path];
            sprite.position = NSPointToCGPoint(point);
            [wc addNodeToLayer:sprite parent:parent];
        }
        [[[SDUtils sharedUtils] currentUndoManager] endUndoGrouping];
    }
    return YES;
}

@end
