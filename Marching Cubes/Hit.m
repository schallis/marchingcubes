//
//  Hit.m
//  Marching Cubes
//
//  Created by Steve Challis on 10/03/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import "Hit.h"


@implementation Hit

@synthesize location, rgb, normal, isovalue;

- (NSString *)description {
    return [NSString stringWithFormat:@"<Hit: l(%.1f, %.1f, %.1f) c(%.1f, %.1f, %.1f)>",
            location.x, location.y, location.z, rgb.x, rgb.y, rgb.z];
}

- (id)initWithLocation:(Vec3 *)newLocation rgb:(Vec3 *)newRgb normal:(Vec3 *)newNormal isovalue:(float)value {
    [super init];
    location = newLocation;
    rgb = newRgb;
    normal = newNormal;
    isovalue = value;
    return self;
}

@end
