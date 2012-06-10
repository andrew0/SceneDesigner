//
//  SDSelectionLayer.m
//  SceneDesigner
//

#import "SDSelectionLayer.h"
#import "CCNode+Additions.h"
#import "SDDrawingView.h"
#import "SDDocumentController.h"

enum
{
    kNoneTag = 100,
    kTopLeftTag,
    kTopMiddleTag,
    kTopRightTag,
    kBottomLeftTag,
    kBottomMiddleTag,
    kBottomRightTag,
    kLeftMiddleTag,
    kRightMiddleTag,
    kRotateTag
};

@implementation NSImage (Rotate)

- (NSImage *)rotateImage:(float)rotation
{
    NSRect rect = NSMakeRect(0, 0, [self size].height, [self size].width);
    NSImage *rotated = [[NSImage alloc] initWithSize:rect.size];
    
    [rotated lockFocus];
    
    NSAffineTransform *t = [NSAffineTransform transform];
    NSPoint center = NSMakePoint([self size].width/2, [self size].height/2);
    
    [t translateXBy:center.x yBy:center.y];
    [t rotateByDegrees:rotation];
    [t translateXBy:-center.x yBy:-center.y];
    [t concat];
    
    [self drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeDestinationOver fraction:1.0f];
    
    [rotated unlockFocus];
    
    return [rotated autorelease];
}

@end

@implementation SDSelectionLayer

- (id)init
{
    self = [super init];
    if (self)
    {
        // create rotated cursors
        NSCursor *tlCursor = [NSCursor resizeUpDownCursor];
        NSImage *tlImage = [[tlCursor image] rotateImage:45.0f];
        NSSize s = [tlImage size];
        _rotatedCounterclockwiseCursor = [[NSCursor alloc] initWithImage:tlImage hotSpot:NSMakePoint(s.width/2, s.height/2)];
        
        NSCursor *trCursor = [NSCursor resizeUpDownCursor];;
        NSImage *trImage = [[trCursor image] rotateImage:-45.0f];
        _rotatedClockwiseCursor = [[NSCursor alloc] initWithImage:trImage hotSpot:NSMakePoint(s.width/2, s.height/2)];
        
        self.isMouseEnabled = YES;
        
        _rotate = [[CCSprite spriteWithFile:@"rotate_handle.png"] retain];
        [_rotate setTag:kRotateTag];
        [[_rotate texture] setAliasTexParameters];
        [_rotate setAnchorPoint:ccp(0.5f, 0)];
        [self addChild:_rotate];
        
        _tl = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_tl setTag:kTopLeftTag];
        [[_tl texture] setAliasTexParameters];
        [self addChild:_tl];
        
        _tm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_tm setTag:kTopMiddleTag];
        [[_tm texture] setAliasTexParameters];
        [self addChild:_tm];
        
        _tr = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_tr setTag:kTopRightTag];
        [[_tr texture] setAliasTexParameters];
        [self addChild:_tr];
        
        _bl = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_bl setTag:kBottomLeftTag];
        [[_bl texture] setAliasTexParameters];
        [self addChild:_bl];
        
        _bm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_bm setTag:kBottomMiddleTag];
        [[_bm texture] setAliasTexParameters];
        [self addChild:_bm];
        
        _br = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_br setTag:kBottomRightTag];
        [[_tl texture] setAliasTexParameters];
        [self addChild:_br];
        
        _lm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_lm setTag:kLeftMiddleTag];
        [[_lm texture] setAliasTexParameters];
        [self addChild:_lm];
        
        _rm = [[CCSprite spriteWithFile:@"resize_handle.png"] retain];
        [_rm setTag:kRightMiddleTag];
        [[_rm texture] setAliasTexParameters];
        [self addChild:_rm];
        
        _currentTag = kNoneTag;
        
        [self updateForSelection:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [_rotatedClockwiseCursor release];
    [_rotatedCounterclockwiseCursor release];
    [_trackingAreas release];
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
            [oldNode removeObserver:self forKeyPath:@"ignoreAnchorPointForPosition"];
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
        [selectedNode addObserver:self forKeyPath:@"ignoreAnchorPointForPosition" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"skewX" options:0 context:NULL];
        [selectedNode addObserver:self forKeyPath:@"skewY" options:0 context:NULL];
    }
    else if ([object isKindOfClass:[CCNode class]])
    {
        [self updateForSelection:object];
    }
}

