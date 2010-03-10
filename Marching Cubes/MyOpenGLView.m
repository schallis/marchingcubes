//
//  MyOpenGLView.m
//
//  Created by Steve Challis on 04/12/2009.
//  Copyright 2009 Steve Challis. All rights reserved.
//

#import "MyOpenGLView.h"
#import "functions.h"
#import "trackball.h"
#include <math.h>

// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE;
GLboolean gPan = GL_FALSE;
GLboolean gTrackball = GL_FALSE;
MyOpenGLView * gTrackingViewInfo = NULL;

// lighing properties
GLfloat LightAmbient[4] = {0.4f, 0.4f, 0.4f, 1.0f}; 
GLfloat LightDiffuse[4] = {0.9f, 0.9f, 0.9f, 1.0f};
GLfloat LightSpecular[4] = {0.2f, 0.2f, 0.2f, 1.0f};
GLfloat LightPosition[4] = {0.4f, 1.2f, -0.7f, 1.0f};
GLfloat LightPosition2[4] = {0.0f, 1.5f, -0.9f, 1.0f};
float colorBlueAmb[4] = {0.6, 0.7, 0.8, 1.0};
float colorBlueDiff[4] = {0.73, 0.74, 0.74, 1.0};
float colorBlueSpec[4] = {0.1, 0.1, 0.1, 1.0};

static CFAbsoluteTime gStartTime = 0.0f;

// set app start time
static void setStartTime (void)
{	
	gStartTime = CFAbsoluteTimeGetCurrent ();
}

// return float elpased time in seconds since app start
static CFAbsoluteTime getElapsedTime (void)
{	
	return CFAbsoluteTimeGetCurrent () - gStartTime;
}
              
recVec gOrigin = {0.0, 0.0, 0.0};

@implementation MyOpenGLView

@synthesize dataset, surfaceType, showNormals, vertexNormals, showVertices, showBox, startingWindow;

// pixel format definition
+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16, // 16 bit depth buffer, doesn't seem to work, set in IB also
        (NSOpenGLPixelFormatAttribute)nil
    };
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

// respond to slider change 
- (IBAction) scale:(id)obj {
	[self setScale:[obj floatValue]];
}

// update object scale
- (void) setScale:(float)newScale {
}
// respond to slider change 
- (IBAction) isoValue:(id)obj {
	[self setIsoValue:[obj floatValue]];
    [dataset recalculateWithIsovalue:objIsoValue];
}

// update isovalue
- (void) setIsoValue:(float)newIsoValue {
	objIsoValue = (GLfloat)newIsoValue;
}

// change the function used to render the surface
- (IBAction) changeWave:(id)obj {
    NSString *file = [[obj selectedItem] representedObject];
    [self setDataset:[[Dataset alloc] init]];
    NSLog(@"Changing dataset ...");
    [dataset initWithContentsOfFile:[@"../../" stringByAppendingString:file]];
    NSLog(@"Changed!");
    [dataset recalculateWithIsovalue:objIsoValue];
    NSLog(@"Recalculated!");
    //NSLog(@"%@", file);
    //NSLog(@"%d %d", [[[dataset dimensions] objectAtIndex:1] intValue], [[dataset scalarData] count]);
}

// change the type of the surface
- (IBAction) changeSurface:(id)obj {
    [self setSurfaceType:[[obj selectedItem] representedObject]];
    //NSLog(@"%@", [self surfaceType]);
}

// change the type of the surface
- (IBAction) toggleNormals:(id)obj {
    [self setShowNormals:[obj state]];
    //NSLog(@"%d", [self showNormals]);
}

// change the type of the surface
- (IBAction) toggleVertexNormals:(id)obj {
    [self setVertexNormals:[obj state]];
    //NSLog(@"%d", [self showNormals]);
}

// change the type of the surface
- (IBAction) toggleVertices:(id)obj {
    [self setShowVertices:[obj state]];
    //NSLog(@"%d", [self showVertices]);
}

// change the type of the surface
- (IBAction) toggleBox:(id)obj {
    [self setShowBox:[obj state]];
    //NSLog(@"%d", [self showBox]);
}

- (IBAction) toggleFullScreen:(id)sender {
    if( fullscreenOn == true )
    {
        [fullscreenWindow close];
        [startingWindow setAcceptsMouseMovedEvents:YES];
        [startingWindow setContentView: self];
        [startingWindow makeKeyAndOrderFront: self];
        [startingWindow makeFirstResponder: self];
        fullscreenOn = false;
    }
    else
    {
        NSRect frame = [[NSScreen mainScreen] frame];
        fullscreenWindow = [[NSWindow alloc]
                            initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer: NO];
        [startingWindow setAcceptsMouseMovedEvents:NO];
        if(fullscreenWindow != nil)
        {		
            [fullscreenWindow setTitle: @"Full Screen"];			
            [fullscreenWindow setReleasedWhenClosed: YES];
            [fullscreenWindow setAcceptsMouseMovedEvents:YES];
            [fullscreenWindow setContentView: self];
            [fullscreenWindow makeKeyAndOrderFront:self ];
            [fullscreenWindow setLevel: NSScreenSaverWindowLevel-1];
            [fullscreenWindow makeFirstResponder:self];
            fullscreenOn = true;
        } else {
            NSLog(@"Error: could not create fullscreen window!");
        }
    }
}

