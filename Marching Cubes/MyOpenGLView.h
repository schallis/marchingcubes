//
//  MyOpenGLView.h
//
//  Created by Steve Challis on 04/12/2009.
//  Copyright 2009 All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>
#import <GLUT/glut.h>
#import "MarchingCubesAppDelegate.h"
#import "Dataset.h"

typedef struct {
	GLdouble x,y,z;
} recVec;

typedef struct {
	recVec viewPos; // View position
	recVec viewDir; // View direction vector
	recVec viewUp; // View up direction
	recVec rotPoint; // Point to rotate about
	GLdouble aperture; // pContextInfo->camera aperture
	GLint viewWidth, viewHeight; // current window/screen height and width
} recCamera;

@interface MyOpenGLView : NSOpenGLView {
    NSWindow *fullscreenWindow;
    NSWindow *startingWindow;
    BOOL fullscreenOn;
    
	NSTimer *timer;
	CFAbsoluteTime time;
    
	// camera handling
	recCamera camera;
	GLfloat worldRotation [4];
	GLfloat objectRotation [4];
	GLfloat shapeSize;
	GLfloat objScale;
	GLfloat objIsoValue;
    
    Dataset *dataset;
    NSString *surfaceType;
    NSInteger showNormals;
    NSInteger vertexNormals;
    NSInteger showVertices;
    NSInteger showBox;
}

@property (assign, readwrite) Dataset *dataset;
@property (copy) NSString *surfaceType;
@property (readwrite) NSInteger showNormals;
@property (readwrite) NSInteger vertexNormals;
@property (readwrite) NSInteger showVertices;
@property (readwrite) NSInteger showBox;
@property (assign) IBOutlet NSWindow *startingWindow;

+ (NSOpenGLPixelFormat*) basicPixelFormat;

- (IBAction) scale:(id)obj;
- (void) setScale:(float)newScale;
- (IBAction) isoValue:(id)obj;
- (void) setIsoValue:(float)newIsoValue;
- (IBAction) changeWave:(id)obj;
- (IBAction) changeSurface:(id)obj;
- (IBAction) toggleNormals:(id)obj;
- (IBAction) toggleVertexNormals:(id)obj;
- (IBAction) toggleVertices:(id)obj;
- (IBAction) toggleBox:(id)obj;
- (IBAction) toggleFullScreen:(id)sender;

- (void) updateProjection;
- (void) updateModelView;
- (void) resizeGL;
- (void) animationTimer:(NSTimer *)timer;
- (void) resetCamera;

- (void) mouseDown:(NSEvent *)theEvent;
- (void) rightMouseDown:(NSEvent *)theEvent;
- (void) otherMouseDown:(NSEvent *)theEvent;
- (void) mouseUp:(NSEvent *)theEvent;
- (void) rightMouseUp:(NSEvent *)theEvent;
- (void) otherMouseUp:(NSEvent *)theEvent;
- (void) mouseDragged:(NSEvent *)theEvent;
- (void) rightMouseDragged:(NSEvent *)theEvent;
- (void) otherMouseDragged:(NSEvent *)theEvent;

- (void) drawRect:(NSRect)rect;

- (void) prepareOpenGL;
- (void) update;		// moved or resized

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (id) initWithFrame: (NSRect) frameRect;
- (void) awakeFromNib;

@end
