//
//  Vec3.m
//  Marching Cubes
//
//  Created by Steve Challis on 22/02/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import "Vec3.h"

@implementation Vec3

@synthesize x, y, z;

- (NSString *)description {
    return [NSString stringWithFormat:@"<Vec3: (%.1f, %.1f, %.1f)>", x, y, z];
}

- (id)initiWithX:(float)newX Y:(float)newY Z:(float)newZ {
    x = newX;
    y = newY;
    z = newZ;
    return self;
}

- (Vec3 *)add:(Vec3 *)v2 {
    x += [v2 x];
    y += [v2 y];
    z += [v2 z];
    return self;
}

- (Vec3 *)c_add:(Vec3 *)v2 {
    Vec3 *new = [[Vec3 alloc] initiWithX:x+[v2 x]
                                       Y:y+[v2 y]
                                       Z:z+[v2 z]];
    return new;
}

- (Vec3 *)subtract:(Vec3 *)v2 {
    x -= [v2 x];
    y -= [v2 y];
    z -= [v2 z];
    return self;
}

- (Vec3 *)c_subtract:(Vec3 *)v2 {
    Vec3 *new = [[Vec3 alloc] initiWithX:x-[v2 x]
                                       Y:y-[v2 y]
                                       Z:z-[v2 z]];
    return new;
}

- (Vec3 *)product:(float)t {
    x *= t;
    y *= t;
    z *= t;
    return self;
}

- (Vec3 *)c_product:(float)t {
    Vec3 *new = [[Vec3 alloc] initiWithX:x*t
                                       Y:y*t
                                       Z:z*t];
    return new;
}

@end
