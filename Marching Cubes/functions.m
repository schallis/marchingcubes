#include <math.h>
#include <stdlib.h>
#include "functions.h"

float area(double points[3][2][3]) {
    // Find side lengths
    float a = (float)sqrt(pow(points[0][0][0],2)+ 
                            pow(points[0][0][2],2)+
                            pow(points[0][0][2],2));
    float b = (float)sqrt(pow(points[1][0][0],2)+ 
                            pow(points[1][0][2],2)+
                            pow(points[1][0][2],2));
    float c = (float)sqrt(pow(points[2][0][0],2)+ 
                            pow(points[2][0][2],2)+
                            pow(points[2][0][2],2));
    // Use heron's formula to compute area
    return (float)sqrt(((a+b+c)*(a+b-c)*(b+c-a)*(c+a-b))/16);
}

void getFaceNormal(double *norm, double pointa[3], double pointb[3], double pointc[3])
{
    double vect[2][3];
    int a,b;
    double point[3][3];
	
    for (a=0;a<3;++a)
    {
        point[0][a]=pointa[a];
        point[1][a]=pointb[a]; 
        point[2][a]=pointc[a];
    }
	
    for (a=0;a<2;++a)
    {
        for (b=0;b<3;++b)
        {
            vect[a][b]=point[2-a][b]-point[0][b];           
        }
    }
	
    CrossProduct(norm,vect[0],vect[1]); 
    Normalize(norm);
}

inline void Normalize(double * vect)	//scales a vector a length of 1
{
    double length;
    int a;
	
	//A^2 + B^2 + C^2 = length^2
    length=(double)sqrt(pow(vect[0],2)+ 
					   pow(vect[1],2)+
					   pow(vect[2],2)
					   );
	
    for (a=0;a<3;++a)	//divides vector by its length to normalise
    {
		// Avoid division by 0
		if (length == 0.0)
			length = 1.0;

        vect[a] /= length;
    }
}

void CrossProduct(double *c, double a[3], double b[3])
{  
	c[0]=a[1]*b[2] - b[1]*a[2];
    c[1]=a[2]*b[0] - b[2]*a[0];
    c[2]=a[0]*b[1] - b[0]*a[1];
}

double Square(double num)
{
    return num * num;
}

double EuclideanDistance(double x1, double y1, double z1, double x2, double y2, double z2)
{
    double dx_sqr = Square(x1 - x2);
    double dy_sqr = Square(y1 - y2);
    double dz_sqr = Square(z1 - z2);
    double distance = sqrt(dx_sqr + dy_sqr + dz_sqr);

    return distance;
}

double ChebyshevDistance(double x1, double y1, double z1, double x2, double y2, double z2)
{
    double r1 = fabs(x1-x2);
    double r2 = fabs(y1-y2);
    double r3 = fabs(z1-z2);
    
    double temp = (r2 > r3 ? r2 : r3);
    return r1 > temp ? r1 : temp;
}



// simple cube data
GLint cube_num_vertices = 8;

GLfloat cube_vertices [8][3] = {
    {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {-1.0, -1.0, 1.0}, {-1.0, 1.0, 1.0},
    {1.0, 1.0, -1.0}, {1.0, -1.0, -1.0}, {-1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0} };

GLfloat cube_vertex_colors [8][3] = {
    {1.0, 1.0, 1.0}, {1.0, 1.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 1.0, 1.0},
    {1.0, 0.0, 1.0}, {1.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0} };

GLint num_faces = 6;

short cube_faces [6][4] = {
    {3, 2, 1, 0}, {2, 3, 7, 6}, {0, 1, 5, 4}, {3, 0, 4, 7}, {1, 2, 6, 5}, {4, 5, 6, 7} };

void drawCube(int solid, float fSize, GLfloat pos[3]) {
    
    int f,i;
    
    glPushMatrix();
    glTranslatef(pos[0], pos[1], pos[2]);
    if (solid > 0) {
        glBegin (GL_QUADS);
        for (f = 0; f < num_faces; f++)
            for (i = 0; i < 4; i++) {
                glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
            }
        glEnd ();
    } else {
        for (f = 0; f < num_faces; f++) {
            glBegin (GL_LINE_LOOP);
            for (i = 0; i < 4; i++)
                glVertex3f(cube_vertices[cube_faces[f][i]][0] * fSize, cube_vertices[cube_faces[f][i]][1] * fSize, cube_vertices[cube_faces[f][i]][2] * fSize);
            glEnd ();
        }  
    }
    glPopMatrix();
}