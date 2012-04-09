//
//  SDOutlineView.m
//  SceneDesigner
//

#import "SDOutlineView.h"
#import "SDOutlineViewDataSource.h"
#import "SDWindowController.h"
#import "CCNode+Additions.h"

NSString *NSOutlineViewWillReloadDataNotification = @"NSOutlineViewWillReloadDataNotification";
NSString *NSOutlineViewDidReloadDataNotification = @"NSOutlineViewDidReloadDataNotification";

@implementation SDOutlineView

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    
    if ([[self selectedRowIndexes] count] == 0)
        return;
    
    if ([[theEvent characters] length] == 0)
        return;
    
    unichar firstCharacter = [[theEvent characters] characterAtIndex:0];
    if (firstCharacter == NSDeleteFunctionKey ||
        firstCharacter == NSDeleteCharFunctionKey ||
        firstCharacter == NSDeleteCharacter ||
        firstCharacter == NSBackspaceCharacter)
    {
        NSInteger row = [self selectedRow];
        CCNode *node = [self itemAtRow:row];
        if (node != nil && [node isKindOfClass:[CCNode class]] && [node isSDNode])
        {
            SDWindowController *wc = [[self window] windowController];
            if ([wc isKindOfClass:[SDWindowController class]])
                [wc removeNodeFromLayer:node];
        }
    }
}

- (void)reloadData
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewWillReloadDataNotification object:self];
    [super reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSOutlineViewDidReloadDataNotification object:self];
}

@end
