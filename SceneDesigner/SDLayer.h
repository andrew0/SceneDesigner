//
//  SDLayer.h
//  SceneDesigner
//

#import "cocos2d.h"
#import "SDNode.h"

@interface SDLayer : CCLayer <SDNodeProtocol>
{
    // because this is cocos2d Mac, there is no isAccelerometerEnabled, so we have to make our own
    BOOL _isAccelerometerEnabled;
    SDNODE_IVARS
}

@property (nonatomic, assign) BOOL isAccelerometerEnabled;

@end
