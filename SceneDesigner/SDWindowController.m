//
//  SDWindowController.m
//  SceneDesigner
//

#import "SDWindowController.h"
#import "AppDelegate.h"
#import "SDClipView.h"
#import "TLCollapsibleView.h"
#import "TLDisclosureBar.h"
#import "NSView+Additions.h"
#import "SDDocument.h"
#import "SDDrawingView.h"
#import "SDNode.h"
#import "SDSprite.h"
#import "SDLabelBMFont.h"
#import "SDLayer.h"
#import "SDLayerColor.h"
#import "SDGLView.h"
#import "NSThread+Blocks.h"
#import "SDOutlineViewDataSource.h"

@implementation SDWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // register for notifications
    SDDocument *document = nil;
    if ([[self document] isKindOfClass:[SDDocument class]])
    {
        document = (SDDocument *)[self document];
        [document addObserver:self forKeyPath:@"drawingView.selectedNode" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
        [document addObserver:self forKeyPath:@"drawingView.selectedNode.mutableZOrder" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:NULL];
    }
    
    SceneDesignerAppDelegate *delegate = [NSApp delegate];
    SDGLView *glView = [delegate glView];
    
    SDClipView *clipView = [[SDClipView alloc] initWithFrame:[[_scrollView contentView] frame]];
    [clipView setBackgroundColor:[NSColor colorWithPatternImage:[NSImage imageNamed:@"linen.png"]]];
    [_scrollView setContentView:clipView];
    [_scrollView setDocumentView:glView];
    
    if ([[CCDirector sharedDirector] runningScene] == nil)
        [delegate startCocos2D];
    else
        [delegate resumeCocos2D];
    
    // center window
    [[self window] center];
    
    // split view
    [_splitView setDelegate:self];
    
    // add TLAnimatingOutlineView
    NSSize contentSize = [_rightView contentSize];
    _animatingOutlineView = [[TLAnimatingOutlineView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, contentSize.width, contentSize.height)];
    [_animatingOutlineView setDelegate:self];
    [_animatingOutlineView setAutoresizingMask:NSViewWidthSizable];
    [_rightView setDocumentView:_animatingOutlineView];
    
    // hierarchy outline view
    [_outlineView setDelegate:self];
    [self reloadOutlineView];
}

- (void)dealloc
{
    [_animatingOutlineView release];
    [super dealloc];
}

- (void)reloadOutlineView
{
    // must perform on main thread because it Cocoa objects (i.e. NSOutlineView) can only be modified on main thread
    // waitUntilDone because this is called right before synchronizeOutlineViewWithSelection, and if it hasn't finished yet
    // then the synchronization will fail
    [[NSThread mainThread] performBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NSOutlineViewWillReloadDataNotification" object:_outlineView];
        [_outlineView reloadData];
    } waitUntilDone:YES];
}

#pragma mark -
#pragma mark Add/Remove Nodes

