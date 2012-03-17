//
//  SDWindowController.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>
#import "TLAnimatingOutlineView.h"

@class TLAnimatingOutlineView;
@class TLCollapsibleView;
@class CCNode;
@protocol SDNodeProtocol;

@interface SDWindowController : NSWindowController <NSSplitViewDelegate, TLAnimatingOutlineViewDelegate, NSWindowDelegate, NSOutlineViewDelegate>
{
    TLAnimatingOutlineView *_animatingOutlineView;
    
    IBOutlet NSOutlineView *_outlineView;
    
    IBOutlet NSSplitView *_splitView;
    IBOutlet NSScrollView *_scrollView;
    IBOutlet NSScrollView *_rightView;
    
    IBOutlet NSView *_generalProperties;
    IBOutlet NSView *_nodeProperties;
    IBOutlet NSView *_spriteProperties;
    IBOutlet NSView *_bmFontProperties;
    IBOutlet NSTextField *_fntPathField;
    IBOutlet NSView *_layerProperties;
    IBOutlet NSView *_layerColorProperties;
    
    IBOutlet NSObjectController *_objectController;
    
    BOOL _ignoreNewSelection;
}

- (void)reloadOutlineView;
- (IBAction)addNode:(id)sender;
- (IBAction)removeNode:(id)sender;
- (void)addNodeToLayer:(CCNode<SDNodeProtocol> *)node;
- (void)removeNodeFromLayer:(CCNode<SDNodeProtocol> *)node;
- (void)configureView:(TLCollapsibleView *)view;
- (IBAction)selectFntFile:(id)sender;
- (void)synchronizeOutlineViewWithSelection;

@end
