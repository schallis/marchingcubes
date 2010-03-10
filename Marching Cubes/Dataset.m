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

int signof(float a) { return (a == 0) ? 0 : (a<0 ? -1 : 1); }

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
    
    //Vec3 *origin = [[Vec3 alloc] initiWithX:0.5 Y:0.5 Z:0];
    //Vec3 *direction = [[Vec3 alloc] initiWithX:0 Y:0 Z:1];
    //Vec3 *direction = [[Vec3 alloc] initiWithX:0.8 Y:0.267 Z:0.534];
    //Ray *r = [[Ray alloc] initWithOrigin:origin direction:direction];
    //NSLog(@"New ray: %@", r);
    //[self intersectRay:r withIsovalue:0.005];
    [self computeIlluminationWithSamples:10000];
}

- (void)computeIlluminationWithSamples:(int)samples {
    // generate 1 ray per sample
    int num_hits = 0;
    for (int i=0; i<samples; i++) {
        float x = (float)rand()/(float)RAND_MAX*([[dimensions objectAtIndex:0] floatValue]-1);
        float y = (float)rand()/(float)RAND_MAX*([[dimensions objectAtIndex:1] floatValue]-1);
        //NSLog(@"x:%f y:%f",x, y);
        Vec3 *origin = [[Vec3 alloc] initiWithX:x Y:y Z:0];
        Vec3 *direction = [[Vec3 alloc] initiWithX:0 Y:0 Z:1];
        Ray *r = [[Ray alloc] initWithOrigin:origin direction:direction];
        //NSLog(@"New ray: %@", r);
        float v = [self isovalueFromUnitIsovalue:0.5];
        //NSLog(@"iso: %f", v);
        Hit *hit = [self intersectRay:r withIsovalue:v];
        if (hit)
            num_hits += 1;
    }
    NSLog(@"Hits: %d", num_hits);
}

- (float)isovalueFromUnitIsovalue:(float)value {
    // given a value between 0 and 1, return
    // corresponding isovalues for dataset
    return value * (maxValue - minValue) + minValue;
}

