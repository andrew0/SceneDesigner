//
//  SDOutlineView.m
//  SceneDesigner
//

#import "SDOutlineView.h"
#import "SDOutlineViewDataSource.h"
#import "SDWindowController.h"

@implementation SDOutlineView

- (void)keyDown:(NSEvent *)theEvent
{
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
        NSDictionary *dict = [self itemAtRow:row];
        CCNode<SDNodeProtocol> *node = [dict objectForKey:NODE_KEY];
        if (node != nil)
        {
            SDWindowController *wc = [[self window] windowController];
            if ([wc isKindOfClass:[SDWindowController class]])
            {
                [wc removeNodeFromLayer:node parent:[node parent]];
            }
        }
    }
}

@end
