//
//  CCNode+Additions.m
//  SceneDesigner
//

#import "CCNode+Additions.h"

@implementation CCNode (Additions)

- (BOOL)isEventInRect:(NSEvent *)event
{
    return [self isEventInRect:event insetX:0 insetY:0];
}

- (BOOL)isEventInRect:(NSEvent *)event insetX:(CGFloat)x insetY:(CGFloat)y
{
    CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	CGPoint local = [self convertToNodeSpace:location];
	CGRect r = CGRectInset(CGRectMake(0, 0, contentSize_.width, contentSize_.height), x, y);
	return CGRectContainsPoint(r, local);
}

@end