- (void)draw
{
    if ([self visible])
    {
        ccDrawColor4B(255.0f, 255.0f, 255.0f, 255.0f);
        
        CGPoint vertices[] = {
            [_bl position],
            [_tl position],
            [_tr position],
            [_br position]
        };
        
        ccDrawPoly(vertices, 4, YES);
    }
    
    [super draw];
}

- (void)updateForSelection:(CCNode *)node
{
    if (_trackingAreas == nil)
        _trackingAreas = [[NSMutableArray arrayWithCapacity:9] retain];
    
    NSView *view = [[CCDirector sharedDirector] view];
    if ([_trackingAreas count] > 0)
    {
        for (NSTrackingArea *area in _trackingAreas)
            [view removeTrackingArea:area];
        
        [_trackingAreas removeAllObjects];
    }
    
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
        
        // add tracking areas
        NSTrackingArea *tlArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_tl boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kTopLeftTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *tmArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_tm boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kTopMiddleTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *trArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_tr boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kTopRightTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *blArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_bl boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kBottomLeftTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *bmArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_bm boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kBottomMiddleTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *brArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_br boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kBottomRightTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *lmArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_lm boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kLeftMiddleTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *rmArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_rm boundingBox], -2.0f, -2.0f)
                                                               options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                 owner:view
                                                              userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kRightMiddleTag] forKey:@"tag"]] autorelease];
        NSTrackingArea *rotateArea = [[[NSTrackingArea alloc] initWithRect:CGRectInset([_rotate boundingBox], -2.0f, -2.0f)
                                                                   options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder)
                                                                     owner:view
                                                                  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:kRotateTag] forKey:@"tag"]] autorelease];
        [view addTrackingArea:tlArea]; [_trackingAreas addObject:tlArea];
        [view addTrackingArea:tmArea]; [_trackingAreas addObject:tmArea];
        [view addTrackingArea:trArea]; [_trackingAreas addObject:trArea];
        [view addTrackingArea:blArea]; [_trackingAreas addObject:blArea];
        [view addTrackingArea:bmArea]; [_trackingAreas addObject:bmArea];
        [view addTrackingArea:brArea]; [_trackingAreas addObject:brArea];
        [view addTrackingArea:lmArea]; [_trackingAreas addObject:lmArea];
        [view addTrackingArea:rmArea]; [_trackingAreas addObject:rmArea];
        [view addTrackingArea:rotateArea]; [_trackingAreas addObject:rotateArea];
    }
    
    self.isMouseEnabled = (node != nil);
}

- (BOOL)ccMouseDown:(NSEvent *)event
{
    CCNode *node = nil;
    for (CCNode *child in [[[self children] getNSArray] reverseObjectEnumerator])
    {
        if ( [child isEventInRect:event insetX:-2.0f insetY:-2.0f] )
        {
            node = child;
            break;
        }
    }
    
    if (!node)
        return NO;
    else
        _currentTag = [node tag];
    
    [self updateCursor];
    
    _isDragging = YES;
    
    [[[[CCDirector sharedDirector] view] window] disableCursorRects];
    
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    CCNode *selectedNode = [(SDDrawingView *)[self parent] selectedNode];
    _initialPosition = [selectedNode position];
    _initialScaleX = [selectedNode scaleX];
    _initialScaleY = [selectedNode scaleY];
    
    [[[[SDDocumentController sharedDocumentController] currentDocument] undoManager] beginUndoGrouping];
    
    return YES;
}

