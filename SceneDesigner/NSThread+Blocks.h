//
//  NSThread+Blocks.h
//  SceneDesigner
//

#import <Foundation/Foundation.h>

@interface NSThread (Blocks)

- (void)performBlock:(void (^)())block;
- (void)performBlock:(void (^)())block waitUntilDone:(BOOL)wait;

@end
