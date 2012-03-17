//
//  SDDocument.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

@class HelloWorldLayer;

@interface SDDocument : NSDocument
{
    HelloWorldLayer *_drawingView;
    NSMutableArray *_nodesToAdd;
}

@property (nonatomic, retain) HelloWorldLayer *drawingView;

@end
