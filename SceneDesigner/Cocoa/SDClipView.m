//
//  SDClipView.m
//  SceneDesigner
//

#import "SDClipView.h"

@implementation SDClipView

- (void)centerView
{
    // get frame of clipView and documentView
    NSRect documentFrame = [[self documentView] frame];
    NSRect clipFrame = [self bounds];
    
    // if the clip frame is wider than the document, then it isn't scrolling horizontally
    if (NSWidth(documentFrame) < NSWidth(clipFrame))
        clipFrame.origin.x = NSWidth(documentFrame) / 2 - NSWidth(clipFrame) / 2;
    
    // if the clip frame is taller than the document, then it isn't scrolling veritically
    if (NSHeight(documentFrame) < NSHeight(clipFrame))
        clipFrame.origin.y = NSHeight(documentFrame) / 2 - NSHeight(clipFrame) / 2;
    
    // scroll to calculated point
    [self scrollToPoint:[self constrainScrollPoint:clipFrame.origin]];
    [[self enclosingScrollView] reflectScrolledClipView:self];
}

- (NSPoint)constrainScrollPoint:(NSPoint)newOrigin
{
    // get frame of clipView and documentView
    NSRect documentFrame = [[self documentView] frame];
    NSRect clipFrame = [self bounds];
    
    // call super and modifiy it if necessary
    NSPoint retVal = [super constrainScrollPoint:newOrigin];
    if (NSWidth(documentFrame) < NSWidth(clipFrame))
        retVal.x = NSMinX(documentFrame) + floorf(NSWidth(documentFrame) / 2 - NSWidth(clipFrame) / 2);
    if (NSHeight(documentFrame) < NSHeight(clipFrame))
        retVal.y = NSMinY(documentFrame) + floorf(NSHeight(documentFrame) / 2 - NSHeight(clipFrame) / 2);
    
    return retVal;
}

- (void)setFrameOrigin:(NSPoint)newOrigin
{
    [super setFrameOrigin:newOrigin];
    [self centerView];
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self centerView];
}

- (void)setFrameRotation:(CGFloat)angle
{
    [super setFrameRotation:angle];
    [self centerView];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] saveGraphicsState];
    
    // this makes the background color draw in the top left origin
    NSRect offsetRect = [self convertRect:[self bounds] toView:nil];
    [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(NSMinX(offsetRect), NSMaxY(offsetRect))];
    [super drawRect:dirtyRect];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self documentView] mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [[self documentView] mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [[self documentView] mouseDragged:theEvent];
}

@end
