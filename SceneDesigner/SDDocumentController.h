//
//  SDDocumentController.h
//  SceneDesigner
//

#import <AppKit/AppKit.h>

@interface SDDocumentController : NSDocumentController
{
    NSURL *_url;
    BOOL _displayDocument;
    void (^_completionHandler)(NSDocument *, BOOL, NSError *);
}

@end
