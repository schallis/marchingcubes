//
//  Dataset.m
//  Marching Cubes
//
//  Created by Steve Challis on 25/01/2010.
//  Copyright 2010 All rights reserved.
//

#import "Dataset.h"
#import "functions.h"
#import "mc_tables.h"
#include <stdlib.h>

@implementation Dataset

@synthesize scalarData, rawData, dimensions, triangles, num_triangles, num_allocated, num_elements, isovalue, minValue, maxValue, smoothedNormals;

-(id)init
{
    self = [super init];
    [self clearData];
    return self;
}

-(void)clearData {
    free(triangles);
    [self setTriangles:NULL];
    [self setNum_triangles:0];
    [self setNum_allocated:0];
    [self setNum_elements:0];
    [self setNum_elements:0];
}

- (void)initWithContentsOfFile:(NSString *)path {
    NSLog([@"Loading " stringByAppendingString:path]);
    [self clearData];
    NSError *error;
    // Read file
    self.rawData = [[[NSString alloc] initWithContentsOfFile:path
                                     encoding:NSUTF8StringEncoding
                                     error:&error] autorelease];

    // Setup scanner that skips spaces and newlines
    NSScanner *scanner = [NSScanner scannerWithString:[self rawData]];
    [scanner setCharactersToBeSkipped:
     [NSCharacterSet characterSetWithCharactersInString:@"\n\t\r "]];
    NSMutableArray *points = [NSMutableArray array];
    float density;
    
    // Extract scalar values from raw data
    int count = 0;
    while ( [scanner scanFloat:&density] ) {
        [points addObject: [NSNumber numberWithFloat:density]];
        if (count>3) {
            if (density > maxValue) { [self setMaxValue:density]; }
            if (density < minValue) { [self setMinValue:density]; }
        } else if (count>2) {
            [self setMaxValue:density];
            [self setMinValue:density];
        }
        count += 1;
    }
    
    // Assign first 3 points as the dimensions
    NSInteger split = 3;
    NSRange range = NSMakeRange(0, split);
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
    [self setDimensions:[points objectsAtIndexes:indexes]];
    
    // Assign remainder as data
    NSRange range2 = NSMakeRange(split, [points count]-split);
    NSIndexSet *indexes2 = [NSIndexSet indexSetWithIndexesInRange:range2];
    [self setScalarData:[points objectsAtIndexes:indexes2]];
    NSLog(@"Dimensions: %d %d %d", [[dimensions objectAtIndex:0] intValue], [[dimensions objectAtIndex:1] intValue], [[dimensions objectAtIndex:2] intValue]);
    NSLog(@"Datapoints: %d", [scalarData count]);
    [self setSmoothedNormals:FALSE];
}

