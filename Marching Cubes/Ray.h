//
//  Ray.h
//  Marching Cubes
//
//  Created by Steve Challis on 22/02/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Ray : NSObject {
    Vec3 *origin;
    Vec3 *direction;
}

@property (assign, readwrite) Vec3 *origin;
@property (assign, readwrite) Vec3 *direction;

- (id)initWithOrigin:(Vec3 *)newOrigin direction:(Vec3 *)newDirection;
- (Vec3 *)pointAtParamater:(float)t;

@end