// update the projection matrix based on camera and view info
- (void) updateProjection
{
	GLdouble ratio, radians, wd2;
	GLdouble left, right, top, bottom, near, far;
	
    [[self openGLContext] makeCurrentContext];
	
	// set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians 
	wd2 = near * tan(radians);
    // Aspect ratio
	ratio = camera.viewWidth / (float) camera.viewHeight;
	if (ratio >= 1.0) {
		left  = -ratio * wd2;
		right = ratio * wd2;
		top = wd2;
		bottom = -wd2;	
	} else {
		left  = -wd2;
		right = wd2;
		top = wd2 / ratio;
		bottom = -wd2 / ratio;	
	}
	glFrustum (left, right, bottom, top, near, far);
}

// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
	// move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
    
    // if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);
	else {
	}
	// accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
    
	glRotated(-20.0, 1.0, 0.0, 0.0);
}

// handles resizing of GL need context update and if the window dimensions change, a
// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	
	// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) {
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
	}
}

// per-window timer function, basic time based animation preformed here
- (void)animationTimer:(NSTimer *)timer
{
	BOOL shouldDraw = NO;
	
	CFTimeInterval deltaTime = CFAbsoluteTimeGetCurrent () - time;
	
	if (deltaTime > 10.0) // skip pauses
		return;
	else {
		shouldDraw = YES; // force redraw
	}
	time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
	if (YES == shouldDraw)
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
}

// sets the camera data to initial conditions
- (void) resetCamera
{
	camera.aperture = 40;
	camera.rotPoint = gOrigin;
	
	camera.viewPos.x = 0.0;
	camera.viewPos.y = 0.0;
	camera.viewPos.z = -3.0;
	camera.viewDir.x = -camera.viewPos.x; 
	camera.viewDir.y = -camera.viewPos.y; 
	camera.viewDir.z = -camera.viewPos.z;
	
	camera.viewUp.x = 0;  
	camera.viewUp.y = 1; 
	camera.viewUp.z = 0;
}

- (void) drawRect:(NSRect)rect
{		
	// setup viewport and prespective
	[self resizeGL]; // forces projection matrix update (does test for size changes)
    
	[self updateModelView];  // update model view matrix for object
	
	// clear our drawable
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Basic drawing properties
    glLineWidth(1.0);
    glPointSize(1.0);
    glColor3f(0.5f, 0.6f, 0.7f);
    glMaterialfv(GL_FRONT, GL_AMBIENT, colorBlueAmb);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, colorBlueDiff);
    //glMaterialfv(GL_FRONT, GL_SPECULAR, colorBlueSpec);
    glMaterialf(GL_FRONT, GL_SHININESS, 10); // 0-128
    glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, 1.0f);
    glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, 0.2f);
    glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0.08f);
    
	// Move light
	//LightPosition[0] = sin(getElapsedTime())*1.5;
	//LightPosition[2] = cos(getElapsedTime())*1.5;
    glLightfv(GL_LIGHT0, GL_POSITION, LightPosition);
    
    // Draw light source
    glColor3f(1.0, 1.0, 0.0);
    drawCube(1, 0.1, LightPosition);
    
    int x = (int)[[[dataset dimensions] objectAtIndex:0] intValue];
    int y = (int)[[[dataset dimensions] objectAtIndex:1] intValue];
    int z = (int)[[[dataset dimensions] objectAtIndex:2] intValue];
    float max = (float) x > y ? x : y;
    max = (float) max > z ? max : z;
    glScalef(x/max, y/max, z/max);
    
    // Draw bounding box
    if (showBox > 0) {
        glColor3f(0.7f, 0.0f, 0.0f);
        GLfloat pos[3] = {0.0,0.0,0.0};
        drawCube(0, 0.5, pos);
    }
    
    // Draw surface
    if (surfaceType != @"none") {
        if (surfaceType == @"solid") {
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        } else {
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        }
        glColor3f(0.5f, 0.6f, 0.7f);
        if (vertexNormals > 0) {
            [dataset renderWithSmoothing:TRUE cellShading:FALSE];
        } else {
            [dataset renderWithSmoothing:FALSE cellShading:FALSE];
        }
        // Draw normals
        if (showNormals > 0) {
            if (vertexNormals > 0) {
            [dataset renderNormalsAtScale:0.1 withSmoothing:TRUE];
            } else {
                [dataset renderNormalsAtScale:0.1 withSmoothing:FALSE];
            }

        }
    }
        
    // Draw green cubes at grid vertices
    if (showVertices > 0) {
        glColor3f(0.0f, 1.0f, 0.0f);
        [dataset renderVertices];
    }
    
	[[self openGLContext] flushBuffer];
}

