//
//  SDDrawingView.h
//  SceneDesigner
//

#import "cocos2d.h"

@interface SDDrawingView : CCLayer
{
    CCSprite *_background;
    NSArray *_nodesToAddOnEnter;
    CCNode *_selectedNode;
    BOOL _willDragNode;
    BOOL _willDeselectNode;
    CGPoint _initialNodePosition;
    CGPoint _initialMouseLocation;
}

@property (nonatomic, retain) NSArray *nodesToAddOnEnter;
@property (nonatomic, retain) CCNode *selectedNode;
@property (nonatomic, assign) CGFloat sceneWidth;
@property (nonatomic, assign) CGFloat sceneHeight;

+ (CCScene *)scene;
- (CCScene *)scene;
- (CCNode *)nodeForEvent:(NSEvent *)event withParent:(CCNode *)parent;
- (CCNode *)nodeForEvent:(NSEvent *)event;

@end
