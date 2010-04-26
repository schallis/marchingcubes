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

+ (Vec3 *)withX:(float)newX Y:(float)newY Z:(float)newZ {
    return [[Vec3 alloc] initiWithX:newX Y:newY Z:newZ];
}

- (id)initiWithX:(float)newX Y:(float)newY Z:(float)newZ {
    x = newX;
    y = newY;
    z = newZ;
    return self;
}

- (Vec3 *)add:(Vec3 *)v2 {
    x += v2.x;
    y += v2.y;
    z += v2.z;
    return self;
}

- (void)normalize {
    double length=(double)sqrt(pow(x,2)+ 
                        pow(y,2)+
                        pow(z,2)
                        );
	
    for (int a=0; a<3; ++a)	//divides vector by its length to normalise
    {
		// Avoid division by 0
		if (length == 0.0)
			length = 1.0;
    }
        
    x /= length;
    y /= length;
    z /= length;
}

- (Vec3 *)c_add:(Vec3 *)v2 {
    Vec3 *new = [[Vec3 alloc] initiWithX:x+v2.x
                                       Y:y+v2.y
                                       Z:z+v2.z];
    return new;
}

- (Vec3 *)subtract:(Vec3 *)v2 {
    x -= v2.x;
    y -= v2.y;
    z -= v2.z;
    return self;
}

- (Vec3 *)c_subtract:(Vec3 *)v2 {
    Vec3 *new = [[Vec3 alloc] initiWithX:x-v2.x
                                       Y:y-v2.y
                                       Z:z-v2.z];
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

- (Vec3 *)c_divide:(float)t {
    Vec3 *new = [[Vec3 alloc] initiWithX:x/t
                                       Y:y/t
                                       Z:z/t];
    return new;
}

- (Vec3 *)c_floor {
    Vec3 *new = [[Vec3 alloc] initiWithX:floor(x)
                                       Y:floor(y)
                                       Z:floor(z)];
    return new;
}

- (float)dot:(Vec3 *)v2 {
    return x * v2.x + y * v2.y + z * v2.z;
}

- (float)chebyshev:(Vec3 *)v2 {
    float r1 = fabs(x-v2.x);
    float r2 = fabs(y-v2.y);
    float r3 = fabs(z-v2.z);
    
    float temp = (r2 > r3 ? r2 : r3);
    return r1 > temp ? r1 : temp;
}

@end
