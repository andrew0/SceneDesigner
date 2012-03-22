//
//  AppDelegate.h
//  SceneDesigner
//

#import "cocos2d.h"

@class SDGLView;

@interface SceneDesignerAppDelegate : NSObject <NSApplicationDelegate>
{
    SDGLView *_glView;
}

@property (assign) IBOutlet SDGLView *glView;

- (void)startCocos2D;
- (void)pauseCocos2D;
- (void)resumeCocos2D;
- (void)currentDocumentDidChange:(NSNotification *)notification;

@end
