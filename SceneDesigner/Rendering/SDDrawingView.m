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
        self.isKeyboardEnabled = YES;
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
    if (sceneWidth <= 0)
        return;
    
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
    if (sceneHeight <= 0)
        return;
    
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
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
        {
            CCNode<SDNodeProtocol> *grandchild = [self nodeForEvent:event withParent:child];
            if (grandchild != nil)
                return grandchild;
            else if ([child isEventInRect:event])
                return child;
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
                    if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
                        [points addObjectsFromArray:[self snapPointsForNode:child]];
                [points removeObjectsInArray:[_selectedNode snapPoints]];
                
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
                    
                    // get snap points (i.e. points on node that will can snap to another node)
                    CGSize contentSize = [_selectedNode contentSize];
                    float sx = [_selectedNode scaleX];
                    float sy = [_selectedNode scaleY];
                    CGPoint snapPoint1 = [_selectedNode convertToWorldSpace:ccp(0,0)];
                    CGPoint snapPoint2 = [_selectedNode convertToWorldSpace:ccp(contentSize.width*sx,contentSize.height*sy)];
                    
                    // transform points into node space
                    CGAffineTransform t = [_selectedNode parentToNodeTransform];
                    CGPoint transformedSnapPoint1 = CGPointApplyAffineTransform(snapPoint1, t);
                    CGPoint transformedSnapPoint2 = CGPointApplyAffineTransform(snapPoint2, t);
                    
                    // subtract anchor point if necessary
                    if ([_selectedNode isRelativeAnchorPoint])
                    {
                        transformedSnapPoint1 = ccpSub(transformedSnapPoint1, [_selectedNode anchorPointInPoints]);
                        transformedSnapPoint2 = ccpSub(transformedSnapPoint2, [_selectedNode anchorPointInPoints]);
                    }
                    
                    // apply snapping
                    if (abs(snapPoint1.x - point.x) <= kSnapDistance)
                        newPos.x = point.x - transformedSnapPoint1.x;
                    if (abs(snapPoint1.y - point.y) <= kSnapDistance)
                        newPos.y = point.y - transformedSnapPoint1.y;
                    
                    if (abs(snapPoint2.x - point.x) <= kSnapDistance)
                        newPos.x = point.x - transformedSnapPoint2.x;
                    if (abs(snapPoint2.y - point.y) <= kSnapDistance)
                        newPos.y = point.y - transformedSnapPoint2.y;
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

- (BOOL)ccKeyDown:(NSEvent *)event
{
//    [[[SDUtils sharedUtils] currentUndoManager] beginUndoGrouping];
    
    // keycodes available at http://forums.macrumors.com/showpost.php?p=8428116&postcount=2
    NSUInteger modifiers = [event modifierFlags];
    unsigned short keyCode = [event keyCode];
    SDWindowController *wc = [[SDUtils sharedUtils] currentWindowController];
    
    // remove node
    switch (keyCode)
    {
        case 0x33: // delete
        case 0x75: // forward delete
            [wc removeNodeFromLayer:_selectedNode];
            break;
        default:
            break;
    }
    
    // if option/alt key is pressed....
    if(modifiers & NSAlternateKeyMask)
    {
        // move anchor point
        CGFloat increment = (modifiers & NSShiftKeyMask) ? 0.1f : 0.01f;
        CGPoint anchorPoint = [_selectedNode anchorPoint];
        
        switch(keyCode)
        {
            case 0x7B: // left arrow
                anchorPoint.x -= increment;
                break;
            case 0x7C: // right arrow
                anchorPoint.x += increment;
                break;
            case 0x7D: // down arrow
                anchorPoint.y -= increment;
                break;
            case 0x7E: // up arrow
                anchorPoint.y += increment;
                break;
            default:
                return YES;
        }
        
        [_selectedNode setAnchorPoint:anchorPoint];
        
        return YES;
    }
    else if (modifiers & NSControlKeyMask)
    {
        // rotate node
        float increment = (modifiers & NSShiftKeyMask) ? 10.0f : 1.0f;
        float rotation = [_selectedNode rotation];
        
        switch(keyCode)
        {
            case 0x7B: // left arrow
                rotation -= increment;
                break;
            case 0x7C: // right arrow
                rotation += increment;
                break;
            default:
                return YES;
        }
        
        [_selectedNode setRotation:rotation];
        
        return YES;
    }
    else if (modifiers & NSCommandKeyMask)
    {
        // change z
        NSInteger zOrder = [_selectedNode zOrder];
        
        switch(keyCode)
        {
            case 0x1E: // cmd-]
                zOrder += 1;
                break;
            case 0x21: // cmd-[
                zOrder -= 1;
                break;
            default:
                return YES;
        }
        
        [_selectedNode setZOrder:zOrder];
    }
    else
    {
        // move position & change z
        NSInteger increment = (modifiers & NSShiftKeyMask) ? 10 : 1;
        CGPoint position = [_selectedNode position];
        NSInteger zOrder = [_selectedNode zOrder];
        
        switch(keyCode)
        {
            case 0x7B: // left arrow
                position.x -= increment;
                break;
            case 0x7C: // right arrow
                position.x += increment;
                break;
            case 0x7D: // down arrow
                position.y -= increment;
                break;
            case 0x7E: // up arrow
                position.y += increment;
                break;
            case 0x74: // page up
                zOrder += 1;
                break;
            case 0x79: // page down
                zOrder -= 1;
                break;
            default:
                return YES;
        }
        
        [_selectedNode setPosition:position];
        [_selectedNode setZOrder:zOrder];
    }

    return YES;
}

- (BOOL)ccKeyUp:(NSEvent *)event
{
//    [[[SDUtils sharedUtils] currentUndoManager] endUndoGrouping];
    return YES;
}

- (void)sortAllChildren
{
    BOOL shouldPostNotification = isReorderChildDirty_;
    [super sortAllChildren];
    if (shouldPostNotification)
        [[NSNotificationCenter defaultCenter] postNotificationName:CCNodeDidReorderChildren object:self];
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
