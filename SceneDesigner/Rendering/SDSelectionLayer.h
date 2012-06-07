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
    
    CGPoint _initialPosition; ///< Initial position of selected node
    float _initialScaleX; ///< Initial scale X of selected node
    float _initialScaleY; ///< Initial scale X of selected node
    BOOL _isDragging;
    
    NSCursor *_rotatedCounterclockwiseCursor;
    NSCursor *_rotatedClockwiseCursor;
    
    NSMutableArray *_trackingAreas;
    NSInteger _currentTag; ///< Tag of current corner
}

- (void)updateForSelection:(CCNode *)node;
- (void)updateCursor;

@end