- (BOOL)ccMouseDragged:(NSEvent *)event
{
#define kMinimumDistance 2.0f
    
    if (_currentTag == kNoneTag || !_isDragging)
        return NO;
    
    NSAssert([[self parent] isKindOfClass:[SDDrawingView class]], @"SDSelectionView should be child of SDDrawingView");
    CCNode *selectedNode = [(SDDrawingView *)[self parent] selectedNode];
    CGSize s = [selectedNode contentSize];
    CGPoint anchor = [selectedNode anchorPoint];
    CGPoint newPos = _initialPosition;
    CGPoint pos = [[CCDirector sharedDirector] convertEventToGL:event];
    
    if (_currentTag == kRotateTag)
    {
        
    }
    
    if (_currentTag == kRightMiddleTag || _currentTag == kTopRightTag || _currentTag == kBottomRightTag)
    {
        CGFloat newWidth = pos.x - [selectedNode convertToWorldSpace:ccp(0,0)].x;
        [selectedNode setScaleX:newWidth / s.width];
        
        newPos.x += (newWidth - s.width * _initialScaleX) * anchor.x;
    }
    
    if (_currentTag == kLeftMiddleTag || _currentTag == kTopLeftTag || _currentTag == kBottomLeftTag)
    {
        CGFloat newWidth = [selectedNode convertToWorldSpace:ccp(s.width,0)].x - pos.x;
        [selectedNode setScaleX:newWidth / s.width];
        
        newPos.x -= (newWidth - s.width * _initialScaleX) * (1 - anchor.x);
    }
    
    if (_currentTag == kTopMiddleTag || _currentTag == kTopLeftTag || _currentTag == kTopRightTag)
    {
        CGFloat newHeight = pos.y - [selectedNode convertToWorldSpace:ccp(0,0)].y;
        [selectedNode setScaleY:newHeight / s.height];
        
        newPos.y += (newHeight - s.height * _initialScaleY) * anchor.y;
    }
    
    if (_currentTag == kBottomMiddleTag || _currentTag == kBottomLeftTag || _currentTag == kBottomRightTag)
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
    if (!_isDragging)
        return NO;
    
    [[[[SDDocumentController sharedDocumentController] currentDocument] undoManager] endUndoGrouping];
    
    _isDragging = NO;
    
    // reenable cursor rects
    [[[[CCDirector sharedDirector] view] window] enableCursorRects];
    [[[[CCDirector sharedDirector] view] window] resetCursorRects];
    
    // 1: send mouse exited in case it was missed while dragging
    [self ccMouseExited:nil];
    
    // 2: make sure that we aren't still over a handle
    CCNode *node = nil;
    for (CCNode *child in [[[self children] getNSArray] reverseObjectEnumerator])
    {
        if ( [child isEventInRect:event insetX:-2.0f insetY:-2.0f] )
        {
            node = child;
            break;
        }
    }
    
    if (!node)
        _currentTag = kNoneTag;
    else
        _currentTag = [node tag];
    
    // 3: update cursor based on findings from 2
    [self updateCursor];
    
    return YES;
}

- (void)ccMouseEntered:(NSEvent *)theEvent
{
    NSAssert([theEvent userData] != NULL, @"user data not set");
    NSNumber *tag = [(NSDictionary *)[theEvent userData] objectForKey:@"tag"];
    NSAssert(tag, @"tag not set");
    
    _currentTag = [tag integerValue];
    [self updateCursor];
}

- (void)ccMouseExited:(NSEvent *)theEvent
{
    if (!_isDragging)
    {
        _currentTag = kNoneTag;
        [NSCursor pop];
    }
}

- (void)updateCursor
{
    switch (_currentTag)
    {
        case kTopLeftTag:
        case kBottomRightTag:
            if ([NSCursor currentCursor] != _rotatedCounterclockwiseCursor)
                [_rotatedCounterclockwiseCursor push];
            break;
        case kTopMiddleTag:
        case kBottomMiddleTag:
            if ([NSCursor currentCursor] != [NSCursor resizeUpDownCursor])
                [[NSCursor resizeUpDownCursor] push];
            break;
        case kTopRightTag:
        case kBottomLeftTag:
            if ([NSCursor currentCursor] != _rotatedClockwiseCursor)
                [_rotatedClockwiseCursor push];
            break;
        case kLeftMiddleTag:
        case kRightMiddleTag:
            if ([NSCursor currentCursor] != [NSCursor resizeLeftRightCursor])
                [[NSCursor resizeLeftRightCursor] push];
            break;
        case kRotateTag:
            break;
        default:
            _currentTag = kNoneTag;
            break;
    }
}

@end
