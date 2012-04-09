//
//  CCNode+Additions.m
//  SceneDesigner
//

#import "CCNode+Additions.h"
#import "SDNode.h"

@implementation CCNode (Additions)

@dynamic SDNode;

- (BOOL)isEventInRect:(NSEvent *)event
{
	CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
	CGPoint local = [self convertToNodeSpace:location];
	CGRect r = CGRectMake(0, 0, contentSize_.width, contentSize_.height);
	return CGRectContainsPoint(r, local);
}

- (BOOL)isSDNode
{
    return ([self SDNode] != nil && [[self SDNode] isKindOfClass:[SDNode class]]);
}

- (SDNode *)SDNode
{
    return (SDNode *)userObject_;
}

- (void)setSDNode:(SDNode *)SDNode
{
    [self setUserObject:SDNode];
}

@end