- (void)recalculateWithIsovalue:(float)value {
    [self clearData];
    float normIso = value*(maxValue-minValue)+minValue;
    [self setIsovalue:normIso];
    int x = (int)[[dimensions objectAtIndex:0] intValue];
    int y = (int)[[dimensions objectAtIndex:1] intValue];
    int z = (int)[[dimensions objectAtIndex:2] intValue];
    // Loop over cells in dataset
    for (int i=0; i<x-1; i++) {
        for (int j=0; j<y-1; j++) {
            for (int k=0; k<z-1; k++) {
                // Get surrounding vertices indexes
                int is[8] = {
                    // Bits are in reverse order
                    k + j*z + i*z*y,            // 000  0
                    k + (j*z) + (i+1)*z*y,      // 001  1
                    k + (j+1)*z + i*z*y,        // 010  2
                    k + (j+1)*z + (i+1)*z*y,    // 011  3
                    (k+1) + (j*z) + i*z*y,      // 100  4
                    k+1 + (j*z) + (i+1)*z*y,    // 101  5
                    k+1 + (j+1)*z + i*z*y,      // 110  6
                    k+1 + (j+1)*z + (i+1)*z*y   // 111  7
                };
                double vs[8];
                for (int n=0; n<8; n++) {
                    vs[n] = [[[self scalarData] objectAtIndex:is[n]] doubleValue];
                }
                // Figure out which ones are above the threshold
                // Label values 1 or 0 depending on whether they are above isovalue
                int b_vs[8];
                for (int n=0; n<8; n++) {
                    b_vs[n] = vs[n] >= normIso;
                }
                // Get decimal value to lookup
                int lookup = b_vs[0] + (b_vs[1]*2) +
                (b_vs[2]*4) + (b_vs[3]*8) +
                (b_vs[4]*16) + (b_vs[5]*32) +
                (b_vs[6]*64) + (b_vs[7]*128);
                // Get triangles
                for (int t=0; t<triangleTable[lookup][0]; t++) {
                    // Edges
                    int edges[3] = {
                        triangleTable[lookup][(t*3)+1],
                        triangleTable[lookup][(t*3)+2],
                        triangleTable[lookup][(t*3)+3]
                    };
                    // Get edge points
                    int edgePoints[6];
                    for (int pairs=0; pairs<3; pairs++) {
                        for (int pair=0; pair<2; pair++) {
                            edgePoints[(pairs*2)+pair] = edgeTable[edges[pairs]][pair];
                        }
                    };
                    // Figure out triangle points
                    Triangle triangle;
                    for (int edge=0; edge<3; edge++) {
                        // points at end of edges
                        int point1 = edgePoints[2*edge];
                        int point2 = edgePoints[(2*edge+1)];
                        // Binary values, to find out which dimension to interpolate
                        // Remember that the bits are reversed
                        int p1[3] = {
                            vertPos[edgePoints[2*edge]][2],
                            vertPos[edgePoints[2*edge]][1],
                            vertPos[edgePoints[2*edge]][0]};
                        int p2[3] = {
                            vertPos[edgePoints[(2*edge+1)]][2],
                            vertPos[edgePoints[(2*edge+1)]][1],
                            vertPos[edgePoints[(2*edge+1)]][0]};
                        // coords of those points
                        double c1 = [[scalarData objectAtIndex:is[point1]] doubleValue];
                        double c2 = [[scalarData objectAtIndex:is[point2]] doubleValue];
                        double interp = (isovalue-c1)/(c2-c1);
                        double px = interp*abs(p1[0]-p2[0])+(p1[0]*p2[0]);
                        double py = interp*abs(p1[1]-p2[1])+(p1[1]*p2[1]);
                        double pz = interp*abs(p1[2]-p2[2])+(p1[2]*p2[2]);
                        GLdouble point_pos[3] = {
                            // Normalise to +-0.5
                            ((i+px)-((x-1)/2.0))/(x-1),
                            ((j+py)-((y-1)/2.0))/(y-1),
                            ((k+pz)-((z-1)/2.0))/(z-1)};
                        triangle.points[edge][0][0] = point_pos[0];
                        triangle.points[edge][0][1] = point_pos[1];
                        triangle.points[edge][0][2] = point_pos[2];
                    };
                    [self setNum_triangles:[self num_triangles]+1];
                    //Get the surface normal for this triangle
                    getFaceNormal(triangle.normal, triangle.points[0][0], triangle.points[1][0], triangle.points[2][0]);
                    [self addTriangle:triangle];
                }
            }
        }
    }
    [self setSmoothedNormals:FALSE];
    NSLog(@"Triangles: %d", num_triangles);
}
    
- (void)computeVertexNormals {
    // get vertex normals
    if (num_triangles>-1) {
        NSLog(@"Getting vertex normals...");
        for (int t=0; t<num_triangles; t++) {
            for (int v=0; v<3; v++) {
                triangles[t].points[v][1][0] = 0;
                triangles[t].points[v][1][1] = 0;
                triangles[t].points[v][1][2] = 0;
                // loop through vertices again
                for (int t2=0; t2<num_triangles; t2++) {
                    //double weight = area(triangles[t2].points);
                    if (t2!=-1) { // Don't average triangle with itself
                        for (int v2=0; v2<3; v2++) {
                            // Sum normals from faces with same vertex
                            if (triangles[t].points[v][0][0]==triangles[t2].points[v2][0][0] &&
                                triangles[t].points[v][0][1]==triangles[t2].points[v2][0][1] &&
                                triangles[t].points[v][0][2]==triangles[t2].points[v2][0][2]) {
                                // matching vertices, sum normals
                                triangles[t].points[v][1][0] += triangles[t2].normal[0];
                                triangles[t].points[v][1][1] += triangles[t2].normal[1];
                                triangles[t].points[v][1][2] += triangles[t2].normal[2];
                            }
                        }
                    }
                }
                Normalize(triangles[t].points[v][1]);
            }
        }
    }
    [self setSmoothedNormals:TRUE];
}

