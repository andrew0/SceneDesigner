//
//  SDPrefsController.h
//  SceneDesigner
//

#import <Cocoa/Cocoa.h>

@interface SDPrefsController : NSWindowController <NSToolbarDelegate>
{
    NSMutableArray *_itemIdentifiers;
    NSMutableArray *_toolbarItems;
    NSMutableDictionary *_itemViews;
}

- (void)addItems;
- (void)addItemWithView:(NSView *)view label:(NSString *)label image:(NSImage *)image;
- (void)itemSelected:(NSToolbarItem *)sender;

@end
