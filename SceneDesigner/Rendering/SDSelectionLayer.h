//
//  SDSelectionLayer.h
//  SceneDesigner
//

#import "cocos2d.h"

@interface SDSelectionLayer : CCLayer
{
    CCSprite *_tl; ///< Top left resize handle
    CCSprite *_tm; ///< Top middle resize handle
    CCSprite *_tr; ///< Top right resize handle
    CCSprite *_bl; ///< Bottom left resize handle
    CCSprite *_bm; ///< Bototm middle resize handle
    CCSprite *_br; ///< Bottom right resize handle
    CCSprite *_lm; ///< Left middle resize handle
    CCSprite *_rm; ///< Right middle resize handle
    CCSprite *_rotate; ///< Rotation handle
    
    CCNode *_trackedNode; ///< Node to track for mouse movement
    CGPoint _initialMousePosition; ///< Initial position of mouse (in GL coordinates)
    CGPoint _initialPosition; ///< Initial position of selected node
    float _initialScaleX; ///< Initial scale X of selected node
    float _initialScaleY; ///< Initial scale X of selected node
    BOOL _isDragging;
}

- (void)updateForSelection:(CCNode *)node;

@end
