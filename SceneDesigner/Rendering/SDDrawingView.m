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

@interface SDDrawingView ()
- (BOOL)willSnap;
- (NSArray *)snapPointsForNode:(CCNode<SDNodeProtocol> *)node;
@end

@implementation SDDrawingView

@synthesize nodesToAddOnEnter = _nodesToAddOnEnter;
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
        self.isMouseEnabled = YES;
    }
    
    return self;
}

- (void)onEnter
{
    [super onEnter];
    
    if (_background == nil)
    {
        // add repeating checkerboard background to indicate transparency
        _background = [[CCSprite spriteWithFile:@"checkerboard_dark.png"] retain];
        [self addChild:_background z:NSIntegerMin];
        
        // make texture repeating
        ccTexParams params = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
        [[_background texture] setTexParameters:&params];
        [_background setPosition:CGPointZero];
        [_background setAnchorPoint:CGPointZero];
        
        // resize background checkerboard
        CGSize s = [[CCDirector sharedDirector] winSize];
        [_background setContentSize:s];
        [_background setTextureRect:CGRectMake(0, 0, s.width, s.height)];
    }
    
    if (_nodesToAddOnEnter != nil && [_nodesToAddOnEnter count] > 0)
    {
        for (CCNode *node in _nodesToAddOnEnter)
            if ([node isKindOfClass:[CCNode class]])
                [self addChild:node];
        
        self.nodesToAddOnEnter = nil;
        
        NSArray *windowControllers = [[[NSDocumentController sharedDocumentController] currentDocument] windowControllers];
        if ([windowControllers count] > 0)
        {
            SDWindowController *wc = [windowControllers objectAtIndex:0];
            if ([wc isKindOfClass:[SDWindowController class]])
                [wc reloadOutlineView];
        }
    }
}

- (void)dealloc
{
    [_background release];
    self.nodesToAddOnEnter = nil;
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
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setSceneWidth:[self sceneWidth]];
        [um setActionName:NSLocalizedString(@"resize scene", nil)];
        
        [[[CCDirector sharedDirector] view] lockOpenGLContext];
        CGSize s = [[CCDirector sharedDirector] winSize];
        s.width = sceneWidth;
        [[CCDirector sharedDirector] reshapeProjection:s];
        [[[CCDirector sharedDirector] view] unlockOpenGLContext];
        
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
        NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
        [[um prepareWithInvocationTarget:self] setSceneHeight:[self sceneHeight]];
        [um setActionName:NSLocalizedString(@"resize scene", nil)];
        
        
        [[[CCDirector sharedDirector] view] lockOpenGLContext];
        CGSize s = [[CCDirector sharedDirector] winSize];
        s.height = sceneHeight;
        [[CCDirector sharedDirector] reshapeProjection:s];
        [[[CCDirector sharedDirector] view] unlockOpenGLContext];
        
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

- (NSArray *)snapPointsForNode:(CCNode<SDNodeProtocol> *)node
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[node snapPoints]];
    
    for (CCNode<SDNodeProtocol> *child in [node children])
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
            [array addObjectsFromArray:[self snapPointsForNode:child]];
    
    return array;
}

- (BOOL)willSnap
{
    if (![[[NSUserDefaults standardUserDefaults] valueForKey:@"snapToEdges"] isEqualTo:[NSNumber numberWithBool:YES]])
        return NO;
    
    // don't snap when alt key is down
    if ([NSEvent modifierFlags] & NSAlternateKeyMask)
        return NO;
    
    if (floorf([_selectedNode rotation]) != [_selectedNode rotation])
        return NO;
    
    // if node rotation is divisible by 360 (i.e. not rotated), then allow snapping
    // (TEMP) disable snapping for scaled nodes until fixed
    return ((int)floorf([_selectedNode rotation]) % 360 == 0) && ([_selectedNode scaleX] == 1 && [_selectedNode scaleY] == 1);
}

- (BOOL)ccMouseDown:(NSEvent *)event
{
    // don't create undo event for every reposition while dragging, just one at end
    [[[SDUtils sharedUtils] currentUndoManager] disableUndoRegistration];
    
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
    
    _initialNodePosition = _selectedNode.position;
    _initialMouseLocation = [[CCDirector sharedDirector] convertEventToGL:event];
    
    return YES;
}

