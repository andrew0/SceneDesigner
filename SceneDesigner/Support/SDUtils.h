//
//  SDUtils.h
//  SceneDesigner
//

#import <Foundation/Foundation.h>

@interface SDUtils : NSObject
{
    NSMutableDictionary *_classesDicitonary;
}

+ (id)sharedUtils;
- (Class)customClassFromCocosClass:(Class)cocosClass;
- (Class)cocosClassFromCustomClass:(Class)customClass;

@end