// move camera in z axis
-(void)mouseDolly: (NSPoint) location
{
	GLfloat dolly = (gDollyPanStartPoint[1] -location.y) * -camera.viewPos.z / 300.0f;
	camera.viewPos.z += dolly;
	if (camera.viewPos.z == 0.0) // do not let z = 0.0
		camera.viewPos.z = 0.0001;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

// move camera in x/y plane
- (void)mousePan: (NSPoint) location
{
	GLfloat panX = (gDollyPanStartPoint[0] - location.x) / (900.0f / -camera.viewPos.z);
	GLfloat panY = (gDollyPanStartPoint[1] - location.y) / (900.0f / -camera.viewPos.z);
	camera.viewPos.x -= panX;
	camera.viewPos.y -= panY;
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
}

- (void)mouseDown:(NSEvent *)theEvent // trackball
{
    if ([theEvent modifierFlags] & NSControlKeyMask) // send to pan
		[self rightMouseDown:theEvent];
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) // send to dolly
		[self otherMouseDown:theEvent];
	else {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		location.y = camera.viewHeight - location.y;
		gDolly = GL_FALSE; // no dolly
		gPan = GL_FALSE; // no pan
		gTrackball = GL_TRUE;
		startTrackball (location.x, location.y, 0, 0, camera.viewWidth, camera.viewHeight);
		gTrackingViewInfo = self;
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent // pan
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_FALSE; // no dolly
	gPan = GL_TRUE; 
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

- (void)otherMouseDown:(NSEvent *)theEvent //dolly
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) { // if we are currently tracking, end trackball
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	}
	gDolly = GL_TRUE;
	gPan = GL_FALSE; // no pan
	gTrackball = GL_FALSE; // no trackball
	gDollyPanStartPoint[0] = location.x;
	gDollyPanStartPoint[1] = location.y;
	gTrackingViewInfo = self;
}

- (void)mouseUp:(NSEvent *)theEvent
{
	if (gDolly) { // end dolly
		gDolly = GL_FALSE;
	} else if (gPan) { // end pan
		gPan = GL_FALSE;
	} else if (gTrackball) { // end trackball
		gTrackball = GL_FALSE;
		if (gTrackBallRotation[0] != 0.0)
			addToRotationTrackball (gTrackBallRotation, worldRotation);
		gTrackBallRotation [0] = gTrackBallRotation [1] = gTrackBallRotation [2] = gTrackBallRotation [3] = 0.0f;
	} 
	gTrackingViewInfo = NULL;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	[self mouseUp:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	location.y = camera.viewHeight - location.y;
	if (gTrackball) {
		rollToTrackball (location.x, location.y, gTrackBallRotation);
		[self setNeedsDisplay: YES];
	} else if (gDolly) {
		[self mouseDolly: location];
		[self updateProjection];  // update projection matrix (not normally done on draw)
		[self setNeedsDisplay: YES];
	} else if (gPan) {
		[self mousePan: location];
		[self setNeedsDisplay: YES];
	}
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged: theEvent];
}
- (void) prepareOpenGL
{
    GLint swapInt = 1;

	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync
	
	// init GL stuff here
	glEnable(GL_DEPTH_TEST);
	glShadeModel(GL_SMOOTH);
    //glDisable(GL_CULL_FACE);
	glFrontFace(GL_CW);
    glEnable(GL_COLOR_MATERIAL);
	glPolygonOffset (1.0f, 1.0f);
    //glEnable(GL_BLEND);
    //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	// Put the lights up
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glLightfv(GL_LIGHT0, GL_AMBIENT, LightAmbient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, LightDiffuse);
	//glLightfv(GL_LIGHT0, GL_SPECULAR, LightSpecular);
	glLightfv(GL_LIGHT0, GL_POSITION, LightPosition);
	//glEnable(GL_LIGHT1);
	glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);
	glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);
	glLightfv(GL_LIGHT1, GL_SPECULAR, LightSpecular);
	glLightfv(GL_LIGHT1, GL_POSITION, LightPosition2);
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	
	[self resetCamera];
	
	shapeSize = 3.0;	// max radius of of objects
	objIsoValue = 0.5;	// Initial isovalue
    [dataset recalculateWithIsovalue:objIsoValue];
}

// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
	[super update];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return  YES;
}

- (BOOL)resignFirstResponder
{
	return YES;
}

-(id) initWithFrame: (NSRect) frameRect
{
	NSOpenGLPixelFormat * pf = [MyOpenGLView basicPixelFormat];
	
	self = [super initWithFrame: frameRect pixelFormat: pf];
	
    return self;
}

- (void) awakeFromNib
{
    [self setDataset:[[Dataset alloc] init]];
    [dataset initWithContentsOfFile:@"../../test.txt"];

    [self setSurfaceType:@"solid"];
    [self setShowNormals:0];
    [self setVertexNormals:0];
    [self setShowVertices:0];
    [self setShowBox:1];
    
	//setStartTime();
	time = CFAbsoluteTimeGetCurrent ();  // set animation time start time
	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
}

@end