- (BOOL)ccMouseDragged:(NSEvent *)event
{
#define kSnapDistance 7.0f
    // we're dragging the node, so don't deselect it
    _willDeselectNode = NO;
    
    CGPoint location = [[CCDirector sharedDirector] convertEventToGL:event];
    
    // drag the node
    if (_willDragNode)
    {
        if (_selectedNode)
        {
            CGPoint diff = ccpSub(location, _initialMouseLocation);
            diff = CGPointApplyAffineTransform(diff, CGAffineTransformMakeRotation(-CC_DEGREES_TO_RADIANS([_selectedNode rotation])));
            diff = CGPointApplyAffineTransform(diff, CGAffineTransformMakeScale([_selectedNode scaleX], [_selectedNode scaleY]));
            CGPoint worldPos = [_selectedNode convertToWorldSpace:_initialNodePosition];
            CGPoint newPos = [_selectedNode convertToNodeSpace:ccpAdd(worldPos, diff)];
            _selectedNode.position = newPos; // temporarily assign new pos so that convertToWorldSpace works
            
            if ([self willSnap])
            {
                // snap to other nodes in 
                NSMutableArray *points = [NSMutableArray array];
                for (CCNode<SDNodeProtocol> *child in [self children])
                    if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)] && child != _selectedNode)
                        [points addObjectsFromArray:[self snapPointsForNode:child]];
                
                // add snap points for canvas
                CGSize s = [[CCDirector sharedDirector] winSize];
                CGPoint canvasPoint1 = ccp(0,0);
                CGPoint canvasPoint2 = ccp(s.width, s.height);
                [points addObject:[NSValue valueWithBytes:&canvasPoint1 objCType:@encode(CGPoint)]];
                [points addObject:[NSValue valueWithBytes:&canvasPoint2 objCType:@encode(CGPoint)]];
                
                for (NSValue *value in points)
                {
                    CGPoint point;
                    [value getValue:&point];
                    
                    CGSize contentSize = [_selectedNode contentSize];
                    float sx = [_selectedNode scaleX];
                    float sy = [_selectedNode scaleY];
                    CGPoint snapPoint1 = [_selectedNode convertToWorldSpace:ccp(0,0)];
                    CGPoint snapPoint2 = [_selectedNode convertToWorldSpace:ccp(contentSize.width*sx,contentSize.height*sy)];
                    
                    if (abs(snapPoint1.x - point.x) <= kSnapDistance)
                        newPos.x = point.x - ([_selectedNode isRelativeAnchorPoint] ? [_selectedNode convertToNodeSpaceAR:snapPoint1] : [_selectedNode convertToNodeSpace:snapPoint1]).x;
                    if (abs(snapPoint1.y - point.y) <= kSnapDistance)
                        newPos.y = point.y - ([_selectedNode isRelativeAnchorPoint] ? [_selectedNode convertToNodeSpaceAR:snapPoint1] : [_selectedNode convertToNodeSpace:snapPoint1]).y;
                    
                    if (abs(snapPoint2.x - point.x) <= kSnapDistance)
                        newPos.x = point.x - ([_selectedNode isRelativeAnchorPoint] ? [_selectedNode convertToNodeSpaceAR:snapPoint2] : [_selectedNode convertToNodeSpace:snapPoint2]).x;
                    if (abs(snapPoint2.y - point.y) <= kSnapDistance)
                        newPos.y = point.y - ([_selectedNode isRelativeAnchorPoint] ? [_selectedNode convertToNodeSpaceAR:snapPoint2] : [_selectedNode convertToNodeSpace:snapPoint2]).y;
                }
                
                // assign new (snapped) position
                _selectedNode.position = newPos;
            }
        }
    }
    
    return YES;
}

- (BOOL)ccMouseUp:(NSEvent *)event
{
    NSUndoManager *um = [[SDUtils sharedUtils] currentUndoManager];
    if (![um isUndoRegistrationEnabled])
        [um enableUndoRegistration];
    
	// are we supposed to toggle the visibility?
	if (_willDeselectNode)
        self.selectedNode = nil;
    else if (_selectedNode)
    {
        if (!CGPointEqualToPoint(_selectedNode.position, _initialNodePosition))
        {
            // make undo event
            [[um prepareWithInvocationTarget:_selectedNode] setPosition:_initialNodePosition];
            [um setActionName:NSLocalizedString(@"repositioning", nil)];
        }
    }
    
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
