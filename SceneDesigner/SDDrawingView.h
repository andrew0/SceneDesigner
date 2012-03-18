//
//  SDDrawingView.h
//  SceneDesigner
//

#import "cocos2d.h"

@protocol SDNodeProtocol;

@interface SDDrawingView : CCLayer
{
    CCSprite *_background;
    CCNode<SDNodeProtocol> *_selectedNode;
    BOOL _willDragNode;
    BOOL _willDeselectNode;
    CGPoint _initialPosition;
    CGPoint _prevLocation;
}

@property (nonatomic, retain) CCNode<SDNodeProtocol> *selectedNode;
@property (nonatomic, assign) CGFloat sceneWidth;
@property (nonatomic, assign) CGFloat sceneHeight;

+ (CCScene *)scene;
- (CCScene *)scene;
- (CCNode<SDNodeProtocol> *)nodeForEvent:(NSEvent *)event;

@end
