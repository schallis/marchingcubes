//
//  Ray.m
//  Marching Cubes
//
//  Created by Steve Challis on 22/02/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import "Ray.h"


@implementation Ray

@synthesize origin, direction;

- (NSString *)description {
    return [NSString stringWithFormat:@"<Ray: o(%.2f, %.2f, %.2f) d(%.2f, %.2f, %.2f)>",
            origin.x, origin.y, origin.z, direction.x, direction.y, direction.z];
}

- (id)initWithOrigin:(Vec3 *)newOrigin direction:(Vec3 *)newDirection {
    [super init];
    origin = newOrigin;
    direction = newDirection;
    return self;
}

- (Vec3 *)pointAtParamater:(float)t {
    Vec3 *new = [[Vec3 alloc] initiWithX:[direction x]*t+[origin x]
                                       Y:[direction y]*t+[origin y]
                                       Z:[direction z]*t+[origin z]];
    //NSLog(@"%f * %f + %@ = %f", [direction z], t, origin, [new z]);
    return new;
}

@end
