//
//  SDNode.m
//  SceneDesigner
//

#import "SDNode.h"

@implementation SDNode

SDNODE_FUNC_SRC

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

@end
