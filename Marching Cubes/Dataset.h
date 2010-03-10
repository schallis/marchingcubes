//
//  Dataset.h
//  Marching Cubes
//
//  Created by Steve Challis on 25/01/2010.
//  Copyright 2010 All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "Ray.h"
#include "Hit.h"

#define LERP(a,l,h)	((l)+(((h)-(l))*(a)))

typedef struct {
	double points[3][2][3]; //tripoint, point/normal, xyz, 
    double normal[3];
} Triangle;

typedef struct {
	double point[3]; // xyz, 
    double faces[12]; // maximum of 12 incident faces
    int incident; // number of faces collected
} Vertex;

@interface Dataset : NSObject {
    NSString *rawData;
    NSArray *scalarData;
    NSArray *dimensions;    // x, y, z
    NSMutableArray *hits;
    Triangle *triangles;
    Vertex *vertices;
    int num_triangles;
    int num_allocated;
    int num_elements;
	float isovalue;
    float maxValue;
    float minValue;
    BOOL smoothedNormals;
}

@property (copy) NSString *rawData;
@property (copy) NSArray *scalarData;
@property (copy) NSArray *dimensions;
@property (readwrite) Triangle *triangles;
@property (readwrite) int num_triangles;
@property (readwrite) int num_allocated;
@property (readwrite) int num_elements;
@property (readwrite) float isovalue;
@property (readwrite) float minValue;
@property (readwrite) float maxValue;
@property (readwrite) BOOL smoothedNormals;

- (void)initWithContentsOfFile:(NSString *)path;
- (void)clearData;
- (void)computeIlluminationWithSamples:(int)samples;
- (float)isovalueFromUnitIsovalue:(float)value;
- (void)recalculateWithIsovalue:(float)isovalue; // recalculate triangles
- (void)computeVertexNormals;
- (void)renderWithSmoothing:(BOOL)smoothing cellShading:(BOOL)cell; // draw triangles
- (void)renderNormalsAtScale:(float)scale withSmoothing:(BOOL)smoothing;
- (void)renderVertices;
- (void)renderIllumination;
- (int)addTriangle:(Triangle)item;
- (Hit *)intersectRay:(Ray *)r withIsovalue:(float)val;
- (Hit *)intersectRay:(Ray *)r withVoxel:(Vec3 *)voxel isovalue:(float)val tin:(Vec3 *)tin tout:(Vec3 *)tout;

@end
