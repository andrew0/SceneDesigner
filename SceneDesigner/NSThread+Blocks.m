//
//  NSThread+Blocks.m
//  SceneDesigner
//

#import "NSThread+Blocks.h"

@implementation NSThread (Blocks)

- (void)runBlock:(void (^)())block
{
    block();
}

- (void)performBlock:(void (^)())block
{
    [self performBlock:block waitUntilDone:NO];
}

- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait
{
    if ([[NSThread currentThread] isEqualTo:self] && wait)
        block();
    else
        [self performSelector:@selector(runBlock:) onThread:self withObject:[[block copy] autorelease] waitUntilDone:wait];
}

@end
