//
//  SDNode.h
//  SceneDesigner
//

#import "cocos2d.h"

@protocol SDNodeProtocol <NSObject>

@required

- (void)setMutableZOrder:(NSInteger)z;
- (NSDictionary *)dictionaryRepresentation;
+ (id)setupFromDictionaryRepresentation:(NSDictionary *)dict;
- (void)forceRedraw;

@optional

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, readonly) NSInteger mutableZOrder;
@property (nonatomic, readwrite) CGFloat posX;
@property (nonatomic, readwrite) CGFloat posY;
@property (nonatomic, readwrite) CGFloat anchorX;
@property (nonatomic, readwrite) CGFloat anchorY;
@property (nonatomic, readwrite) CGFloat contentWidth;
@property (nonatomic, readwrite) CGFloat contentHeight;

- (NSDictionary *)_dictionaryRepresentation;
+ (id)_setupFromDictionaryRepresentation:(NSDictionary *)dict;

@end

#define SDNODE_IVARS \
NSString *_name;\
BOOL _isSelected;

#define SDNODE_FUNC_SRC \
@synthesize name = _name;\
@synthesize isSelected = _isSelected;\
@dynamic mutableZOrder;\
@dynamic posX;\
@dynamic posY;\
@dynamic anchorX;\
@dynamic anchorY;\
@dynamic contentWidth;\
@dynamic contentHeight;\
\
- (void)setPosition:(CGPoint)pos\
{\
    if (!CGPointEqualToPoint([self position], pos))\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setPosition:[self position]];\
        [um setActionName:NSLocalizedString(@"repositioning", nil)];\
\
        [self willChangeValueForKey:@"posX"];\
        [self willChangeValueForKey:@"posY"];\
        [super setPosition:pos];\
        [self didChangeValueForKey:@"posX"];\
        [self didChangeValueForKey:@"posY"];\
    }\
}\
- (void)setAnchorPoint:(CGPoint)anchorPoint\
{\
    if (!CGPointEqualToPoint([self anchorPoint], anchorPoint))\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setAnchorPoint:[self anchorPoint]];\
        [um setActionName:NSLocalizedString(@"anchor point adjustment", nil)];\