- (IBAction)addNode:(id)sender
{
    if (![sender isKindOfClass:[NSMenuItem class]])
        return;
    
    NSMenuItem *item = (NSMenuItem *)sender;
    
    if ([[item title] isEqualToString:@"CCNode"])
    {
        SDNode *node = [SDNode node];
        CCNode *parent = [[[self document] drawingView] selectedNode];
        [self addNodeToLayer:node parent:parent];
    }
    else if ([[item title] isEqualToString:@"CCSprite"])
    {
        // initialize panel + set flags
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseFiles:YES];
        [openPanel setAllowsMultipleSelection:YES];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"png", @"gif", @"jpg", @"jpeg", @"tif", @"tiff", @"bmp", @"ccz", @"pvr", nil]];
        [openPanel setAllowsOtherFileTypes:NO];
        
        // handle the open panel
        [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            if (result == NSOKButton)
            {
                [[CCTextureCache sharedTextureCache] removeUnusedTextures];
                
                NSArray *urls = [openPanel URLs];
                
                CCNode *parent = [[[self document] drawingView] selectedNode];
                
                [[[self document] undoManager] beginUndoGrouping];
                for (NSURL *url in urls)
                {
                    NSString *path = [url path];
                    SDSprite *sprite = [SDSprite spriteWithFile:path];
                    [self addNodeToLayer:sprite parent:parent];
                }
                [[[self document] undoManager] endUndoGrouping];
            }
        }];
    }
    else if ([[item title] isEqualToString:@"CCLayer"])
    {
        SDLayer *layer = [SDLayer node];
        CCNode *parent = [[[self document] drawingView] selectedNode];
        [self addNodeToLayer:layer parent:parent];
    }
    else if ([[item title] isEqualToString:@"CCLayerColor"])
    {
        SDLayerColor *layer = [SDLayerColor layerWithColor:ccc4(0, 0, 0, 255)];
        CCNode *parent = [[[self document] drawingView] selectedNode];
        [self addNodeToLayer:layer parent:parent];
        [layer forceRedraw];
    }
}

- (IBAction)removeNode:(id)sender
{
    SDDrawingView *layer = [(SDDocument *)[self document] drawingView];
    CCNode<SDNodeProtocol> *node = [layer selectedNode];
    if (layer && node)
        [self removeNodeFromLayer:node parent:[node parent]];
}

- (void)addNodeToLayer:(CCNode<SDNodeProtocol> *)node parent:(CCNode *)parent
{
    if (!node)
        return;
    
    if ([node parent] != nil)
        return;
    
    if (parent == nil)
        parent = [[self document] drawingView];
    
    [[[[self document] undoManager] prepareWithInvocationTarget:self] removeNodeFromLayer:node parent:parent];
    [[[self document] undoManager] setActionName:NSLocalizedString(@"node addition", nil)];
    
    SDDrawingView *layer = [[self document] drawingView];
    CCCallBlock *action = [CCCallBlock actionWithBlock:^{
        [parent addChild:node];
        [layer setSelectedNode:node];
        [self reloadOutlineView];
    }];
    [layer runAction:action];
}

- (void)addNodeToLayer:(CCNode<SDNodeProtocol> *)node
{
    [self addNodeToLayer:node parent:nil];
}

- (void)removeNodeFromLayer:(CCNode<SDNodeProtocol> *)node parent:(CCNode *)parent
{
    if (!node)
        return;
    
    [[[[self document] undoManager] prepareWithInvocationTarget:self] addNodeToLayer:node parent:parent];
    [[[self document] undoManager] setActionName:NSLocalizedString(@"node addition", nil)];
    
    CCCallBlock *action = [CCCallBlock actionWithBlock:^{
        [[node parent] removeChild:node cleanup:YES];
        [self reloadOutlineView];
    }];
    [[node parent] runAction:action];
}

- (IBAction)selectFntFile:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"fnt"]];
    [openPanel setAllowsOtherFileTypes:NO];
    
    // block to handle open file sheet
    void (^handler)(NSInteger result) = ^(NSInteger result) {
        if(result == NSOKButton)
        {
            NSArray *files = [openPanel URLs];
            if ([files count] > 0)
            {
                NSURL *url = [files objectAtIndex:0];
                SDDocument *document = [self document];
                if ([document isKindOfClass:[SDDocument class]])
                {
                    SDLabelBMFont *node = (SDLabelBMFont *)[[document drawingView] selectedNode];
                    if ([node isKindOfClass:[SDLabelBMFont class]])
                        node.fntFile = [url path];
                }
            }
        }
    };
    
    [openPanel beginSheetModalForWindow:[self window] completionHandler:handler];
}

#pragma mark -
#pragma mark Window Stuff

