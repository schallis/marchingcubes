//
//  Vec3.h
//  Marching Cubes
//
//  Created by Steve Challis on 22/02/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Vec3 : NSObject {
    float x;
    float y;
    float z;
}

@property (readwrite) float x;
@property (readwrite) float y;
@property (readwrite) float z;

- (id)initiWithX:(float)newX Y:(float)newY Z:(float)newZ;

// modify operators
- (Vec3 *)add:(Vec3 *)v2;
- (Vec3 *)subtract:(Vec3 *)v2;
- (Vec3 *)product:(float)t;

// copy operators
- (Vec3 *)c_add:(Vec3 *)v2;
- (Vec3 *)c_subtract:(Vec3 *)v2;
- (Vec3 *)c_product:(float)t;

@end
