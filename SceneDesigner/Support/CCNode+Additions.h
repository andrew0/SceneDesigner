//
//  CCNode+Additions.h
//  SceneDesigner
//

#import "cocos2d.h"

@class SDNode;

@interface CCNode (Additions)

- (BOOL)isEventInRect:(NSEvent *)event;
- (BOOL)isSDNode;
- (SDNode *)SDNode;

@property (nonatomic, assign) SDNode *SDNode;

@end
