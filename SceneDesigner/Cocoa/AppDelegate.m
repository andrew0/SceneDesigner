//
//  AppDelegate.m
//  SceneDesigner
//

#import "AppDelegate.h"
#import "SDDrawingView.h"
#import "SDDocumentController.h"
#import "SDGLView.h"
#import "SDDocument.h"
#import "NSThread+Blocks.h"

@implementation SceneDesignerAppDelegate

@synthesize glView = _glView;

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // ensure that NSDocumentController singleton is initialized as SDDocumentController
    [SDDocumentController sharedDocumentController];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // set default values for NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![[defaults valueForKey:@"fileFormat"] isEqualToString:@"Property List"] &&
        ![[defaults valueForKey:@"fileFormat"] isEqualToString:@"JSON"])
    {
        [defaults setValue:@"Property List" forKey:@"fileFormat"];
    }
    
    if (![[defaults valueForKey:@"snapToEdges"] isEqualTo:[NSNumber numberWithBool:YES]] &&
        ![[defaults valueForKey:@"snapToEdges"] isEqualTo:[NSNumber numberWithBool:NO]])
    {
        [defaults setValue:[NSNumber numberWithBool:YES] forKey:@"snapToEdges"];
    }
    
    if (![[defaults valueForKey:@"nonIntegerPositions"] isEqualTo:[NSNumber numberWithBool:YES]] &&
        ![[defaults valueForKey:@"nonIntegerPositions"] isEqualTo:[NSNumber numberWithBool:NO]])
    {
        [defaults setValue:[NSNumber numberWithBool:NO] forKey:@"nonIntegerPositions"];
    }
    
    [defaults synchronize];
}

// call startCocos2D manually after document loads instead of in applicationDidFinishLaunching:
// because if the glView hasn't been added to a document yet it will crash.
- (void)startCocos2D
{
    [[_glView openGLContext] makeCurrentContext];
    
    // for some reason there's an OpenGL error in CCConfiguration init if we change
    // the projection, so make sure it's initialized before changing it
    [CCConfiguration sharedConfiguration];
    
    CCDirectorMac *director = (CCDirectorMac *)[CCDirector sharedDirector];
    [director setResizeMode:kCCDirectorResize_NoScale];
    
    // set the openGL view
    [director setView:_glView];
    
    // set our projection delegate to be the SDGLView, which is the same as
    // kCCDirectorProjection2D except it offsets the viewport by the scrollbar
    // amount
    [director setProjection:kCCDirectorProjectionCustom];
    [director setDelegate:_glView];
    
    // get scene
    [director runWithScene:[CCScene node]];
    
    // get notifications for new document
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentDocumentDidChange:) name:@"CurrentDocumentDidChangeNotification" object:nil];
}

- (void)pauseCocos2D
{
    CCDirector *director = [CCDirector sharedDirector];
    if ([director runningScene] != nil)
        [director replaceScene:[CCScene node]];
}

- (void)resumeCocos2D
{
}

- (void)currentDocumentDidChange:(NSNotification *)notification
{
    [[_glView openGLContext] makeCurrentContext];
    
    if ([[notification object] isKindOfClass:[SDDocument class]])
    {
        SDDocument *document = (SDDocument *)[notification object];
        
        if ([document drawingView] == nil)
            [document setDrawingView:[SDDrawingView node]];
        
        if ( ![[[CCDirector sharedDirector] runningScene] isEqualTo:[[document drawingView] scene]] )
            [[CCDirector sharedDirector] replaceScene:[[document drawingView] scene]];
    }
}

- (void)dealloc
{
    [[CCDirector sharedDirector] end];
    [super dealloc];
}

@end
