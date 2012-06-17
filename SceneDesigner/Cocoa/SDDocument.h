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
    NSSize _sceneSizeToSet;
}

@property (nonatomic, retain) SDDrawingView *drawingView;
@property (nonatomic, readonly) NSArray *allResourceNames;

- (NSDictionary *)resources;

@end