- (void)recalculateWithIsovalue:(float)value {
    [self clearData];
    float normIso = [self isovalueFromUnitIsovalue:value];
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
                    k + j*z + (i+1)*z*y,        // 001  1
                    k + (j+1)*z + i*z*y,        // 010  2
                    k + (j+1)*z + (i+1)*z*y,    // 011  3
                    (k+1) + (j*z) + i*z*y,      // 100  4
                    (k+1) + (j*z) + (i+1)*z*y,  // 101  5
                    (k+1) + (j+1)*z + i*z*y,    // 110  6
                    (k+1) + (j+1)*z + (i+1)*z*y // 111  7
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
    NSLog(@"Isovalue:%.3f Triangles: %d", isovalue, num_triangles);
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

- (void)renderWithSmoothing:(BOOL)smoothing cellShading:(BOOL)cell {
    if (smoothedNormals==FALSE && smoothing==TRUE) {
        [self computeVertexNormals];
    }
    for (int t=0; t<num_triangles; t++) {
        if (cell==TRUE) {
            // Cell shading :)
            glLineWidth(5.0f);
            glColor3f(0.3f, 0.4f, 0.5f);
            glEnable(GL_CULL_FACE);
            glDisable(GL_LIGHTING);
            glCullFace(GL_FRONT);
            glPolygonMode(GL_BACK, GL_LINE);
            glBegin(GL_TRIANGLES);
            if (smoothing==FALSE) {glNormal3f(triangles[t].normal[0], triangles[t].normal[1], triangles[t].normal[2]);}
            for (int i=0; i<3; i++) {
                GLfloat p[3] = {triangles[t].points[i][0][0], triangles[t].points[i][0][1], triangles[t].points[i][0][2]};
                GLfloat n[3] = {triangles[t].points[i][1][0], triangles[t].points[i][1][1], triangles[t].points[i][1][2]};
                if (smoothing==TRUE) {glNormal3f(n[0], n[1], n[2]);}
                glVertex3f(p[0], p[1], p[2]);
            }
            glEnd();
            glDisable(GL_CULL_FACE);
            glEnable(GL_LIGHTING);
            glColor3f(0.5f, 0.6f, 0.7f);
        }
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
-(int)addTriangle:(Triangle)item {

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

- (Hit *)intersectRay:(Ray *)r withVoxel:(Vec3 *)voxel isovalue:(float)val tin:(Vec3 *)tin tout:(Vec3 *)tout {
    //NSLog(@"vox:%@ iso:%f tin:%@ tout:%@", voxel, val, tin, tout);
    // lookup voxel values
    // test if val within them
    int i = [voxel x];
    int j = [voxel y];
    int k = [voxel z];
    int y = (int)[[dimensions objectAtIndex:1] intValue];
    int z = (int)[[dimensions objectAtIndex:2] intValue];
    //NSLog(@"ijkyz: %d %d %d %d %d", i,j,k,y,z);
    int is[8] = {
        // Bits are in reverse order
        k + j*z + i*z*y,                // 000  0
        k + j*z + (i+1)*z*y,            // 001  1
        k + (j+1)*z + i*z*y,            // 010  2
        k + (j+1)*z + (i+1)*z*y,        // 011  3
        (k+1) + j*z + i*z*y,            // 100  4
        (k+1) + j*z + (i+1)*z*y,        // 101  5
        (k+1) + (j+1)*z + i*z*y,        // 110  6
        (k+1) + (j+1)*z + (i+1)*z*y     // 111  7
    };
    float vs[8];
    for (int n=0; n<8; n++) {
        vs[n] = [[[self scalarData] objectAtIndex:is[n]] floatValue];
    }
    // Figure out which ones are above the threshold
    int count = 0;
    for (int n=0; n<8; n++) {
        if (vs[n] >= val)
            count += 1;
    }
    //NSLog(@"count: %d", count);
    if (count != 0 && count != 8) {
        // return intersection with colour and hit point
        //NSLog(@"Intersect voxel: %@", voxel);

        // calculate hit point
        float inx, iny, inz, outx, outy, outz,
              dx00, dx01, dx10, dx11, dxy0, dxy1,
              pin, pout;
        inx = [tin x]-[voxel x];
        iny = [tin y]-[voxel y];
        inz = [tin z]-[voxel z];
        //NSLog(@"ins: %f %f %f", inx, iny, inz);
        dx00 = LERP(inz, vs[0], vs[1]);
        dx01 = LERP(inz, vs[4], vs[5]);
        dx10 = LERP(inz, vs[2], vs[3]);
        dx11 = LERP(inz, vs[6], vs[7]);
        dxy0 = LERP(iny, dx00, dx10);
        dxy1 = LERP(iny, dx01, dx11);
        pin = LERP(inx, dxy0, dxy1);
        
        outx = [tout x]-[voxel x];
        outy = [tout y]-[voxel y];
        outz = [tout z]-[voxel z];
        //NSLog(@"outs: %f %f %f", outx, outy, outz);
        dx00 = LERP(outz, vs[0], vs[1]);
        dx01 = LERP(outz, vs[4], vs[5]);
        dx10 = LERP(outz, vs[2], vs[3]);
        dx11 = LERP(outz, vs[6], vs[7]);
        dxy0 = LERP(outy, dx00, dx10);
        dxy1 = LERP(outy, dx01, dx11);
        pout = LERP(outx, dxy0, dxy1);
        
        //NSLog(@"pin:%f pout:%f", pin, pout);
        //NSLog(@"tin:%@ tout:%@", tin, tout);
        //NSLog(@"iso:%f", val);
        if (signof(pin-val) == signof(pout-val)) {
            //NSLog(@"NILL");
        } else {
            Vec3 *thit = [tin c_add:[[tout c_subtract:tin] c_product:((val - pin) / (pout - pin))]];
            Vec3 *color = [[Vec3 alloc] initiWithX:1.0 Y:1.0 Z:1.0];
            Hit *hit = [[Hit alloc] initWithLocation:thit rgb:color];
            //NSLog(@"Hit surface at: %@", thit);
            return hit;
        }
    }
    return Nil;
}

- (Hit *)intersectRay:(Ray *)r withIsovalue:(float)val {
    //NSLog(@"ray:%@", r);
    // Set cur to nearest voxel (represented by integer)
    Vec3 *cur = [[Vec3 alloc] initiWithX:floor([[r origin] x])
                                       Y:floor([[r origin] y])
                                       Z:floor([[r origin] z])];
    
    // rel hold relative distance travelled (in unit voxels), initially zero
    Vec3 *rel = [[Vec3 alloc] initiWithX:0 Y:0 Z:0];
    
    // holds relative distance travelled in absolute units
    Vec3 *tRel = [[Vec3 alloc] initiWithX:0 Y:0 Z:0];
    
    float tParam = 0.0;
    float tParamNext = 0.0;
    
    Vec3 *sign = [[Vec3 alloc] initiWithX:1 Y:1 Z:1];
    if ([[r direction] x] < 0)
        [sign setX:-1];
    if ([[r direction] y] < 0)
        [sign setY:-1];
    if ([[r direction] z] < 0)
        [sign setZ:-1];
    
    // delta holds components for each dimension from ray direction
    // Useful to find next boundary of intersection
    Vec3 *delta = [[Vec3 alloc] initiWithX:0 Y:0 Z:0];
    if ([[r direction] x] != 0)
        [delta setX:1/[[r direction] x]];
    if ([[r direction] y] != 0)
        [delta setY:1/[[r direction] y]];
    if ([[r direction] z] != 0)
        [delta setZ:1/[[r direction] z]];
    //NSLog(@"delta: %@", delta);
    
    BOOL inside = TRUE;

    while (inside>0) {
        //NSLog(@"cur: %@", cur);
        
        // Get distances til next boundary
        float dx = fabs(([rel x] + [sign x]) * [delta x]);
        float dy = fabs(([rel y] + [sign y]) * [delta y]);
        float dz = fabs(([rel z] + [sign z]) * [delta z]);
        //NSLog(@"dx:%f dy:%f dz:%f", dx, dy, dz);

        // Find minimum distance that is not zero
        if (dx != 0 && (dx <= dy || dy == 0) && (dx <= dz || dz == 0)) {
            // Check for out of range values
            if (([cur x] > [[dimensions objectAtIndex:0] floatValue]-2) || ([cur x] < 0)) {
                inside = FALSE;
            } else {
                Vec3 *oldCur = [[Vec3 alloc] initiWithX:[cur x]
                                                      Y:[cur y]
                                                      Z:[cur z]];
                Vec3 *oldTRel = [[Vec3 alloc] initiWithX:[tRel x]
                                                       Y:[tRel y]
                                                       Z:[tRel z]];
                [cur setX:floor([cur x] + [sign x])];
                [rel setX:[rel x] + [sign x]];
                [tRel setX:[tRel x] + [[r direction] x]];
                [tRel setY:ceil([tRel y])];
                [tRel setZ:ceil([tRel z])];
                tParam = sqrt(pow([oldTRel x],2) + pow([oldTRel y],2) + pow([oldTRel z],2));
                tParamNext = sqrt(pow([tRel x],2) + pow([tRel y],2) + pow([tRel z],2));
                //NSLog(@"oldtRel: %@, tRel: %@", oldTRel, tRel);
                //NSLog(@"tParam: %f, tParamNext: %f", tParam, tParamNext);
                //NSLog(@"current: %@", cur);
                //NSLog(@"point: %@", [r pointAtParamater:tParamNext]);
                return [self intersectRay:r  withVoxel:oldCur isovalue:val
                                      tin:[r pointAtParamater:tParam]
                                     tout:[r pointAtParamater:tParamNext]];
            }
        } else if (dy != 0 && (dy <= dx || dx == 0) && (dy <= dz || dx == 0)) {
            if (([cur y] > [[dimensions objectAtIndex:1] floatValue]-2) || ([cur y] < 0)) {
                inside = FALSE;
            } else {
                Vec3 *oldCur = [[Vec3 alloc] initiWithX:[cur x]
                                                      Y:[cur y]
                                                      Z:[cur z]];
                Vec3 *oldTRel = [[Vec3 alloc] initiWithX:[tRel x]
                                                       Y:[tRel y]
                                                       Z:[tRel z]];
                [cur setY:floor([cur y] + [sign y])];
                [rel setY:[rel y] + [sign y]];
                [tRel setX:ceil([tRel x])];
                [tRel setY:[tRel y] + [[r direction] y]];
                [tRel setZ:ceil([tRel z])];
                tParam = sqrt(pow([oldTRel x],2) + pow([oldTRel y],2) + pow([oldTRel z],2));
                tParamNext = sqrt(pow([tRel x],2) + pow([tRel y],2) + pow([tRel z],2));
                //NSLog(@"oldtRel: %@, tRel: %@", oldTRel, tRel);
                //NSLog(@"tParam: %f, tParamNext: %f", tParam, tParamNext);
                //NSLog(@"current: %@", cur);
                //NSLog(@"point: %@", [r pointAtParamater:tParamNext]);
                return [self intersectRay:r  withVoxel:oldCur isovalue:val
                                      tin:[r pointAtParamater:tParam]
                                     tout:[r pointAtParamater:tParamNext]];
            }
        } else if (dz != 0 && (dz <= dx || dx == 0) && (dz <= dy || dx == 0)) {
            if (([cur z] > [[dimensions objectAtIndex:2] floatValue]-2) || ([cur z] < 0)) {
                inside = FALSE;
                //NSLog(@"NEIGH!");
            } else {
                //NSLog(@"YEIGH!");
                Vec3 *oldCur = [[Vec3 alloc] initiWithX:[cur x]
                                                      Y:[cur y]
                                                      Z:[cur z]];
                Vec3 *oldTRel = [[Vec3 alloc] initiWithX:[tRel x]
                                                       Y:[tRel y]
                                                       Z:[tRel z]];
                [cur setZ:floor([cur z] + [sign z])];
                [rel setZ:[rel z] + [sign z]];
                [tRel setX:ceil([tRel x])];
                [tRel setY:ceil([tRel y])];
                [tRel setZ:[tRel z] + [[r direction] z]];
                tParam = sqrt(pow([oldTRel x],2) + pow([oldTRel y],2) + pow([oldTRel z],2));
                tParamNext = sqrt(pow([tRel x],2) + pow([tRel y],2) + pow([tRel z],2));
                //NSLog(@"oldtRel: %@, tRel: %@", oldTRel, tRel);
                //NSLog(@"tParam: %f, tParamNext: %f", tParam, tParamNext);
                //NSLog(@"current: %@", cur);
                //NSLog(@"point: %@", [r pointAtParamater:tParamNext]);
                return [self intersectRay:r  withVoxel:oldCur isovalue:val
                                      tin:[r pointAtParamater:tParam]
                                     tout:[r pointAtParamater:tParamNext]];
            }
        } else {
            NSLog(@"Error: d:%.1f %.1f %.1f cur:%@", dx, dy, dz, cur);
            inside = FALSE;
        }
    }
    return Nil;
}

-(void)dealloc {
    [super dealloc];
    free(triangles);
}

@end
