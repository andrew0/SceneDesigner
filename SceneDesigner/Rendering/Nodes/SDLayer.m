//
//  SDLayer.m
//  SceneDesigner
//

#import "SDLayer.h"

@implementation SDLayer

@synthesize isAccelerometerEnabled = _isAccelerometerEnabled;

- (id)init
{
    self = [super init];
    if (self)
        SDNODE_INIT();
    
    return self;
}

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

- (void)setIsAccelerometerEnabled:(BOOL)isAccelerometerEnabled
{
    if (isAccelerometerEnabled != _isAccelerometerEnabled)
    {
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setIsAccelerometerEnabled:_isAccelerometerEnabled];
        [um setActionName:NSLocalizedString(@"accelerometer toggling", nil)];
        _isAccelerometerEnabled = isAccelerometerEnabled;
    }
}

- (void)setIsTouchEnabled:(BOOL)isTouchEnabled
{
    if (isTouchEnabled != isTouchEnabled_)
    {
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setIsTouchEnabled:isTouchEnabled_];
        [um setActionName:NSLocalizedString(@"touch toggling", nil)];
        isTouchEnabled_ = isTouchEnabled;
    }
}

- (void)setIsKeyboardEnabled:(BOOL)isKeyboardEnabled
{
    if (isKeyboardEnabled != isKeyboardEnabled_)
    {
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setIsMouseEnabled:isKeyboardEnabled_];
        [um setActionName:NSLocalizedString(@"keyboard toggling", nil)];
        isKeyboardEnabled_ = isKeyboardEnabled;
    }
}

- (void)setIsMouseEnabled:(BOOL)isMouseEnabled
{
    if (isMouseEnabled != isMouseEnabled_)
    {
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setIsMouseEnabled:isMouseEnabled_];
        [um setActionName:NSLocalizedString(@"mouse toggling", nil)];
        isMouseEnabled_ = isMouseEnabled;
    }
}

SDNODE_FUNC_SRC

@end
