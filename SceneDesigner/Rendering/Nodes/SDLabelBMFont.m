//
//  SDLabelBMFont.m
//  SceneDesigner
//

#import "SDLabelBMFont.h"
#import "ColorFunctions.h"

@implementation SDLabelBMFont

- (id)initWithString:(NSString*)theString fntFile:(NSString*)fntFile width:(float)width alignment:(CCTextAlignment)alignment
{
    self = [super initWithString:theString fntFile:fntFile width:width alignment:alignment];
    return self;
}

- (void)setOpacity:(GLubyte)opacity
{
    if ([self opacity] != opacity)
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [(CCLabelBMFont *)[um prepareWithInvocationTarget:self] setOpacity:[self opacity]];
        [um setActionName:NSLocalizedString(@"opacity adjustment", nil)];
        [super setOpacity:opacity];
    }
}

- (void)setString:(NSString *)label
{
    if (![label isEqualToString:[self string]])
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [[um prepareWithInvocationTarget:self] setString:[self string]];
        [um setActionName:NSLocalizedString(@"label string adjustment", nil)];
        [super setString:label];
    }
}

- (void)setFntFile:(NSString *)fntFile
{
    if (![[self fntFile] isEqualToString:fntFile])
    {
        NSUndoManager *um = [[[NSDocumentController sharedDocumentController] currentDocument] undoManager];
        [[um prepareWithInvocationTarget:self] setFntFile:[self fntFile]];
        [um setActionName:NSLocalizedString(@"label font adjustment", nil)];
        [super setFntFile:fntFile];
    }
}

- (NSDictionary *)_dictionaryRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
    
    [dict setValue:[self fntFile] forKey:@"fntFile"];
    [dict setValue:[self string] forKey:@"string"];
    [dict setValue:[NSNumber numberWithUnsignedChar:self.opacity] forKey:@"opacity"];
    [dict setValue:NSStringFromColor(self.color) forKey:@"color"];
    
    return [dict autorelease];
}

+ (id)_setupFromDictionaryRepresentation:(NSDictionary *)dict
{
    CCLabelBMFont *retVal = [self labelWithString:[dict valueForKey:@"string"] fntFile:[dict valueForKey:@"fntFile"]];
    retVal.opacity = [[dict valueForKey:@"opacity"] unsignedCharValue];
    retVal.color = ColorFromNSString([dict valueForKey:@"color"]);
    return retVal;
}

SDNODE_FUNC_SRC

@end
