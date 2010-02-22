float area(double points[3][2][3]);

void CrossProduct(double *c, double a[3], double b[3]);
void Normalize(double *vect);
void getFaceNormal(double *norm,double pointa[3],double pointb[3],double pointc[3]);

double Square(double num);
double EuclideanDistance(double x1, double y1, double z1, double x2, double y2, double z2);

int rand_max(int max);

void drawCube(int solid, float fSize, GLfloat pos[3]);