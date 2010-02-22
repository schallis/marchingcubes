//
//  Object.h
//  BasicOpenGL2
//
//  Created by Steve Challis on 07/02/2010.
//  Copyright 2010 Steve Challis. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Dataset.h"

@interface Object : NSObject {
    Dataset *dataset;
}

@property (copy) Dataset *dataset;

- (void)recalculate; // recalculate triangles
- (void)render; // draw triangles

@end