\
        [self willChangeValueForKey:@"anchorX"];\
        [self willChangeValueForKey:@"anchorY"];\
        [super setAnchorPoint:anchorPoint];\
        [self didChangeValueForKey:@"anchorX"];\
        [self didChangeValueForKey:@"anchorY"];\
    }\
}\
\
- (void)setContentSize:(CGSize)size\
{\
    /* don't bother with undo for this,\
      only do undo for setContentWidth: or setContentHeight: */\
    if (!CGSizeEqualToSize([self contentSize], size))\
    {\
        [self willChangeValueForKey:@"contentWidth"];\
        [self willChangeValueForKey:@"contentHeight"];\
        [super setContentSize:size];\
        [self didChangeValueForKey:@"contentWidth"];\
        [self didChangeValueForKey:@"contentHeight"];\
    }\
}\
\
- (void)setScaleX:(float)sx\
{\
    if ([self scaleX] != sx)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setScaleX:[self scaleX]];\
        [um setActionName:NSLocalizedString(@"resizing", nil)];\
        [super setScaleX:sx];\
    }\
}\
\
- (void)setScaleY:(float)sy\
{\
    if ([self scaleY] != sy)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setScaleY:[self scaleY]];\
        [um setActionName:NSLocalizedString(@"resizing", nil)];\
        [super setScaleY:sy];\
    }\
}\
- (NSInteger)mutableZOrder\
{\
    return [self zOrder];\
}\
\
- (void)setMutableZOrder:(NSInteger)z\
{\
    if ([self zOrder] != z)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setMutableZOrder:[self zOrder]];\
        [um setActionName:NSLocalizedString(@"z order adjustment", nil)];\
        [[self parent] reorderChild:self z:z];\
    }\
}\
\
- (void)setRotation:(float)rotation\
{\
    if ([self rotation] != rotation)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setRotation:[self rotation]];\
        [um setActionName:NSLocalizedString(@"rotation", nil)];\
        [super setRotation:rotation];\
    }\
}\
\
- (void)setTag:(NSInteger)tag\
{\
    if ([self tag] != tag)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setTag:[self tag]];\
        [um setActionName:NSLocalizedString(@"tag adjustment", nil)];\
        [super setTag:tag];\
    }\
}\
\
- (void)setVisible:(BOOL)visible\
{\
    if ([self visible] != visible)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setVisible:[self visible]];\
        [um setActionName:NSLocalizedString(@"visibility adjustment", nil)];\
        [super setVisible:visible];\
    }\
}\
\
- (void)setIsRelativeAnchorPoint:(BOOL)relative\
{\
    if ([self isRelativeAnchorPoint] != relative)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setIsRelativeAnchorPoint:[self isRelativeAnchorPoint]];\
        [um setActionName:NSLocalizedString(@"relative anchor point adjustment", nil)];\
        [super setIsRelativeAnchorPoint:relative];\
    }\
}\
\
- (CGFloat)posX\
{\
    return self.position.x;\
}\
\
- (void)setPosX:(CGFloat)posX\
{\
    if (posX != self.position.x)\
    {\
        CGPoint pos = self.position;\
        pos.x = posX;\
        self.position = pos;\
    }\
}\
\
- (CGFloat)posY\
{\
    return self.position.y;\
}\
\
- (void)setPosY:(CGFloat)posY\
{\
    if (posY != self.position.y)\
    {\
        CGPoint pos = self.position;\
        pos.y = posY;\
        self.position = pos;\
    }\
}\
\
- (CGFloat)anchorX\
{\
    return self.anchorPoint.x;\
}\
\
- (void)setAnchorX:(CGFloat)anchorX\
{\
    if (anchorX != self.anchorPoint.x)\
    {\
        CGPoint anchor = self.anchorPoint;\
        anchor.x = anchorX;\
        self.anchorPoint = anchor;\
    }\
}\
\
- (CGFloat)anchorY\
{\
    return self.anchorPoint.y;\
}\
\
- (void)setAnchorY:(CGFloat)anchorY\
{\
    if (anchorY != self.position.y)\
    {\
        CGPoint anchor = self.anchorPoint;\
        anchor.y = anchorY;\
        self.anchorPoint = anchor;\
    }\
}\
\
- (CGFloat)contentWidth\
{\
    return self.contentSize.width;\
}\
\
- (void)setContentWidth:(CGFloat)contentWidth\
{\
    if (contentWidth != self.contentSize.width)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setContentWidth:self.contentSize.width];\
        [um setActionName:NSLocalizedString(@"content size adjustment", nil)];\
