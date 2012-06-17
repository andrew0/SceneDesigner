//
//  SDHeaderView.m
//  SceneDesigner
//

#import "SDHeaderView.h"

@implementation SDHeaderView

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect rect = [self bounds];
    CGFloat radius = 7.0f;
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(NSMinX(rect)+radius, NSMaxY(rect))];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect) - radius, NSMaxY(rect) - radius) radius:radius startAngle:90 endAngle:0 clockwise:YES];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:0 startAngle:360 endAngle:270 clockwise:YES];
    [path appendBezierPathWithArcWithCenter:rect.origin radius:0 startAngle:270 endAngle:180 clockwise:YES];
    [path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect) + radius, NSMaxY(rect) - radius) radius:radius startAngle:180 endAngle:90 clockwise:YES];
    [path closePath];
    
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithDeviceRed:243/255.0f green:243/255.0f blue:243/255.0f alpha:1.0f] endingColor:[NSColor colorWithDeviceRed:210/255.0f green:210/255.0f blue:210/255.0f alpha:1.0f]];
    [gradient drawInBezierPath:path angle:270.0f];
    
    NSBezierPath *strokePath = [NSBezierPath bezierPath];
    [strokePath moveToPoint:NSMakePoint(NSMinX(rect)+radius + 0.5f, NSMaxY(rect) - 0.5f)];
    [strokePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect) - radius - 0.5f, NSMaxY(rect) - radius - 0.5f) radius: radius startAngle:90 endAngle:0 clockwise:YES];
    [strokePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect) - 0.5f, NSMinY(rect) + 0.5f) radius:0  startAngle:360 endAngle:270 clockwise:YES];
    [strokePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect) + 0.5f, NSMinY(rect) + 0.5f) radius:0 startAngle:270 endAngle:180 clockwise:YES];
    [strokePath appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect) + radius + 0.5f, NSMaxY(rect) - radius - 0.5f) radius:radius startAngle:180 endAngle:90 clockwise:YES];
    [strokePath closePath];
    [[NSColor colorWithDeviceRed:152/255.0f green:152/255.0f blue:152/255.0f alpha:1.0f] set];
    [strokePath stroke];
}

@end
