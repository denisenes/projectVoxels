#ifndef VOXELSWITHCUDA_GEOMETRY_CUH
#define VOXELSWITHCUDA_GEOMETRY_CUH

#include <iostream>
#include <cmath>
#include <cfloat>


class Matrix3D{
private:
    float n[3][3]{};
public:
    __host__ __device__
    Matrix3D() = default;
    __host__ __device__
    Matrix3D(float n00, float n01, float n02,
             float n10, float n11, float n12,
             float n20, float n21, float n22){
        n[0][0] = n00; n[0][1] = n10; n[0][2] = n20;
        n[1][0] = n01; n[1][1] = n11; n[1][2] = n21;
        n[2][0] = n02; n[2][1] = n12; n[2][2] = n22;
    }
    __host__ __device__
    Matrix3D(const float3& a, const float3& b, const float3& c){
        n[0][0] = a.x; n[0][1] = a.y; n[0][2] = a.z;
        n[1][0] = b.x; n[1][1] = b.y; n[1][2] = b.z;
        n[2][0] = c.x; n[2][1] = c.y; n[2][2] = c.z;
    }
    __host__ __device__
    float& operator()(int i, int j){
        return (n[i][j]);
    }
    __host__ __device__
    const float& operator()(int i, int j) const{
        return (n[i][j]);
    }
    __host__ __device__
    float3& operator[](int j){
        return (*reinterpret_cast<float3 *>(n[j]));
    }
    __host__ __device__
    const float3& operator[](int j) const{
        return (*reinterpret_cast<const float3 *>(n[j]));
    }
};




class Plane {
public:
    float x, y, z, w;
    __host__ __device__
    Plane() = default;
    __host__ __device__
    Plane(float nx, float ny, float nz, float d) {
        x = nx;
        y = ny;
        z = nz;
        w = d;
    }
    __host__ __device__
    Plane(const float3 &n, float d) {
        x = n.x;
        y = n.y;
        z = n.z;
        w = d;
    }
    __host__ __device__
    const float3& GetNormal() const {
        return (reinterpret_cast<const float3 &>(x));
    }
};




/*__device__
inline Point3D operator +(const Point3D& a, const float3& b) {
    return (Point3D(a.x + b.x, a.y + b.y, a.z + b.z));
}
__device__
inline float3 operator -(const Point3D& a, const Point3D& b) {
    return (float3(a.x - b.x, a.y - b.y, a.z - b.z));
}*/

__host__ __device__
inline uint3 operator * (const uint3 v, float s){
    return (make_uint3(v.x * s, v.y * s, v.z * s));
}
__host__ __device__
inline uchar3 operator * (const uchar3 v, float s){
    return (make_uchar3(v.x * s, v.y * s, v.z * s));
}
__host__ __device__
inline float myAbs(float a){
    return a > 0.0f ? a : -1 * a;
}
__host__ __device__
inline bool operator == (float3 v, float3 u){
    float eps = 0.0001f;
    return (myAbs(v.x - u.x) < eps) && (myAbs(v.y - u.y) < eps) && (myAbs(v.z - u.z) < eps);
}
__host__ __device__
inline float3 operator * (const float3 v, float s){
    return (make_float3(v.x * s, v.y * s, v.z * s));
}
__host__ __device__
inline float3 operator / (const float3 v, float s){
    s = 1.0f / s;
    return (make_float3(v.x * s, v.y * s, v.z * s));
}
__host__ __device__
inline float3 operator - (const float3 v){
    return (make_float3(-v.x, -v.y, -v.z));
}
__host__ __device__
inline float Magnitude(const float3 v){
    return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
}
__host__ __device__
inline float3 Normalize(const float3& v){
    return (v / Magnitude(v));
}
__host__ __device__
inline float3 operator + (const float3 a, const float3 b){
    return (make_float3(a.x+b.x, a.y+b.y, a.z+b.z));
}

