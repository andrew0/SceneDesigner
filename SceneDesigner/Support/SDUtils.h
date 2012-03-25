//
//  SDUtils.h
//  SceneDesigner
//

#import <Foundation/Foundation.h>

@class SDDocument;

@interface SDUtils : NSObject
{
    NSMutableDictionary *_classesDicitonary;
}

+ (id)sharedUtils;
- (Class)customClassFromCocosClass:(Class)cocosClass;
- (Class)cocosClassFromCustomClass:(Class)customClass;
- (SDDocument *)currentDocument;
- (NSUndoManager *)currentUndoManager;
- (NSString *)uniqueNameForString:(NSString *)string;

@end
