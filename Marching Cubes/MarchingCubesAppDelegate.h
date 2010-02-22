//
//  MarchingCubesAppDelegate.h
//  MarchingCubes
//
//  Created by Steve Challis on 04/12/2009.
//  Copyright 2009 Steve Challis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MarchingCubesAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;

    NSArray *waveList;
    NSArray *surfaceList;
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSArrayController *surfaceController;
}

@property (assign) IBOutlet NSWindow *window;

@end