- (void)renderWithSmoothing:(BOOL)smoothing {
    if (smoothing==TRUE) {
    }
    if (smoothedNormals==FALSE && smoothing==TRUE) {
        [self computeVertexNormals];
    }
    for (int t=0; t<num_triangles; t++) {
        glBegin(GL_TRIANGLES);
        if (smoothing==FALSE) {glNormal3f(triangles[t].normal[0], triangles[t].normal[1], triangles[t].normal[2]);}
        for (int i=0; i<3; i++) {
            GLfloat p[3] = {triangles[t].points[i][0][0], triangles[t].points[i][0][1], triangles[t].points[i][0][2]};
            GLfloat n[3] = {triangles[t].points[i][1][0], triangles[t].points[i][1][1], triangles[t].points[i][1][2]};
            if (smoothing==TRUE) {glNormal3f(n[0], n[1], n[2]);}
            glVertex3f(p[0], p[1], p[2]);
        }
        glEnd();
    }
}

- (void)renderNormalsAtScale:(float)scale withSmoothing:(BOOL)smoothing {
    for (int t=0; t<num_triangles; t++) {
        if (smoothing==FALSE) {
            glBegin(GL_LINES);
            glColor3f(1.0f, 1.0f, 1.0f);
            glVertex3f(triangles[t].points[0][0][0], triangles[t].points[0][0][1], triangles[t].points[0][0][2]);
            glColor3f(0.0f, 0.0f, 1.0f);
            glVertex3f(triangles[t].points[0][0][0]+triangles[t].normal[0]*scale,triangles[t].points[0][0][1]+triangles[t].normal[1]*scale,triangles[t].points[0][0][2]+triangles[t].normal[2]*scale);
            glEnd();
        } else {
            for (int v=0; v<3; v++) {
                glBegin(GL_LINES);
                glColor3f(1.0f, 1.0f, 1.0f);
                glVertex3f(triangles[t].points[v][0][0], triangles[t].points[v][0][1], triangles[t].points[v][0][2]);
                glColor3f(0.0f, 0.0f, 1.0f);
                glVertex3f(triangles[t].points[v][0][0]+triangles[t].points[v][1][0]*scale,triangles[t].points[v][0][1]+triangles[t].points[v][1][1]*scale,triangles[t].points[v][0][2]+triangles[t].points[v][1][2]*scale);
                glEnd();
            }
        }
    }
}

-(void)renderVertices {
	//Get plain vanilla floats back out of dimensions array
    int x = (int)[[dimensions objectAtIndex:0] intValue];
    int y = (int)[[dimensions objectAtIndex:1] intValue];
    int z = (int)[[dimensions objectAtIndex:2] intValue];
    for (int i=0; i<x; i++) {
        for (int j=0; j<y; j++) {
            for (int k=0; k<z; k++) {
                float v = [[scalarData objectAtIndex:k + j*z + i*z*y] floatValue];
                float x_pos = ((GLfloat)i-((x-1)/2.0))/(x-1);
                float y_pos = ((GLfloat)j-((y-1)/2.0))/(y-1);
                float z_pos = ((GLfloat)k-((z-1)/2.0))/(z-1);
                if (v >= isovalue) {
                    GLfloat pos[3] = {x_pos, y_pos, z_pos};
                    drawCube(1, 0.01, pos);
                }
            }
        }
    }
}

// Dynamically resize array to accommodate new objects
-(int)addTriangle:(Triangle)item
{
	if(num_elements == num_allocated) { // Are more refs required?
        
		if (num_allocated == 0)
			num_allocated = 10; // Start off with 10 refs
		else
			num_allocated *= 2; // Double the number of refs allocated
		
		// Make the reallocation transactional by using a temporary variable first
		void *_tmp = realloc([self triangles], (num_allocated * sizeof(Triangle)));
		
		// If the reallocation didn't go so well, inform the user and bail out
		if (!_tmp) { 
			fprintf(stderr, "ERROR: Couldn't realloc memory!\n");
			return(-1); 
		}
		[self setTriangles:(Triangle*)_tmp];	
	}
	
	triangles[num_elements] = item; 
	num_elements++;
	
	return num_elements;
}

-(void)dealloc {
    [super dealloc];
    free(triangles);
}

@end
