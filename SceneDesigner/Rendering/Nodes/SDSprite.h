//
//  SDSprite.h
//  SceneDesigner
//

#import "cocos2d.h"
#import "SDNode.h"

@interface SDSprite : SDNode
{
    NSString *_path;
}

@property (nonatomic, copy) NSString *path;
@property (nonatomic, readwrite) CGFloat textureRectX;
@property (nonatomic, readwrite) CGFloat textureRectY;
@property (nonatomic, readwrite) CGFloat textureRectWidth;
@property (nonatomic, readwrite) CGFloat textureRectHeight;
@property (nonatomic, assign) NSColor *colorObject;

+ (CCSprite *)spriteWithFile:(NSString *)filename;

@end
