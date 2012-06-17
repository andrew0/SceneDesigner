//
//  SDUtils.h
//  SceneDesigner
//

#import <Foundation/Foundation.h>

@class SDDocument;
@class SDWindowController;

@interface SDUtils : NSObject
{
    NSMutableDictionary *_classesDictionary;
    SDDocument *_loadingDocument; ///< Document currently being loaded, used for currentDocument
}

@property (nonatomic, assign) SDDocument *loadingDocument;

+ (id)sharedUtils;
- (Class)customClassFromCocosClass:(Class)cocosClass;
- (Class)cocosClassFromCustomClass:(Class)customClass;
- (NSString *)uniqueNameForString:(NSString *)string;
- (NSString *)uniqueResourceNameForString:(NSString *)string;
- (NSArray *)allowedImageTypes;
- (void)removeObjectsWithKey:(NSString *)key fromDictionaryRepresentation:(NSMutableDictionary *)dict;

@end
