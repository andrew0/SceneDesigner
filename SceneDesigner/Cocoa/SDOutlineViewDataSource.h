//
//  SDOutlineViewDataSource.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>
#import "cocos2d.h"

#define CLASS_NAME_KEY @"className"
#define CHILDREN_KEY @"children"
#define NODE_KEY @"node"

@interface SDOutlineViewDataSource : NSObject <NSOutlineViewDataSource>
{
    NSMutableArray *_array;
    IBOutlet NSWindowController *_windowController;
}

- (NSDictionary *)dictionaryForNode:(CCNode *)node;

@end
