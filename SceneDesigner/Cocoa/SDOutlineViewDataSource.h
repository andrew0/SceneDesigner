//
//  SDOutlineViewDataSource.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

@interface SDOutlineViewDataSource : NSObject <NSOutlineViewDataSource>
{
    IBOutlet NSWindowController *_windowController;
}

- (CCArray *)childrenOfNode:(CCNode *)node;
- (CCArray *)drawingViewChildren;

@end
