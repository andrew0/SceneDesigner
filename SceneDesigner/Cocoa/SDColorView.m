//
//  SDColorView.m
//  SceneDesigner
//

#import "SDColorView.h"

@implementation SDColorView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithDeviceRed:152/255.0f green:152/255.0f blue:152/255.0f alpha:1.0f] set];
    NSRectFill([self bounds]);
}

@end
