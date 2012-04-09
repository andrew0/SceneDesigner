//
//  SDLayer.m
//  SceneDesigner
//

#import "SDLayer.h"
#import "CCNode+Additions.h"

@implementation SDLayer

@synthesize isAccelerometerEnabled = _isAccelerometerEnabled;

- (id)init
{
    self = [super init];
    if (self)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
        [dict setValue:@"" forKey:@"isAccelerometerEnabled"];
        [dict setValue:@"" forKey:@"isTouchEnabled"];
        [dict setValue:@"" forKey:@"isMouseEnabled"];
        [dict setValue:@"" forKey:@"isKeyboardEnabled"];
        [self registerKeysFromDictionary:dict];
    }
    
    return self;
}

+ (Class)representedClass
{
    return [CCLayer class];
}

+ (id)node
{
    CCLayer *retVal = [CCLayer node];
    retVal.SDNode = [[[self alloc] init] autorelease];
    [retVal.SDNode setNode:retVal];
    return retVal;
}

+ (void)setupNode:(CCNode *)node withDictionaryRepresentation:(NSDictionary *)dict
{
    [super setupNode:node withDictionaryRepresentation:dict];
    
    CCLayer *layer = (CCLayer *)node;
    [(SDLayer *)layer.SDNode setIsAccelerometerEnabled:[[dict valueForKey:@"isAccelerometerEnabled"] boolValue]];
    layer.isTouchEnabled = [[dict valueForKey:@"isTouchEnabled"] boolValue];
    layer.isMouseEnabled = [[dict valueForKey:@"isMouseEnabled"] boolValue];
    layer.isKeyboardEnabled = [[dict valueForKey:@"isKeyboardEnabled"] boolValue];
    layer.contentSize = NSSizeToCGSize(NSSizeFromString([dict valueForKey:@"contentSize"]));
}

- (NSDictionary *)dictionaryRepresentation
{
    CCLayer *layer = (CCLayer *)_node;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryRepresentation]];
    [dict setValue:[NSNumber numberWithBool:[self isAccelerometerEnabled]] forKey:@"isAccelerometerEnabled"];
    [dict setValue:[NSNumber numberWithBool:[layer isTouchEnabled]] forKey:@"isTouchEnabled"];
    [dict setValue:[NSNumber numberWithBool:[layer isMouseEnabled]] forKey:@"isMouseEnabled"];
    [dict setValue:[NSNumber numberWithBool:[layer isKeyboardEnabled]] forKey:@"isKeyboardEnabled"];
    
    return dict;
}

@end
