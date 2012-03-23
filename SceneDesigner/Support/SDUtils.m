//
//  SDUtils.m
//  SceneDesigner
//

#import "SDUtils.h"

@implementation SDUtils

+ (id)sharedUtils
{
    static dispatch_once_t pred;
    static id shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _classesDicitonary = [[NSMutableDictionary alloc] initWithCapacity:5];
        [_classesDicitonary setObject:@"CCNode" forKey:@"SDNode"];
        [_classesDicitonary setObject:@"CCSprite" forKey:@"SDSprite"];
        [_classesDicitonary setObject:@"CCLayer" forKey:@"SDLayer"];
        [_classesDicitonary setObject:@"CCLayerColor" forKey:@"SDLayerColor"];
        [_classesDicitonary setObject:@"CCLabelBMFont" forKey:@"SDLabelBMFont"];
    }
    
    return self;
}

- (Class)customClassFromCocosClass:(Class)cocosClass
{
    NSArray *classes = [_classesDicitonary allKeysForObject:NSStringFromClass(cocosClass)];
    if ([classes count] > 0)
        return NSClassFromString([classes objectAtIndex:0]);
    
    return nil;
}

- (Class)cocosClassFromCustomClass:(Class)customClass
{
    return NSClassFromString([_classesDicitonary objectForKey:NSStringFromClass(customClass)]);
}

@end
