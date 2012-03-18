//
//  SDDrawingView.m
//  SceneDesigner
//

#import "SDDrawingView.h"
#import "SDNode.h"
#import "SDSprite.h"
#import "SDLabelBMFont.h"
#import "CCNode+Additions.h"
#import "SDWindowController.h"
#import "NSThread+Blocks.h"

@implementation SDDrawingView

@synthesize selectedNode = _selectedNode;
@dynamic sceneWidth;
@dynamic sceneHeight;

+ (CCScene *)scene
{
    CCScene *scene = [CCScene node];
    SDDrawingView *layer = [SDDrawingView node];
    [scene addChild: layer];
    return scene;
}

- (CCScene *)scene
{
    CCScene *scene = nil;
    if (![self parent])
    {
        scene = [CCScene node];
        [scene addChild:self];
    }
    else if ([[self parent] isKindOfClass:[CCScene class]])
        scene = (CCScene *)[self parent];
    
    return scene;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        // add repeating checkerboard background to indicate transparency
        _background = [CCSprite spriteWithFile:@"checkerboard_dark.png"];
        [self addChild:_background];
        
        // make texture repeating
        ccTexParams params = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
        [[_background texture] setTexParameters:&params];
        [_background setPosition:CGPointZero];
        [_background setAnchorPoint:CGPointZero];
        
        // resize background checkerboard
        CGSize s = [[CCDirector sharedDirector] winSize];
        [_background setContentSize:s];
        [_background setTextureRect:CGRectMake(0, 0, s.width, s.height)];
        
        self.isMouseEnabled = YES;
    }
    
    return self;
}

- (void)dealloc
{
    [_background release];
    self.selectedNode = nil;
    [super dealloc];
}

- (void)setSelectedNode:(CCNode<SDNodeProtocol> *)selectedNode
{
    if (selectedNode != _selectedNode)
    {
        [_selectedNode setIsSelected:NO];
        [_selectedNode release];
        _selectedNode = [selectedNode retain];
        [_selectedNode setIsSelected:YES];
    }
}

// TODO: listen to change in reshapeProjection and add willChangeValueForKey:
// and didChangeValueForKey: for sceneWidth and sceneHeight
- (void)setSceneWidth:(CGFloat)sceneWidth
{
    if (sceneWidth != [self sceneWidth])
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [[um prepareWithInvocationTarget:self] setSceneWidth:[self sceneWidth]];
        [um setActionName:NSLocalizedString(@"resize scene", nil)];
        
        CGSize s = [[CCDirector sharedDirector] winSize];
        s.width = sceneWidth;
        [[CCDirector sharedDirector] reshapeProjection:s];
        
        // resize background checkerboard
        [_background setContentSize:s];
        [_background setTextureRect:CGRectMake(0, 0, s.width, s.height)];
    }
}

- (CGFloat)sceneWidth
{
    return [[CCDirector sharedDirector] winSize].width;
}

- (void)setSceneHeight:(CGFloat)sceneHeight
{
    if (sceneHeight != [self sceneHeight])
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [[um prepareWithInvocationTarget:self] setSceneHeight:[self sceneHeight]];
        [um setActionName:NSLocalizedString(@"resize scene", nil)];
        
        CGSize s = [[CCDirector sharedDirector] winSize];
        s.height = sceneHeight;
        [[CCDirector sharedDirector] reshapeProjection:s];
        
        // resize background checkerboard
        [_background setContentSize:s];
        [_background setTextureRect:CGRectMake(0, 0, s.width, s.height)];
    }
}

- (CGFloat)sceneHeight
{
    return [[CCDirector sharedDirector] winSize].height;
}

- (CCNode<SDNodeProtocol> *)nodeForEvent:(NSEvent *)event withParent:(CCNode *)parent
{
    for (CCNode<SDNodeProtocol> *child in [[[parent children] getNSArray] reverseObjectEnumerator])
    {
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)] && [child isEventInRect:event])
        {
            CCNode<SDNodeProtocol> *grandchild = [self nodeForEvent:event withParent:child];
            return (grandchild != nil) ? grandchild : child;
        }
    }
    
    return nil;
}

- (CCNode<SDNodeProtocol> *)nodeForEvent:(NSEvent *)event
{
    return [self nodeForEvent:event withParent:self];
}

- (BOOL)ccMouseDown:(NSEvent *)event
{
    // don't create undo event for every reposition while dragging, just one at end
    [[[[NSDocumentController sharedDocumentController] currentDocument] undoManager] disableUndoRegistration];
    
    _willDragNode = NO;
    _willDeselectNode = NO;
    
    CCNode<SDNodeProtocol> *node = [self nodeForEvent:event];
    if (node)
    {
        // if new node is clicked, select it
        // if same node is clicked, deselect it
        if (_selectedNode != node)
            self.selectedNode = node;
        else
            _willDeselectNode = YES;
        
        _willDragNode = YES;
    }
    
    // if we touch outside of selected sprite, deselect it
    if(_selectedNode && ![_selectedNode isEventInRect:event])
        self.selectedNode = nil;
    
    _initialPosition = _selectedNode.position;
    _prevLocation = [[CCDirector sharedDirector] convertEventToGL:event];
    
    return YES;
}

- (BOOL)ccMouseDragged:(NSEvent *)event
{
    // we're dragging the node, so don't deselect it
    _willDeselectNode = NO;
    
    CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
    
    // drag the node
    if (_willDragNode)
    {
        if (_selectedNode)
        {
            CGPoint diff = ccpSub(location, _prevLocation);
            CGPoint currentPos = [_selectedNode position];
            _selectedNode.position = ccpAdd(currentPos, diff);
        }
    }
    
    _prevLocation = location;
    
    return YES;
}

- (BOOL)ccMouseUp:(NSEvent *)event
{
    NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
    if (![um isUndoRegistrationEnabled])
        [um enableUndoRegistration];
    
	// are we supposed to toggle the visibility?
	if (_willDeselectNode)
        self.selectedNode = nil;
    else if (_selectedNode)
    {
        if (!CGPointEqualToPoint(_selectedNode.position, _initialPosition))
        {
            // make undo event
            [[um prepareWithInvocationTarget:_selectedNode] setPosition:_initialPosition];
            [um setActionName:NSLocalizedString(@"repositioning", nil)];
        }
    }
    
	_prevLocation = [[CCDirector sharedDirector] convertEventToGL:event];
    
	return YES;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    // don't do anything
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

@end
