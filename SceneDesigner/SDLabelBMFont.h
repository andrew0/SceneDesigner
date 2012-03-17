//
//  SDLabelBMFont.h
//  SceneDesigner
//

#import "cocos2d.h"
#import "SDNode.h"

@interface SDLabelBMFont : CCLabelBMFont <SDNodeProtocol>
{
    NSString *_fntFile;
    SDNODE_IVARS
}

@property (nonatomic, copy) NSString *fntFile;

@end
