//
//  SDLayer.m
//  SceneDesigner
//

#import "SDLayer.h"

@implementation SDLayer

@synthesize isAccelerometerEnabled = _isAccelerometerEnabled;

- (void)dealloc
{
    SDNODE_DEALLOC();
    [super dealloc];
}

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    [dict setValue:[NSNumber numberWithBool:[self isAccelerometerEnabled]] forKey:@"isAccelerometerEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isTouchEnabled]] forKey:@"isTouchEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isMouseEnabled]] forKey:@"isMouseEnabled"];
    [dict setValue:[NSNumber numberWithBool:[self isKeyboardEnabled]] forKey:@"isKeyboardEnabled"];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (id)_setupFromDictionaryRepresentation:(NSDictionary *)dict
{
    SDLayer *retVal = [self node];
    retVal.isAccelerometerEnabled = [[dict valueForKey:@"isAccelerometerEnabled"] boolValue];
    retVal.isTouchEnabled = [[dict valueForKey:@"isTouchEnabled"] boolValue];
    retVal.isMouseEnabled = [[dict valueForKey:@"isMouseEnabled"] boolValue];
    retVal.isKeyboardEnabled = [[dict valueForKey:@"isKeyboardEnabled"] boolValue];
    retVal.contentSize = NSSizeToCGSize(NSSizeFromString([dict valueForKey:@"contentSize"]));
    
    return retVal;
}

SDNODE_FUNC_SRC

@end
