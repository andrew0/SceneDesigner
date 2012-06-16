//
//  CCNode+Additions.h
//  SceneDesigner
//

#import "cocos2d.h"

@interface CCNode (Additions)

- (BOOL)isEventInRect:(NSEvent *)event;
- (BOOL)isEventInRect:(NSEvent *)event insetX:(CGFloat)x insetY:(CGFloat)y;
- (NSArray *)allChildren;

@end
