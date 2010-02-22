//
//  Dataset.h
//  Marching Cubes
//
//  Created by Steve Challis on 25/01/2010.
//  Copyright 2010 All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
- (void)recalculateWithIsovalue:(float)isovalue; // recalculate triangles
- (void)computeVertexNormals;
- (void)renderWithSmoothing:(BOOL)smoothing; // draw triangles
- (void)renderNormalsAtScale:(float)scale withSmoothing:(BOOL)smoothing;
- (void)renderVertices;
- (int)addTriangle:(Triangle)item;

@end
