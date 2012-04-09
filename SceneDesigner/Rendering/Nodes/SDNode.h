//
//  SDNode.h
//  SceneDesigner
//

#import "cocos2d.h"

extern NSString *CCNodeDidReorderChildren;
extern NSString *SDNodeUTI;

@interface SDNode : NSObject <NSCoding, NSPasteboardReading, NSPasteboardWriting>
{
    CCNode *_node;
    NSMutableDictionary *_undoKeyDictionary;
    NSString *_name;
}

@property (nonatomic, assign) CCNode *node;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) CGFloat positionX, positionY;
@property (nonatomic, assign) CGFloat anchorPointX, anchorPointY;
@property (nonatomic, assign) CGFloat contentSizeWidth, contentSizeHeight;

// The class of the node that is being represented
+ (Class)representedClass;

// Returns an autoreleased instance of the represented node
+ (id)node;

// Sets up a node based on information serialized in a dictionary
+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict;

// Returns an autoreleased instance of the represented node and sets it up based on information serialized in a dictionary
+ (id)nodeWithDictionaryRepresentation:(NSDictionary *)dict;

// Returns a dictionary that serializes all the node info
- (NSDictionary *)dictionaryRepresentation;

// Register keys of a dictionary for undo/redo support. The value of the keys in the dictionary will be used as the action name.
- (void)registerKeysFromDictionary:(NSDictionary *)dict;

- (NSArray *)snapPoints;

@end
