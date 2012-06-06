//
//  SDSelectionLayer.m
//  SceneDesigner
//

#import "SDSelectionLayer.h"
#import "CCNode+Additions.h"
#import "SDDrawingView.h"

@implementation SDSelectionLayer

- (id)init
{
    self = [super init];
    if (self)
    {
        self.isMouseEnabled = YES;
        
        _rotate = [[CCSprite spriteWithFile:@"rotate_handle.png"] retain];
        [[_rotate texture] setAliasTexParameters];
        [_rotate setAnchorPoint:ccp(0.5f, 0)];
        [self addChild:_rotate];
        
        _tl = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_tl texture] setAliasTexParameters];
        [self addChild:_tl];
        
        _tm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_tm texture] setAliasTexParameters];
        [self addChild:_tm];
        
        _tr = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_tr texture] setAliasTexParameters];
        [self addChild:_tr];
        
        _bl = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_bl texture] setAliasTexParameters];
        [self addChild:_bl];
        
        _bm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_bm texture] setAliasTexParameters];
        [self addChild:_bm];
        
        _br = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_tl texture] setAliasTexParameters];
        [self addChild:_br];
        
        _lm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_lm texture] setAliasTexParameters];
        [self addChild:_lm];
        
        _rm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [[_rm texture] setAliasTexParameters];
        [self addChild:_rm];
        
        [self updateForSelection:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [_rotate release];
    [_tl release];
    [_tm release];
    [_tr release];
    [_bl release];
    [_bm release];
    [_br release];
    [_lm release];
    [_rm release];
    [super dealloc];
}

- (void)onEnter
{
    [super onEnter];
    
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    [[self parent] addObserver:self forKeyPath:@"selectedNode" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
}

- (void)onExit
{
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    [[self parent] removeObserver:self forKeyPath:@"selectedNode"];
    
    [super onExit];
}

- (NSInteger)mouseDelegatePriority
{
    return NSIntegerMin;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [self parent])
    {
        CCNode *oldNode = [change objectForKey:NSKeyValueChangeOldKey];
        @try
        {
            [oldNode removeObserver:self forKeyPath:@"position"];
            [oldNode removeObserver:self forKeyPath:@"contentSize"];
            [oldNode removeObserver:self forKeyPath:@"anchorPoint"];
            [oldNode removeObserver:self forKeyPath:@"scaleX"];
            [oldNode removeObserver:self forKeyPath:@"scaleY"];
            [oldNode removeObserver:self forKeyPath:@"rotation"];
            [oldNode removeObserver:self forKeyPath:@"isRelativeAnchorPoint"];
            [oldNode removeObserver:self forKeyPath:@"skewX"];
            [oldNode removeObserver:self forKeyPath:@"skewY"];

        }
        @catch (NSException *exception) {}
        
        CCNode *selectedNode = [change objectForKey:NSKeyValueChangeNewKey];
        [selectedNode addObserver:self forKeyPath:@"position" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"contentSize" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"anchorPoint" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"scaleX" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"scaleY" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"rotation" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"isRelativeAnchorPoint" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"skewX" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"skewY" options:0 context:NULL];
    }
    else if ([object isKindOfClass:[CCNode class]])
    {
        [self updateForSelection:object];
    }
}

- (void)updateForSelection:(CCNode *)node
{
    BOOL visible = (node != nil);
    [self setVisible:visible];
    
    if (node != nil)
    {
        CGSize s = [node contentSize];
        CGPoint tlPos = [node convertToWorldSpace:ccp(0, s.height)];
        CGPoint tmPos = [node convertToWorldSpace:ccp(s.width/2, s.height)];
        CGPoint trPos = [node convertToWorldSpace:ccp(s.width, s.height)];
        CGPoint blPos = [node convertToWorldSpace:ccp(0, 0)];
        CGPoint bmPos = [node convertToWorldSpace:ccp(s.width/2, 0)];
        CGPoint brPos = [node convertToWorldSpace:ccp(s.width, 0)];
        CGPoint lmPos = [node convertToWorldSpace:ccp(0, s.height/2)];
        CGPoint rmPos = [node convertToWorldSpace:ccp(s.width, s.height/2)];
        CGPoint rotatePos = [node convertToWorldSpace:ccp(s.width/2, s.height)];
        
        [_tl setPosition:tlPos];
        [_tm setPosition:tmPos];
        [_tr setPosition:trPos];
        [_bl setPosition:blPos];
        [_bm setPosition:bmPos];
        [_br setPosition:brPos];
        [_lm setPosition:lmPos];
        [_rm setPosition:rmPos];
        [_rotate setPosition:rotatePos];
    }
}