- (void)windowWillClose:(NSNotification *)notification
{
    if ([[self document] isKindOfClass:[SDDocument class]])
    {
        [[self document] removeObserver:self forKeyPath:@"drawingView.selectedNode"];
        [[self document] removeObserver:self forKeyPath:@"drawingView.selectedNode.mutableZOrder"];
    }
    
    SceneDesignerAppDelegate *delegate = [NSApp delegate];
    [delegate pauseCocos2D];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return [NSString stringWithFormat:@"SceneDesigner - %@", displayName];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    // notify delegate that the current document has changed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentDocumentDidChangeNotification" object:[self document]];
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // make sure this is performed on main thread, since AppKit objects can only be modified on main thread,
    // and the selecting/deselecting of nodes modifies the animating outline view
    [[NSThread mainThread] performBlock:^{
        CCNode<SDNodeProtocol> *newNode = [[[self document] drawingView] selectedNode];
        if ([keyPath isEqualToString:@"drawingView.selectedNode"])
        {
            
            // we have to make a copy of subviews because removeItem:
            // mutates the subviews and you can't mutate an array
            // during enumeration
            NSArray *subviews = [[_animatingOutlineView subviews] copy];
            for (TLCollapsibleView *view in subviews)
                [_animatingOutlineView removeItem:view];
            [subviews release];
            
            // if there's a new node, set the appropriate view
            if (newNode && [newNode isKindOfClass:[CCNode class]] && [newNode conformsToProtocol:@protocol(SDNodeProtocol)])
            {
                // set the object controller selection to the new node
                [_objectController setContent:newNode];
                
                if ([newNode isKindOfClass:[CCNode class]])
                {
                    TLCollapsibleView *view = [_animatingOutlineView addView:_nodeProperties withImage:nil label:@"Node Properties" expanded:YES];
                    [self configureView:view];
                }
                
                if ([newNode isKindOfClass:[CCSprite class]])
                {
                    TLCollapsibleView *view = [_animatingOutlineView addView:_spriteProperties withImage:nil label:@"Sprite Properties" expanded:YES];
                    [self configureView:view];
                }
                
                if ([newNode isKindOfClass:[CCLabelBMFont class]])
                {
                    TLCollapsibleView *view = [_animatingOutlineView addView:_bmFontProperties withImage:nil label:@"Bitmap Font Properties" expanded:YES];
                    [self configureView:view];
                }
                
                if ([newNode isKindOfClass:[CCLayer class]])
                {
                    TLCollapsibleView *view = [_animatingOutlineView addView:_layerProperties withImage:nil label:@"Layer Properties" expanded:YES];
                    [self configureView:view];
                }
                
                if ([newNode isKindOfClass:[CCLayerColor class]])
                {
                    TLCollapsibleView *view = [_animatingOutlineView addView:_layerColorProperties withImage:nil label:@"Layer Color Properties" expanded:YES];
                    [self configureView:view];
                }
            }
            else
            {
                // if there's no new node, then set the content to be the drawing view and add the general project properties
                [_objectController setContent:[[self document] drawingView]];
                
                TLCollapsibleView *view = [_animatingOutlineView addView:_generalProperties withImage:nil label:@"General Properties" expanded:YES];
                [self configureView:view];
                view.disclosureBar.borderSidesMask = TLMinYEdge;
            }
            
            if (!_ignoreNewSelection)
                [self synchronizeOutlineViewWithSelection];
            _ignoreNewSelection = NO;
        }
        else if ([keyPath isEqualToString:@"drawingView.selectedNode.mutableZOrder"])
        {
            // change in z order = change in order for outline view, so outline view must be reloaded
            [self reloadOutlineView];
            [self synchronizeOutlineViewWithSelection];
        }
    }];
}

