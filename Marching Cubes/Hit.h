//
//  Hit.h
//  Marching Cubes
//
//  Created by Steve Challis on 10/03/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Hit : NSObject {
	Vec3 *location;
    Vec3 *rgb;
    Vec3 *normal;
    float isovalue;
}

@property (assign, readwrite) Vec3 *location;
@property (assign, readwrite) Vec3 *rgb;
@property (assign, readwrite) Vec3 *normal;
@property (assign, readwrite) float isovalue;

- (id)initWithLocation:(Vec3 *)newLocation rgb:(Vec3 *)newRgb normal:(Vec3 *)newNormal isovalue:(float)value;

@end
