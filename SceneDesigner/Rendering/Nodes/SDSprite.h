//
//  SDSprite.h
//  SceneDesigner
//

#import "cocos2d.h"
#import "SDNode.h"

@interface SDSprite : CCSprite <SDNodeProtocol>
{
    NSData *_data;
    NSString *_path;
    SDNODE_IVARS
}

@property (nonatomic, copy) NSString *path;
@property (nonatomic, readwrite) CGFloat textureRectX;
@property (nonatomic, readwrite) CGFloat textureRectY;
@property (nonatomic, readwrite) CGFloat textureRectWidth;
@property (nonatomic, readwrite) CGFloat textureRectHeight;
@property (nonatomic, assign, readwrite) NSColor *colorObject;
@property (nonatomic, retain) NSData *data;

@end
