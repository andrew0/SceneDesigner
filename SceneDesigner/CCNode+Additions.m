//
//  CCNode+Additions.m
//  SceneDesigner
//

#import "CCNode+Additions.h"

@implementation CCNode (Additions)

- (BOOL)isEventInRect:(NSEvent *)event
{
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	CGPoint local = [self convertToNodeSpace:location];
	CGRect r = CGRectMake(0, 0, contentSize_.width, contentSize_.height);
	return CGRectContainsPoint(r, local);
}

@end
