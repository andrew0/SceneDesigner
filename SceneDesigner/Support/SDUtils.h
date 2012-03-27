//
//  SDUtils.h
//  SceneDesigner
//

#import <Foundation/Foundation.h>

@class SDDocument;
@class SDWindowController;

@interface SDUtils : NSObject
{
    NSMutableDictionary *_classesDicitonary;
}

+ (id)sharedUtils;
- (Class)customClassFromCocosClass:(Class)cocosClass;
- (Class)cocosClassFromCustomClass:(Class)customClass;
- (SDDocument *)currentDocument;
- (SDWindowController *)currentWindowController;
- (NSUndoManager *)currentUndoManager;
- (NSString *)uniqueNameForString:(NSString *)string;
- (NSArray *)allowedImageTypes;

@end