\
        CGSize size = self.contentSize;\
        size.width = contentWidth;\
        self.contentSize = size;\
    }\
}\
\
- (CGFloat)contentHeight\
{\
    return self.contentSize.height;\
}\
\
- (void)setContentHeight:(CGFloat)contentHeight\
{\
    if (contentHeight != self.contentSize.height)\
    {\
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];\
        [[um prepareWithInvocationTarget:self] setContentHeight:self.contentSize.height];\
        [um setActionName:NSLocalizedString(@"content size adjustment", nil)];\
\
        CGSize size = self.contentSize;\
        size.height = contentHeight;\
        self.contentSize = size;\
    }\
}\
\
- (void)draw\
{\
    [super draw];\
\
    if (_isSelected)\
    {\
        CGSize s = contentSize_;\
        ccDrawColor4B(255.0f, 255.0f, 255.0f, 255.0f);\
        glLineWidth(1.0f);\
\
        CGPoint vertices[] = {\
            ccp(0, s.height),\
            ccp(s.width, s.height),\
            ccp(s.width, 0),\
            ccp(0, 0)\
        };\
\
        ccDrawPoly(vertices, 4, YES);\
    }\
}\
\
- (void)forceRedraw\
{\
    /* a little hackish, but for some reason the layer doesn't change the color until you change the size sometimes */\
    CGSize size = [self contentSize];\
    CGSize tempSize = size;\
    tempSize.width += 1;\
    [self setContentSize:tempSize];\
    [self setContentSize:size];\
}\
\
- (NSDictionary *)dictionaryRepresentation\
{\
    NSMutableDictionary *dict = nil;\
    if ([self respondsToSelector:@selector(_dictionaryRepresentation)])\
        dict = [[[self _dictionaryRepresentation] mutableCopy] autorelease];\
    else\
        dict = [NSMutableDictionary dictionaryWithCapacity:11];\
\
    [dict setValue:[self className] forKey:@"className"];\
    [dict setValue:self.name forKey:@"name"];\
    [dict setValue:NSStringFromPoint(NSPointFromCGPoint(self.position)) forKey:@"position"];\
    [dict setValue:NSStringFromPoint(NSPointFromCGPoint(self.anchorPoint)) forKey:@"anchorPoint"];\
    [dict setValue:[NSNumber numberWithFloat:self.scaleX] forKey:@"scaleX"];\
    [dict setValue:[NSNumber numberWithFloat:self.scaleY] forKey:@"scaleY"];\
    [dict setValue:NSStringFromSize(NSSizeFromCGSize(self.contentSize)) forKey:@"contentSize"];\
    [dict setValue:[NSNumber numberWithInteger:self.zOrder] forKey:@"zOrder"];\
    [dict setValue:[NSNumber numberWithFloat:self.rotation] forKey:@"rotation"];\
    [dict setValue:[NSNumber numberWithInteger:self.tag] forKey:@"tag"];\
    [dict setValue:[NSNumber numberWithBool:self.visible] forKey:@"visible"];\
    [dict setValue:[NSNumber numberWithBool:self.isRelativeAnchorPoint] forKey:@"isRelativeAnchorPoint"];\
\
    NSMutableArray *children = [NSMutableArray array];\
    if ([[self children] count] > 0)\
        for (CCNode<SDNodeProtocol> *child in [self children])\
            if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])\
                [children addObject:[child dictionaryRepresentation]];\
\
    [dict setValue:children forKey:@"children"];\
\
    return dict;\
}\
\
+ (id)setupFromDictionaryRepresentation:(NSDictionary *)dict\
{\
    CCNode<SDNodeProtocol> *retVal = nil;\
    if ([self respondsToSelector:@selector(_setupFromDictionaryRepresentation:)])\
    {\
        id object = [self _setupFromDictionaryRepresentation:dict];\
        if ([object isKindOfClass:[CCNode class]] && [object conformsToProtocol:@protocol(SDNodeProtocol)])\
            retVal = (CCNode<SDNodeProtocol> *)object;\
    }\
\
    if (retVal == nil)\
        retVal = [self node];\
\
    retVal.name = [dict valueForKey:@"name"];\
    retVal.position = NSPointToCGPoint(NSPointFromString([dict valueForKey:@"position"]));\
    retVal.anchorPoint = NSPointToCGPoint(NSPointFromString([dict valueForKey:@"anchorPoint"]));\
    retVal.scaleX = [[dict valueForKey:@"scaleX"] floatValue];\
    retVal.scaleY = [[dict valueForKey:@"scaleY"] floatValue];\
    retVal.contentSize = NSSizeToCGSize(NSSizeFromString([dict valueForKey:@"contentSize"]));\
    retVal.rotation = [[dict valueForKey:@"rotation"] floatValue];\
    retVal.tag = [[dict valueForKey:@"tag"] integerValue];\
    retVal.visible = [[dict valueForKey:@"visible"] boolValue];\
    retVal.isRelativeAnchorPoint = [[dict valueForKey:@"isRelativeAnchorPoint"] boolValue];\
    [retVal setMutableZOrder:[[dict valueForKey:@"zOrder"] integerValue]];\
\
    return retVal;\
}\
\
- (void)setValue:(id)value forUndefinedKey:(NSString *)key\
{\
    /* dont do anything */\
}\
- (id)valueForUndefinedKey:(NSString *)key\
{\
    return nil;\
}\

/**
 * This is the basic SDNode without any additional modifications
 */
@interface SDNode : CCNode <SDNodeProtocol>
{
    SDNODE_IVARS
}

@end
