//
//  AppDelegate.m
//  ToqImageGenerator
//
//  Created by Khaos Tian on 3/11/14.
//  Copyright (c) 2014 Khaos Tian. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
{
    
}

@property (weak) IBOutlet NSImageView *imageWell;

- (IBAction)didGetNewImage:(id)sender;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (IBAction)didGetNewImage:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *processedData = [self processImage:[_imageWell image]];
        if (!processedData) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSSavePanel *panel = [NSSavePanel savePanel];
            [panel setAllowedFileTypes:@[@"img"]];
            [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
                if (result == NSFileHandlingPanelOKButton) {
                    [processedData writeToURL:[panel URL] atomically:YES];
                }
            }];
        });
    });
}

- (NSData *)processImage:(NSImage *)image
{
    NSSize imageSize = image.size;
    
    int width = imageSize.width;
    int height = imageSize.height;
    
    if (width > 288 || height > 192) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *a = [NSAlert alertWithMessageText:@"Image Size too big" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"The image you used is too big for Qualcomm Toq."];
            [a runModal];
        });
        return nil;
    }
    
    NSInteger dataSize = (imageSize.width * imageSize.height)+16;
    
    char *data = (char *)malloc(dataSize*sizeof(char));
    
    data[0] = 0x4D;
    data[1] = 0x53;
    data[2] = 0x4F;
    data[3] = 0x4C;
    data[4] = 0x20;
    data[5] = 0x20;
    
    //A Flag for alpha?
    data[6] = 0x00;
    
    data[7] = 0x08;
    data[8] = (width & 0xFF);
    data[9] = (width >> 8);
    data[10] = (height & 0xFF);
    data[11] = (height >> 8);
    for (int i = 12; i<16; i++) {
        data[i] = 0x00;
    }
    
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
    
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            NSColor *color = [bitmapImageRep colorAtX:x y:y];
            
            int red = (int)(color.redComponent * 255) >> 6;
            int green = (int)(color.greenComponent * 255) >> 6;
            int blue = (int)(color.blueComponent * 255) >> 6;
            //NSLog(@"%#08x,%#08x,%#08x",red,green,blue);
            
            data[16+width*y+x] = (3 + ((red << 6)+(green << 4)+(blue << 2)));
        }
    }
    
    NSData *finalData = [NSData dataWithBytes:data length:dataSize];
    
    free(data);
    
    return finalData;
}

@end