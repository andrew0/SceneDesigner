//
//  SDDocumentController.m
//  SceneDesigner
//

#import "SDDocumentController.h"

@implementation SDDocumentController

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *, BOOL, NSError *))completionHandler
{
    _url = [url copy];
    _displayDocument = displayDocument;
    _completionHandler = [completionHandler copy];
    
    [self closeAllDocumentsWithDelegate:self didCloseAllSelector:@selector(openDocument) contextInfo:NULL];
}

- (void)openDocument
{
    if ( [[self documents] count] == 0 && _url != nil && _completionHandler != nil)
        [super openDocumentWithContentsOfURL:_url display:_displayDocument completionHandler:_completionHandler];
    
    [_url release];
    _url = nil;
    [_completionHandler release];
    _completionHandler = nil;
}

- (void)newDocument:(id)sender
{
    // when there is a new document message, try to close all of the documents open right now
    // then, in superDocument, it will make sure that the document was closed (e.g. they didn't press
    // cancel). if it's closed, it calls the super newDocument:
    [self closeAllDocumentsWithDelegate:self didCloseAllSelector:@selector(newDocument) contextInfo:NULL];
}

- (void)newDocument
{
    // only allow 1 document to be open
    if ( [[self documents] count] == 0 )
        [super newDocument:nil];
}

@end
