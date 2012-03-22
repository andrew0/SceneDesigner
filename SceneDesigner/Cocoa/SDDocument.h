//
//  SDDocument.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

@class SDDrawingView;

@interface SDDocument : NSDocument
{
    SDDrawingView *_drawingView;
    NSMutableArray *_nodesToAdd;
}

@property (nonatomic, retain) SDDrawingView *drawingView;

@end