- (BOOL)ccMouseDown:(NSEvent *)event
{
    _isDragging = NO;
    
    CCNode *node = nil;
    for (CCNode *child in [[[self children] getNSArray] reverseObjectEnumerator])
    {
        if ( [child isEventInRect:event] )
        {
            node = child;
            break;
        }
    }
    
    if (!node)
        return NO;
    
    _trackedNode = node;
    _initialMousePosition = [[CCDirector sharedDirector] convertEventToGL:event];
    
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    CCNode *selectedNode = [(SDDrawingView *)[self parent] selectedNode];
    _initialPosition = [selectedNode position];
    _initialScaleX = [selectedNode scaleX];
    _initialScaleY = [selectedNode scaleY];
    
    return YES;
}

- (BOOL)ccMouseDragged:(NSEvent *)event
{
#define kMinimumDistance 2.0f
    
    if (!_trackedNode)
        return NO;
    
    CGPoint pos = [[CCDirector sharedDirector] convertEventToGL:event];
    CGPoint delta = ccpSub(pos, _initialMousePosition);
    if (!_isDragging)
    {
        if (fabs(delta.x) >= kMinimumDistance || fabs(delta.y) >= kMinimumDistance)
            _isDragging = YES;
        else
            return YES;
    }
    
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    CCNode *selectedNode = [(SDDrawingView *)[self parent] selectedNode];
    CGSize s = [selectedNode contentSize];
    CGPoint anchor = [selectedNode anchorPoint];
    CGPoint newPos = _initialPosition;
    
    if (_trackedNode == _rotate)
    {
        
    }
    
    if (_trackedNode == _rm || _trackedNode == _tr || _trackedNode == _br)
    {
        CGFloat newWidth = pos.x - [selectedNode convertToWorldSpace:ccp(0,0)].x;
        [selectedNode setScaleX:newWidth / s.width];
        
        newPos.x += (newWidth - s.width * _initialScaleX) * anchor.x;
    }
    
    if (_trackedNode == _lm || _trackedNode == _tl || _trackedNode == _bl)
    {
        CGFloat newWidth = [selectedNode convertToWorldSpace:ccp(s.width,0)].x - pos.x;
        [selectedNode setScaleX:newWidth / s.width];
        
        newPos.x -= (newWidth - s.width * _initialScaleX) * (1 - anchor.x);
    }
    
    if (_trackedNode == _tm || _trackedNode == _tl || _trackedNode == _tr)
    {
        CGFloat newHeight = pos.y - [selectedNode convertToWorldSpace:ccp(0,0)].y;
        [selectedNode setScaleY:newHeight / s.height];
        
        newPos.y += (newHeight - s.height * _initialScaleY) * anchor.y;
    }
    
    if (_trackedNode == _bm || _trackedNode == _bl || _trackedNode == _br)
    {
        CGFloat newHeight = [selectedNode convertToWorldSpace:ccp(0,s.height)].y - pos.y;
        [selectedNode setScaleY:newHeight / s.height];
        
        newPos.y -= (newHeight - s.height * _initialScaleY) * (1 - anchor.y);
    }
    
    [selectedNode setPosition:newPos];
    
    return YES;
}

- (BOOL)ccMouseUp:(NSEvent *)event
{
    _isDragging = NO;
    _initialMousePosition = ccp(0,0);
    _trackedNode = nil;
    return NO;
}

@end
