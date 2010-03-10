//
//  MarchingCubesAppDelegate.m
//  MarchingCubes
//
//  Created by Steve Challis on 04/12/2009.
//  Copyright 2009 All rights reserved.
//

#import "MarchingCubesAppDelegate.h"

@implementation MarchingCubesAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    waveList = [[NSArray alloc] initWithObjects:
                [NSDictionary dictionaryWithObjectsAndKeys:@"Test", @"name", @"test.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Circle", @"name", @"circle.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Peak", @"name", @"peak.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Broken Test", @"name", @"broken-test.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Atom", @"name", @"atom9.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Dog", @"name", @"dog.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Hip", @"name", @"neghip.raw.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"5b", @"name", @"5b.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"29", @"name", @"29.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"2b", @"name", @"2b.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Caffeine", @"name", @"caffeine0.3.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Fuel", @"name", @"fuel.raw.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Head", @"name", @"3dheadHalfScaleSmooth.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Rat", @"name", @"ratQuarterScale.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Lobster", @"name", @"lobster.dat.raw.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Brain", @"name", @"uncbrainsmall.txt", @"value", nil],
                [NSDictionary dictionaryWithObjectsAndKeys:@"Engine", @"name", @"EngineQuarterScale.txt", @"value", nil],
                nil]; // don't forget the nil!
    
    surfaceList = [[NSArray alloc] initWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Solid", @"name", @"solid", @"value", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Lines", @"name", @"lines", @"value", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Illumination", @"name", @"illumination", @"value", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"None", @"name", @"none", @"value", nil],
                   nil]; // don't forget the nil!
    
    [arrayController setContent:waveList];
    [surfaceController setContent:surfaceList];
}

@end