__host__ __device__
inline float3 operator - (const float3 a, const float3 b){
    return (make_float3(a.x-b.x, a.y-b.y, a.z-b.z));
}
__host__ __device__
inline float Dot(const float3& a, const float3& b){
    return (a.x * b.x + a.y * b.y + a.z * b.z);
}
__host__ __device__
inline float3 Cross(const float3& a, const float3& b){
    return (make_float3(a.y * b.z - a.z * b.y,
                     a.z * b.x - a.x * b.z,
                     a.x * b.y - a.y * b.x));
}
__host__ __device__
inline float3 Project(const float3& a, const float3& b){
    return (b * (Dot(a,b) / Dot(b,b)));
}
__host__ __device__
inline float3 Reject(const float3& a, const float3& b){
    return (a - b * (Dot(a,b) / Dot(b,b)));
}

__host__ __device__
inline Matrix3D operator* (const Matrix3D& A, const Matrix3D& B) {
    return (Matrix3D(A(0, 0) * B(0, 0) + A(0, 1) * B(1, 0) + A(0, 2) * B(2, 0),
                     A(0, 0) * B(0, 1) + A(0, 1) * B(1, 1) + A(0, 2) * B(2, 1),
                     A(0, 0) * B(0, 2) + A(0, 1) * B(1, 2) + A(0, 2) * B(2, 2),
                     A(1, 0) * B(0, 0) + A(1, 1) * B(1, 0) + A(1, 2) * B(2, 0),
                     A(1, 0) * B(0, 1) + A(1, 1) * B(1, 1) + A(1, 2) * B(2, 1),
                     A(1, 0) * B(0, 2) + A(1, 1) * B(1, 2) + A(1, 2) * B(2, 2),
                     A(2, 0) * B(0, 0) + A(2, 1) * B(1, 0) + A(2, 2) * B(2, 0),
                     A(2, 0) * B(0, 1) + A(2, 1) * B(1, 1) + A(2, 2) * B(2, 1),
                     A(2, 0) * B(0, 2) + A(2, 1) * B(1, 2) + A(2, 2) * B(2, 2)));
}
__host__ __device__
inline float3 operator *(const Matrix3D& M, const float3& v) {
    return (make_float3(M(0, 0) * v.x + M(0, 1) * v.y + M(0, 2) * v.z,
                     M(1, 0) * v.x + M(1, 1) * v.y + M(1, 2) * v.z,
                     M(2, 0) * v.x + M(2, 1) * v.y + M(2, 2) * v.z));
}
__host__ __device__
inline float Determinant(const Matrix3D& M){
    return (  M(0,0) * (M(1,1) * M(2,2) - M(1,2) * M(2,1))
              + M(0,1) * (M(1,2) * M(2,0) - M(1,0) * M(2,2))
              + M(0,2) * (M(1,0) * M(2,1) - M(1,1) * M(2,0))) ;
}
__host__ __device__
inline Matrix3D Inverse(const Matrix3D& M){
    const float3& a = M[0];
    const float3& b = M[1];
    const float3& c = M[2];

    float3 r0 = Cross(b,c);
    float3 r1 = Cross(c,a);
    float3 r2 = Cross(a,b);

    float invDet = 1.0f / Dot(r2, c);

    return (Matrix3D(r0.x * invDet, r0.y * invDet, r0.z * invDet,
                     r1.x * invDet, r1.y * invDet, r1.z * invDet,
                     r2.x * invDet, r2.y * invDet, r2.z * invDet));
}
__host__ __device__
inline Matrix3D MakeRotationX(float t){
    float c = cos(t), s = sin(t);
    return (Matrix3D(1.0f, 0.0f, 0.0f,
                     0.0f,  c,  -s,
                     0.0f,  s,   c));
}
__host__ __device__
inline Matrix3D MakeRotationY(float t){
    float c = cos(t), s = sin(t);
    return (Matrix3D( c,  0.0f,  s,
                      0.0f, 1.0f, 0.0f,
                      -s,  0.0f,  c));
}
__host__ __device__
inline Matrix3D MakeRotationZ(float t){
    float c = cos(t), s = sin(t);
    return (Matrix3D( c,  -s,  0.0f,
                      s,   c,  0.0f,
                      0.0f, 0.0f,  c));
}
// rotation through the angle t about an axis a
__host__ __device__
inline Matrix3D MakeRotation(float t, const float3& a){ // a - unit vector
    float c = cos(t), s = sin(t), d = 1.0f - c;
    float x = a.x * d, y = a.y * d, z = a.z * d;
    float axay = x * a.y;
    float axaz = x * a.z;
    float ayaz = y * a.z;
    return (Matrix3D(c + x * a.x, axay - s * a.z, axaz + s * a.y,
                     axay + s * a.z, c + y * a.y, ayaz - s * a.x,
                     axaz - s * a.y, ayaz + s * a.x, c + z * a.z));
}
// reflection through the plane perpendicular to unit vector a
__host__ __device__
inline Matrix3D MakeReflection(const float3& a) {
    float x = a.x * -2.0f;
    float y = a.y * -2.0f;
    float z = a.z * -2.0f;
    float axay = x * a.y;
    float axaz = x * a.z;
    float ayaz = y * a.z;
    return (Matrix3D(x * a.x + 1.0f, axay, axaz,
                     axay, y * a.y + 1.0f, ayaz,
                     axaz, ayaz, z * a.z + 1.0f));
}
__host__ __device__
inline Matrix3D MakeScale(float sx, float sy, float sz){
    return (Matrix3D( sx, 0.0f, 0.0f,
                      0.0f,  sy, 0.0f,
                      0.0f, 0.0f,  sz));
}
// a scale by a factor of s along a unit direction a
__host__ __device__
inline Matrix3D MakeScale(float s, const float3& a) {
    s -= 1.0f;
    float x = a.x * s;
    float y = a.y * s;
    float z = a.z * s;
    float axay = x * a.y;
    float axaz = x * a.z;
    float ayaz = y * a.z;
    return (Matrix3D(x * a.x + 1.0f, axay, axaz,
                     axay, y * a.y + 1.0f, ayaz,
                     axaz, ayaz, z * a.z + 1.0f));
}
// calculates the distance between the point q and the line determined by the point p and the direction v
/*__device__
double DistPointLine(const Point3D& q, const Point3D& p, const float3& v){
    float3 a = Cross(q - p, v);
    return (sqrt(Dot(a,a) / Dot(v,v)));
}*/
// calculates the distance between two lines determined by the points p1 and p2 and the directions v1 and v2
/*__device__
double DistLineLine(const Point3D& p1, const float3& v1,
                    const Point3D& p2, const float3& v2){
    float3 dp = p2 - p1;
    float v12 = Dot(v1,v1), v22 = Dot(v2,v2), v1v2 = Dot(v1,v2);
    float det = v1v2 * v1v2 - v12 * v22;
    if(fMyAbs(det) > FLT_MIN){
        det = 1.0 / det;
        float dpvl = Dot(dp, v1);
        float dpv2 = Dot(dp, v2);
        float t1 = (v1v2 * dpv2 - v22 * dpvl) * det;
        float t2 = (v12 * dpv2 - v1v2 * dpvl) * det;
        return (Magnitude(dp + v2 * t2 - v1 * t1) );
    }
    // The lines are nearly parallel.
    float3 a = Cross(dp, v1);
    return (sqrt(Dot(a, a) / v12));
}*/

__host__ __device__
inline float Dot(const Plane& f, const float3& v) {
    return (f.x * v.x + f.y * v.y + f.z * v.z);
}
/*__device__
double Dot(const Plane& f, const Point3D& p) {
    return (f.x * p.x + f.y * p.y + f.z * p.z + f.w);
}*/
/*__device__
float IntersectLinePlane(const Point3D& p, const float3& v,
                         const Plane& f, Point3D *q){
    float fv = Dot(f, v);
    if (fMyAbs(fv) > FLT_MIN){
        (*q) = p + (- v * (Dot(f, p) / fv));
        return true;
    }
    return false;
}*/

#endif //VOXELSWITHCUDA_GEOMETRY_CUH
