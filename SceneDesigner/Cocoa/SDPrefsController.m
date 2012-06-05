//
//  SDPrefsController.m
//  SceneDesigner
//

#import "SDPrefsController.h"
#import "NSView+Additions.h"

@implementation SDPrefsController

- (void)dealloc
{
    [_itemIdentifiers release];
    [_toolbarItems release];
    [_itemViews release];
    [super dealloc];
}

- (void)addItems
{
    NSView *generalView = [NSView viewFromNibNamed:@"GeneralPreferences" withOwner:self];
    NSView *shortcutView = [NSView viewFromNibNamed:@"ShortcutPreferences" withOwner:self];
    NSView *advancedView = [NSView viewFromNibNamed:@"AdvancedPreferences" withOwner:self];
    [self addItemWithView:generalView label:@"General" image:[NSImage imageNamed:NSImageNamePreferencesGeneral]];
    [self addItemWithView:shortcutView label:@"Shortcuts" image:[NSImage imageNamed:@"PTKeyboardIcon.tiff"]];
    [self addItemWithView:advancedView label:@"Advanced" image:[NSImage imageNamed:NSImageNameAdvanced]];
}

- (void)showWindow:(id)sender
{
    if (![self window])
    {
        self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 250)
                                                  styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                                    backing:NSBackingStoreBuffered
                                                      defer:YES];
        [self.window center];
        
        NSRect frame = self.window.frame;
        frame.origin.y += 150;
        [self.window setFrame:frame display:YES];
    }
    
    if ([[self window] toolbar] == nil)
    {
        [self addItems];
        
        NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"SDToolbar"] autorelease];
        [toolbar setDelegate:self];
        [toolbar setAllowsUserCustomization:NO];
        [toolbar setAutosavesConfiguration:NO];
        [toolbar setSizeMode:NSToolbarSizeModeDefault];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
        [[self window] setToolbar:toolbar];
        
        if ([_toolbarItems count] > 0)
        {
            NSToolbarItem *firstItem = [_toolbarItems objectAtIndex:0];
            [toolbar setSelectedItemIdentifier:[firstItem itemIdentifier]];
            
            [self itemSelected:firstItem];
        }
    }
    
    [super showWindow:sender];
}

- (void)addItemWithView:(NSView *)view label:(NSString *)label image:(NSImage *)image
{
    if (!_itemIdentifiers)
        _itemIdentifiers = [[NSMutableArray alloc] init];
    if (!_toolbarItems)
        _toolbarItems = [[NSMutableArray alloc] init];
    if (!_itemViews)
        _itemViews = [[NSMutableDictionary alloc] init];
    
    if ([_itemViews objectForKey:label] != nil)
    {
        NSLog(@"<%@> - warning: cannot add two items with same label", [self className]);
        return;
    }
    
    if (view == nil)
    {
        NSLog(@"<%@> - warning: cannot add item with no view", [self className]);
        return;
    }
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:label];
    item.label = label;
    item.paletteLabel = label;
    item.image = image;
    item.target = self;
    item.action = @selector(itemSelected:);
    
    [_itemIdentifiers addObject:label];
    [_toolbarItems addObject:item];
    [_itemViews setObject:view forKey:label];
    
    [item release];
}

- (void)itemSelected:(NSToolbarItem *)sender
{    
    if (![_toolbarItems containsObject:sender])
        return;
    
    NSView *view = [_itemViews objectForKey:[sender itemIdentifier]];
    if (!view)
        return;
    
    NSWindow *window = self.window;
    
    // find the old view (if there is one)
    NSView *oldView = nil;
    if ([[window.contentView subviews] count] > 0)
    {
        for (NSView *subview in [[[window contentView] subviews] reverseObjectEnumerator])
        {
            if ([subview isKindOfClass:[NSView class]])
            {
                oldView = subview;
                break;
            }
        }
        
        if ([view isEqualTo:oldView])
            return;
    }
        
    //  calculate new window frame
    NSRect windowFrame = [window frame];
    NSRect contentFrame = [window contentRectForFrameRect:windowFrame];
    CGFloat titleBarHeight = NSHeight(windowFrame) - NSHeight(contentFrame);
    CGFloat heightDiff = (oldView != nil) ? NSHeight([oldView frame]) - NSHeight([view frame]) : 0;
    
    NSRect newFrame = [view frame];
    newFrame.size.height += titleBarHeight;
    newFrame.origin.x = windowFrame.origin.x;
    newFrame.origin.y = windowFrame.origin.y + heightDiff;
    
    [[window contentView] setSubviews:[NSArray array]]; // remove old view
    [window setFrame:newFrame display:YES animate:YES]; // resize window
    [[window contentView] addSubview:view];             // set new view
    
    // put frame at 0,0
    [view setFrameOrigin:NSMakePoint(0, 0)];
    
    // adjust window name
    [[self window] setTitle:[sender label]];
}

#pragma mark Toolbar Delegate

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    for (NSToolbarItem *item in _toolbarItems)
        if ([item isKindOfClass:[NSToolbarItem class]] && [[item itemIdentifier] isEqualToString:itemIdentifier])
            return item;
    
    return nil;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    return _itemIdentifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
    return [self toolbarAllowedItemIdentifiers:toolbar];
}

@end