- (void)configureView:(TLCollapsibleView *)view
{
    [view.disclosureBar setAutoresizesSubviews:NO];
    [view.disclosureBar.labelField setFrameOrigin:NSMakePoint(20.0f, [view.disclosureBar.labelField frame].origin.y)];
    view.disclosureBar.drawsHighlight = NO;
    view.disclosureBar.activeFillGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.86f alpha:255] endingColor:[NSColor colorWithCalibratedWhite:0.72f alpha:255]] autorelease];
    view.disclosureBar.inactiveFillGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.95f alpha:255] endingColor:[NSColor colorWithCalibratedWhite:0.85f alpha:255]] autorelease];
    view.disclosureBar.clickedFillGradient = [[[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:0.78f alpha:255] endingColor:[NSColor colorWithCalibratedWhite:0.64f alpha:255]] autorelease];
    view.disclosureBar.borderColor = [NSColor colorWithCalibratedWhite:0.66f alpha:255.0f];
}


#pragma mark -
#pragma mark Animating Outline View Delegate

- (CGFloat)rowSeparation
{
    return 0.0f;
}

- (BOOL)outlineView:(TLAnimatingOutlineView *)outlineView shouldCollapseItem:(TLCollapsibleView *)item
{
    // only for TLAnimatingOutlineViews
    if (![outlineView isKindOfClass:[TLAnimatingOutlineView class]])
        return YES;
    
    // if the first responder is being collapsed, remove its focus
    // otherwise the focus ring will still show while the view is being collapsed
    NSResponder *firstResponder = [[self window] firstResponder];
    if ( [firstResponder isKindOfClass:[NSView class]])
    {
        for (NSView *sv = [(NSView *)firstResponder superview]; sv != nil; sv = [sv superview])
        {
            if (sv == [item detailView])
            {
                [[self window] makeFirstResponder:nil];
                break;
            }
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Split View Delegate

- (void)splitViewWillResizeSubviews:(NSNotification *)notification
{
    NSSplitView *splitView = [notification object];
    if ( ![splitView isKindOfClass:[NSSplitView class]] )
        return;
    
    // don't update screen until flush to avoid flickering
    NSWindow *window = [splitView window];
    [window disableScreenUpdatesUntilFlush];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    if (![[splitView subviews] containsObject:view])
        return NO;
    
    NSUInteger index = [[splitView subviews] indexOfObject:view];
    switch (index)
    {
        case 0:
        case 2:
            return NO;
        case 1:
            return YES;
        default:
            break;
    }
    
    return YES;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0)
        return 250.0f;
    
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 1)
        return NSWidth([splitView frame]) - 250.0f - [splitView dividerThickness];
    
    return proposedMax;
}

#pragma mark -
#pragma mark Outline View Delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    // ignore the new selection because it will cause an infinite loop, since
    // it will call outlineViewSelectionDidChange: again, then which changes the
    // selection, which will call outlineViewDidChange: again, etc.
    _ignoreNewSelection = YES;
    
    NSDictionary *dict = [_outlineView itemAtRow:[_outlineView selectedRow]];
    CCNode<SDNodeProtocol> *node = ([dict isKindOfClass:[NSDictionary class]]) ? [dict objectForKey:NODE_KEY] : nil;
    [[[self document] drawingView] setSelectedNode:node];
}

- (void)synchronizeOutlineViewWithSelection
{
    BOOL foundRow = NO;
    NSUInteger row = 0;
    CCNode<SDNodeProtocol> *selectedNode = [[[self document] drawingView] selectedNode];
    
    // try to find selected node's corresponding outline view item and select it
    // if it doesn't find anything, deselect everything
    if (selectedNode != nil)
    {
        for (NSUInteger i = 0; i < [_outlineView numberOfRows]; i++)
        {
            NSDictionary *dict = [_outlineView itemAtRow:i];
            if ([dict isKindOfClass:[NSDictionary class]])
            {
                CCNode<SDNodeProtocol> *node = [dict objectForKey:NODE_KEY];
                if (node == selectedNode)
                {
                    foundRow = YES;
                    row = i;
                }
            }
        }
    }
    
    if (foundRow)
        [_outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    else
        [_outlineView deselectAll:nil];
}

@end
