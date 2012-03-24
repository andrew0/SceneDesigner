//
//  SDLabelBMFont.h
//  SceneDesigner
//

#import "cocos2d.h"
#import "SDNode.h"

@interface SDLabelBMFont : CCLabelBMFont <SDNodeProtocol>
{
    SDNODE_IVARS
}

@property (nonatomic, copy) NSColor *colorObject;

@end
