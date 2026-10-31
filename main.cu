#include <iostream>
#include <SFML/Graphics.hpp>
#include <SFML/OpenGL.hpp>
#include <SFML/Window.hpp>
#include "geometry.cuh"
#include "voxel.cuh"
#include <vector>
#include <fstream>

/*
#ifdef _WIN32
#include <GL/gl.h>
#include <GL/glu.h>
#endif

typedef union PixelInfo
{
    std::uint32_t Colour;
    struct
    {
        std::uint8_t R, G, B, A;
    };
} *PPixelInfo;

class Tga
{
private:
    std::vector<std::uint8_t> Pixels;
    bool ImageCompressed;
    std::uint32_t width, height, size, BitsPerPixel;

public:
    Tga(const char* FilePath);
    std::vector<std::uint8_t> GetPixels() {return this->Pixels;}
    std::uint32_t GetWidth() const {return this->width;}
    std::uint32_t GetHeight() const {return this->height;}
    bool HasAlphaChannel() {return BitsPerPixel == 32;}
};

Tga::Tga(const char* FilePath)
{
    std::fstream hFile(FilePath, std::ios::in | std::ios::binary);
    if (!hFile.is_open()){throw std::invalid_argument("File Not Found.");}

    std::uint8_t Header[18] = {0};
    std::vector<std::uint8_t> ImageData;
    static std::uint8_t DeCompressed[12] = {0x0, 0x0, 0x2, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};
    static std::uint8_t IsCompressed[12] = {0x0, 0x0, 0xA, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};

    hFile.read(reinterpret_cast<char*>(&Header), sizeof(Header));

    if (!std::memcmp(DeCompressed, &Header, sizeof(DeCompressed)))
    {
        BitsPerPixel = Header[16];
        width  = Header[13] * 256 + Header[12];
        height = Header[15] * 256 + Header[14];
        size  = ((width * BitsPerPixel + 31) / 32) * 4 * height;

        if ((BitsPerPixel != 24) && (BitsPerPixel != 32))
        {
            hFile.close();
            throw std::invalid_argument("Invalid File Format. Required: 24 or 32 Bit Image.");
        }

        ImageData.resize(size);
        ImageCompressed = false;
        hFile.read(reinterpret_cast<char*>(ImageData.data()), size);
    }
    else if (!std::memcmp(IsCompressed, &Header, sizeof(IsCompressed)))
    {
        BitsPerPixel = Header[16];
        width  = Header[13] * 256 + Header[12];
        height = Header[15] * 256 + Header[14];
        size  = ((width * BitsPerPixel + 31) / 32) * 4 * height;

        if ((BitsPerPixel != 24) && (BitsPerPixel != 32))
        {
            hFile.close();
            throw std::invalid_argument("Invalid File Format. Required: 24 or 32 Bit Image.");
        }

        PixelInfo Pixel = {0};
        int CurrentByte = 0;
        std::size_t CurrentPixel = 0;
        ImageCompressed = true;
        std::uint8_t ChunkHeader = {0};
        int BytesPerPixel = (BitsPerPixel / 8);
        ImageData.resize(width * height * sizeof(PixelInfo));

        do
        {
            hFile.read(reinterpret_cast<char*>(&ChunkHeader), sizeof(ChunkHeader));

            if(ChunkHeader < 128)
            {
                ++ChunkHeader;
                for(int I = 0; I < ChunkHeader; ++I, ++CurrentPixel)
                {
                    hFile.read(reinterpret_cast<char*>(&Pixel), BytesPerPixel);

                    ImageData[CurrentByte++] = Pixel.B;
                    ImageData[CurrentByte++] = Pixel.G;
                    ImageData[CurrentByte++] = Pixel.R;
                    if (BitsPerPixel > 24) ImageData[CurrentByte++] = Pixel.A;
                }
            }
            else
            {
                ChunkHeader -= 127;
                hFile.read(reinterpret_cast<char*>(&Pixel), BytesPerPixel);

                for(int I = 0; I < ChunkHeader; ++I, ++CurrentPixel)
                {
                    ImageData[CurrentByte++] = Pixel.B;
                    ImageData[CurrentByte++] = Pixel.G;
                    ImageData[CurrentByte++] = Pixel.R;
                    if (BitsPerPixel > 24) ImageData[CurrentByte++] = Pixel.A;
                }
            }
        } while(CurrentPixel < (width * height));
    }
    else
    {
        hFile.close();
        throw std::invalid_argument("Invalid File Format. Required: 24 or 32 Bit TGA File.");
    }

    hFile.close();
    this->Pixels = ImageData;
}
*/


// TODO нормальные __host__ __device__
// TODO сделать класс углов || взять из готовой (cuBLAS??)
// TODO текстуры + шрифт
// TODO нормальная либа векторов
// TODO переписать сообщения об ошибках на cuda error


#ifndef M_PI
#define M_PI 3.1415
#endif
#define MAP_SIZE 200


#define distToViewPort 1.0
#define Vh 1.0
#define Vw 1.0

#define imageHeight 1024
#define imageWidth 1024

#define crossSize 64
#define BOX_SIZE 4

/* mouse look sensitivity, degrees per pixel (tunable at runtime with + / -) */
#define MOUSE_SENSITIVITY 0.05

#define MAX_FRAMES 1000
//#define DEBUG



struct Camera {
public:
    Camera() = default;

    float3 eyePosition;
    float angleX, angleY;
    float speed;

    Camera(float3 &eye, float xAng, float yAng) :
            angleX(xAng), angleY(yAng), eyePosition(eye), speed(0.3f) {}
};

struct Ray {
public:
    float3 source;
    float3 direction;
};

/* camera ray basis, computed once per frame on the host */
struct RayBasis {
    float3 eye;
    float3 origin;
    float3 right;
    float3 down;
};

class Box {
public:
    __host__ __device__
    Box() = default;

    __host__ __device__
    Box(int X, int Y, int Z) : x(X), y(Y), z(Z) {}

    __host__ __device__
    bool intersect(const Ray &, float t0, float t1, float3 &inter1Point, float3 &inter2Point) const;

    __host__ __device__
    void inc_x() {
        x++;
    }

    __host__ __device__
    void inc_y() {
        y++;
    }

    __host__ __device__
    void inc_z() {
        z++;
    }

    __host__ __device__
    void dec_x() {
        x--;
    }

    __host__ __device__
    void dec_y() {
        y--;
    }

    __host__ __device__
    void dec_z() {
        z--;
    }

    __host__ __device__
    int get_x() const { return x; }

    __host__ __device__
    int get_y() const { return y; }

    __host__ __device__
    int get_z() const { return z; }

    /* minimum corner of the box in world coordinates */
    __host__ __device__
    float3 get_min() const {
        return make_float3(x * BOX_SIZE, y * BOX_SIZE, z * BOX_SIZE);
    }

private:
    int x, y, z;
};

// ищет пересечение луча и коробки, записывает точки в interPoint
__host__ __device__
bool Box::intersect(const Ray &r, float t0, float t1, float3 &inter1Point, float3 &inter2Point) const {
    float3 b0 = get_min();
    float3 b1 = b0 + make_float3(BOX_SIZE, BOX_SIZE, BOX_SIZE);
    float tmin, tmax, tymin, tymax, tzmin, tzmax;
    if (r.direction.x >= 0) {
        tmin = (b0.x - r.source.x) / r.direction.x;
        tmax = (b1.x - r.source.x) / r.direction.x;
    } else {
        tmin = (b1.x - r.source.x) / r.direction.x;
        tmax = (b0.x - r.source.x) / r.direction.x;
    }
    if (r.direction.y >= 0) {
        tymin = (b0.y - r.source.y) / r.direction.y;
        tymax = (b1.y - r.source.y) / r.direction.y;
    } else {
        tymin = (b1.y - r.source.y) / r.direction.y;
        tymax = (b0.y - r.source.y) / r.direction.y;
    }
    if ((tmin > tymax) || (tymin > tmax))
        return false;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    if (r.direction.z >= 0) {
        tzmin = (b0.z - r.source.z) / r.direction.z;
        tzmax = (b1.z - r.source.z) / r.direction.z;
    } else {
        tzmin = (b1.z - r.source.z) / r.direction.z;
        tzmax = (b0.z - r.source.z) / r.direction.z;
    }
    if ((tmin > tzmax) || (tzmin > tmax))
        return false;
    if (tzmin > tmin)
        tmin = tzmin;
    if (tzmax < tmax)
        tmax = tzmax;
    if (((tmin < t1) && (tmax > t0))) {
        inter1Point = r.source + r.direction * tmin;
        inter2Point = r.source + r.direction * tmax;
        return true;
    }
    return false;
}

__host__ __device__
void buildDirectionOfStraightMove(Camera *cam, float3 *move) {
    float3 origin = make_float3(0.f, 0.f, 1.f);
    float3 xRotated = MakeRotationY((cam->angleX) * (float)M_PI / 180.f) * make_float3(1.0f, 0.0f, 0.0f);
    float3 result = MakeRotationY((cam->angleX) * (float)M_PI / 180.f) * origin;
    result = MakeRotation(-cam->angleY * (float)M_PI / 180.f, xRotated) * result;
    *move = result;
}

__host__ __device__
void buildDirectionOfNotSoStraightMove(Camera *cam, float3 *move) {
    float3 origin = make_float3(0.f, 0.f, 1.f);
    float3 xRotated = MakeRotationY((cam->angleX) * (float)M_PI / 180.f) * make_float3(1.0f, 0.0f, 0.0f);
    float3 result = MakeRotationY((cam->angleX) * (float)M_PI / 180.f) * origin;
    result = MakeRotation(-cam->angleY * (float)M_PI / 180.f, xRotated) * result;
    float3 viewDirection = result;
    float3 y = make_float3(0.f, 1.f, 0.f);
    *move = Cross(viewDirection, y);
}

__host__ __device__
RayBasis makeRayBasis(const Camera *cam) {
    /* NOTE: rotations must be applied sequentially — Matrix3D::operator*(A,B)
     * composes in the reverse order here, so the old "apply A then B" semantics
     * cannot be expressed as a matrix product. */
    Matrix3D rotY = MakeRotationY((cam->angleX) * (float)M_PI / 180.f);
    float3 xRotated = rotY * make_float3(1.0f, 0.0f, 0.0f);
    Matrix3D rot = MakeRotation(-cam->angleY * (float)M_PI / 180.f, xRotated);
    RayBasis basis;
    basis.eye = cam->eyePosition;
    basis.origin = rot * (rotY * make_float3(-Vw / 2.f, -Vh / 2.f, distToViewPort));
    basis.right = rot * (rotY * make_float3(Vw, 0.f, 0.f));
    basis.down = rot * (rotY * make_float3(0.f, Vh, 0.f));
    return basis;
}

__host__ __device__
Ray computePrimRay(const RayBasis &basis, const int i, const int j) {
    Ray ray;
    ray.source = basis.eye;
    ray.direction = basis.origin
                    + basis.right * (static_cast<float>(j) / imageWidth)
                    + basis.down * (static_cast<float>(i) / imageHeight);
    return ray;
}


__host__ __device__
bool checkWorld(Box *box, voxel* world) {
    if (box->get_x() < 0 || box->get_y() < 0 || box->get_z() < 0 || box->get_x() >= MAP_SIZE ||
        box->get_y() >= MAP_SIZE || box->get_z() >= MAP_SIZE)
        return 0;
    return world[box->get_x() * MAP_SIZE * MAP_SIZE + box->get_y() * MAP_SIZE + box->get_z()].isActive();
}


/* (x, y, z) - индексы текущего бокса в world */
__device__
float3 traverseRay(int startX, int startY, int startZ, Ray &ray, int deep, voxel* world, Box *lastBox,
                   int *hitAxis = nullptr) {
    Box currentBox = Box(startX, startY, startZ);
    float3 deltaT;
    float t_x, t_y, t_z;

    if (ray.direction.x < 0) {
        deltaT.x = -BOX_SIZE / ray.direction.x;
        t_x = (floor(ray.source.x / BOX_SIZE) * BOX_SIZE
               - ray.source.x) / ray.direction.x;
    }
    else {
        deltaT.x = BOX_SIZE / ray.direction.x;
        t_x = ((floor(ray.source.x / BOX_SIZE) + 1) * BOX_SIZE
               - ray.source.x) / ray.direction.x;
    }

    if (ray.direction.y < 0) {
        deltaT.y = -BOX_SIZE / ray.direction.y;
        t_y = (floor(ray.source.y / BOX_SIZE) * BOX_SIZE
               - ray.source.y) / ray.direction.y;
    }
    else {
        deltaT.y = BOX_SIZE / ray.direction.y;
        t_y = ((floor(ray.source.y / BOX_SIZE) + 1) * BOX_SIZE
               - ray.source.y) / ray.direction.y;
    }

    if (ray.direction.z < 0) {
        deltaT.z = -BOX_SIZE / ray.direction.z;
        t_z = (floor(ray.source.z / BOX_SIZE) * BOX_SIZE
               - ray.source.z) / ray.direction.z;
    }
    else {
        deltaT.z = BOX_SIZE / ray.direction.z;
        t_z = ((floor(ray.source.z / BOX_SIZE) + 1) * BOX_SIZE
               - ray.source.z) / ray.direction.z;
    }
    while (true) {
        if (currentBox.get_x() < 0 || currentBox.get_y() < 0 || currentBox.get_z() < 0 ||
            currentBox.get_x() >= MAP_SIZE || currentBox.get_y() >= MAP_SIZE || currentBox.get_z() >= MAP_SIZE /*||
            deep > MAP_SIZE * 2*/) {
            *lastBox = Box(-1, -1, -1);
            return make_float3(-1.f, -1.f, -1.f);
        }
        float t = 0.;
        int axis = 0;

        if (t_x < t_y) {
            if (t_x < t_z) {
                t = t_x;
                t_x += deltaT.x; // increment, next crossing along x
                axis = 0;
                if(ray.direction.x < 0)
                    currentBox.dec_x();
                else
                    currentBox.inc_x();
            }
            else {
                t = t_z;
                t_z += deltaT.z; // increment, next crossing along z
                axis = 2;
                if(ray.direction.z < 0)
                    currentBox.dec_z();
                else
                    currentBox.inc_z();
            }
        }
        else {
            if (t_y < t_z) {
                t = t_y;
                t_y += deltaT.y; // increment, next crossing along y
                axis = 1;
                if(ray.direction.y < 0)
                    currentBox.dec_y();
                else
                    currentBox.inc_y();
            }
            else {
                t = t_z;
                t_z += deltaT.z; // increment, next crossing along z
                axis = 2;
                if(ray.direction.z < 0)
                    currentBox.dec_z();
                else
                    currentBox.inc_z();
            }
        }
        if (checkWorld(&currentBox, world)) {
            *lastBox = currentBox;
            if (hitAxis)
                *hitAxis = axis;
            return ray.source + ray.direction * t;
        }
        deep++;
    }
}

/* копипаста траверс_рея для удаления блоков*/
__host__ __device__
bool
hitRay(int startX, int startY, int startZ, Ray &ray, int deep, Box &boxToDelete, Box &boxToAdd, voxel* world) {
    /* float precision: hit points live at world scale (~800), so face detection
     * cannot use a tighter epsilon than ~1e-3 of a box (BOX_SIZE = 4) */
    const float eps = 0.001f;
    Box currentBox = Box(startX, startY, startZ);
    while (true) {
        if (currentBox.get_x() < 0 || currentBox.get_y() < 0 || currentBox.get_z() < 0 ||
            currentBox.get_x() >= MAP_SIZE || currentBox.get_y() >= MAP_SIZE || currentBox.get_z() >= MAP_SIZE ||
            deep > 150)
            return false;
        /* A1 < A2 : точки пересечения луча и бокса */
        float3 A1 = make_float3(0.f, 0.f, 0.f), A2 = make_float3(0.f, 0.f, 0.f);
        if (currentBox.intersect(ray, 0, INFINITY, A1, A2)) {
            boxToAdd = currentBox;
            float3 A2_normalized = A2 - currentBox.get_min();
            if (myAbs(A2_normalized.x) < eps)
                currentBox.dec_x();
            if (myAbs(A2_normalized.y) < eps)
                currentBox.dec_y();
            if (myAbs(A2_normalized.z) < eps)
                currentBox.dec_z();
            if (myAbs(A2_normalized.x - BOX_SIZE) < eps)
                currentBox.inc_x();
            if (myAbs(A2_normalized.y - BOX_SIZE) < eps)
                currentBox.inc_y();
            if (myAbs(A2_normalized.z - BOX_SIZE) < eps)
                currentBox.inc_z();
            if (checkWorld(&currentBox, world)) {
                boxToDelete = currentBox;
                return true;
            }
        }
        deep++;
    }

}

// TODO нужно ли делать это в хосте?
__host__ __device__
void deleteVoxel(Camera *cam, voxel* world) {
    RayBasis basis = makeRayBasis(cam);
    Ray hit = computePrimRay(basis, imageWidth / 2, imageHeight / 2);
    Box boxToDelete = Box(0, 0, 0), boxToAdd = Box(0, 0, 0);
    if (hitRay(static_cast<int>(cam->eyePosition.x / BOX_SIZE),
               static_cast<int>(cam->eyePosition.y / BOX_SIZE),
               static_cast<int>(cam->eyePosition.z / BOX_SIZE),
               hit, 5, boxToDelete, boxToAdd, world)) {
        int dx[] = { 1, 0, -1, 0, 0, 0};
        int dy[] = { 0, 1, 0, -1, 0, 0 };
        int dz[] = { 0, 0, 0, 0, 1, -1 };
        for (int i = 0; i < 6; i++) {
            int nx = boxToDelete.get_x() + dx[i];
            int ny = boxToDelete.get_y() + dy[i];
            int nz = boxToDelete.get_z() + dz[i];
            if (nx < 0 || ny < 0 || nz < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE || nz >= MAP_SIZE)
                continue;
            world[nx * MAP_SIZE * MAP_SIZE + ny * MAP_SIZE + nz].setInactive();
        }
        world[boxToDelete.get_x() * MAP_SIZE * MAP_SIZE + boxToDelete.get_y() * MAP_SIZE + boxToDelete.get_z()].setInactive();
    }

}

__host__ __device__
void addVoxel(Camera *cam, voxel* world) {
    RayBasis basis = makeRayBasis(cam);
    Ray hit = computePrimRay(basis, imageWidth / 2, imageHeight / 2);
    Box boxToAdd = Box(0, 0, 0), boxToDelete = Box(0, 0, 0);
    if (hitRay(static_cast<int>(cam->eyePosition.x / BOX_SIZE),
               static_cast<int>(cam->eyePosition.y / BOX_SIZE),
               static_cast<int>(cam->eyePosition.z / BOX_SIZE),
               hit, 5, boxToDelete, boxToAdd, world)) {
        world[boxToAdd.get_x() * MAP_SIZE * MAP_SIZE + boxToAdd.get_y() * MAP_SIZE + boxToAdd.get_z()].setActive();
    }
}



__global__
void traversePixels(uchar4 *screen, RayBasis basis, voxel* world, float3 lightSource) {
    float eps = 0.0000001f;

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    int idx = j + i * blockDim.x * gridDim.x;

    uchar3 color;

    Ray primRay = computePrimRay(basis, i, j);
    Box currBox = Box();
    int hitAxis = -1;
    float3 firstHitDot = traverseRay((static_cast<int>(basis.eye.x / BOX_SIZE)),
                                     (static_cast<int>(basis.eye.y / BOX_SIZE)),
                                     (static_cast<int>(basis.eye.z / BOX_SIZE)), primRay, 0, world, &currBox, &hitAxis);
    float3 emptyConst = make_float3(-1.f, -1.f, -1.f);
    if (firstHitDot == emptyConst) {
        /** мы не коснулись ничего = небо */
        color = make_uchar3(21, 4, 133);
    } else if (checkWorld(&currBox, world) == 1) {
        int hitX = currBox.get_x(), hitY = currBox.get_y(), hitZ = currBox.get_z();
        color = world[hitX * MAP_SIZE * MAP_SIZE + hitY * MAP_SIZE + hitZ].color;
        Ray shadowRay;
        shadowRay.source = lightSource;
        shadowRay.direction = firstHitDot - lightSource;
        Box shadowBox = Box();
        traverseRay((static_cast<int>(lightSource.x / BOX_SIZE)),
                    (static_cast<int>(lightSource.y / BOX_SIZE)),
                    (static_cast<int>(lightSource.z / BOX_SIZE)), shadowRay, 0, world, &shadowBox);
        if (shadowBox.get_x() != hitX || shadowBox.get_y() != hitY || shadowBox.get_z() != hitZ) {
            /** случай когда точка падения полностью в тени */
            color = color * 0.2f;
        } else {
            /** случай когда свет дошел до точки */
            /** нормаль наружу через грань, через которую луч вошел в воксель */
            float3 normal = make_float3(0.f, 0.f, 0.f);
            if (hitAxis == 0) normal.x = (primRay.direction.x > 0.f) ? -1.f : 1.f;
            if (hitAxis == 1) normal.y = (primRay.direction.y > 0.f) ? -1.f : 1.f;
            if (hitAxis == 2) normal.z = (primRay.direction.z > 0.f) ? -1.f : 1.f;

            float lightIntensity = 0.2f;
            float cosx = Dot(normal, shadowRay.direction * -1.f) / Magnitude(normal) / Magnitude(shadowRay.direction);

            if (cosx >= eps)
                lightIntensity += cosx;

            if (lightIntensity > 1.f)
                lightIntensity = 1.0f;
            color = color * lightIntensity;
        }
    } else {
        /** куб Валера */
        color = make_uchar3(255, 255, 255);
    }
    screen[idx] = make_uchar4(static_cast<unsigned char>(color.x),
                              static_cast<unsigned char>(color.y),
                              static_cast<unsigned char>(color.z),
                              255);
}
/*
std::chrono::milliseconds start_time;
__host__ __device__
void generateMap(unsigned int *world) {
    static double t1 = 0.001, t2 = 0.001;
    std::chrono::milliseconds ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
    ) - start_time;
    double delta = M_PI;
    int x1 = static_cast<int>(10*cos(t1)) + MAP_SIZE / 2;
    int z1 = static_cast<int>(10*sin(t1)) + MAP_SIZE / 2;
    int y1 = static_cast<int>(t1*3.) + BOX_SIZE * 2;
    int x2 = static_cast<int>(10*cos(-t2-delta)) + MAP_SIZE / 2;
    int z2 = static_cast<int>(10*sin(-t2-delta)) + MAP_SIZE / 2;
    int y2 = static_cast<int>(t2*5.) + BOX_SIZE * 2;
    if((x1 >= MAP_SIZE || y1 >= MAP_SIZE || z1 >= MAP_SIZE) || (x2 >= MAP_SIZE || y2 >= MAP_SIZE || z2 >= MAP_SIZE))
        return;
    int idx = x1 * MAP_SIZE * MAP_SIZE + y1 * MAP_SIZE + z1;
    world[idx] = 1;
    idx = x2 * MAP_SIZE * MAP_SIZE + y2 * MAP_SIZE + z2;
    if(t1 > delta) {
        world[idx] = 1;
        t2 += 0.05;
    }
    t1 += 0.05;
    //for (int i = 0; i < MAP_SIZE * MAP_SIZE * MAP_SIZE; i++)
    //    world[i] = (rand() % 1000 == 0);

}
*/
bool bounds(float3 pos) {
    if (pos.x >= (MAP_SIZE - 1) * BOX_SIZE || pos.y >= (MAP_SIZE - 1) * BOX_SIZE ||
        pos.z >= ((MAP_SIZE - 1) * BOX_SIZE) || pos.x <= 0 || pos.y <= 0 || pos.z <= 0)
        return false;
    return true;
}

void printDebug(Camera *cam) {
    printf("angleX: %f\n", cam->angleX);
    printf("angleY: %f\n", cam->angleY);
    printf("eyePosition: (%f, %f, %f)\n", cam->eyePosition.x, cam->eyePosition.y, cam->eyePosition.z);
}

int main() {

    /*
    Tga info = Tga("C:/Users/...../Desktop/SomeTGA.tga");

    GLuint texture = 0;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, info.HasAlphaChannel() ? GL_RGBA : GL_RGB, info.GetWidth(), info.GetWidth(), 0, info.HasAlphaChannel() ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, info.GetPixels().data());

    */
    int frames = 0;
    float sumScreenRenderTime = 0.0;

    voxel *world;
    uchar4 *screen;
    if (cudaMallocManaged(&world, MAP_SIZE * MAP_SIZE * MAP_SIZE * sizeof(world[0]))) {
        fprintf(stderr, "cuda malloc error: world\n");
        return 1;
    }
    if (cudaMallocManaged(&screen, imageHeight * imageWidth * sizeof(uchar4))) {
        fprintf(stderr, "cuda malloc error: screen\n");
        return 1;
    }
    /* managed memory is not guaranteed zeroed; every voxel's flags must start defined */
    cudaMemset(world, 0, MAP_SIZE * MAP_SIZE * MAP_SIZE * sizeof(world[0]));
    Camera camObj; // host-only now: the kernel takes a RayBasis by value
    Camera *cam = &camObj;
    float3 light;
    uint3 localLight = make_uint3(MAP_SIZE / 2, 15, MAP_SIZE / 2);
    auto *hostScreen = static_cast<uchar4 *>(malloc(imageHeight * imageWidth * sizeof(uchar4)));
    if (!hostScreen) {
        fprintf(stderr, "malloc error: hostScreen\n");
        return 1;
    }

    int blocksCnt = 0;
    for (int i = 0; i < MAP_SIZE * MAP_SIZE * MAP_SIZE; i++) {
        int x, y, z;
        x = i / MAP_SIZE / MAP_SIZE;
        y = i / MAP_SIZE % MAP_SIZE;
        z = i % MAP_SIZE;
        int R = 35;
        if ((x - MAP_SIZE / 2) * (x - MAP_SIZE / 2) + (y - (MAP_SIZE - 2 * R)) * (y - (MAP_SIZE - 2 * R)) + (z - MAP_SIZE / 2) * (z - MAP_SIZE / 2) <= R * R) {
            world[i].setActive();
            world[i].setColor(rand()%256, rand()%256, rand()%256);
        }
        if (y == MAP_SIZE - 10) {
            world[i].setActive();
            world[i].setColor(0, 255, 0);
        }
        blocksCnt += world[i].isActive();
    }
    cudaDeviceSynchronize();
    printf("Num of voxels: %d\n", blocksCnt);
    float3 eyePosition = make_float3(64.636510f, 1.0f, 294.136342f);
    cam->eyePosition = eyePosition;
    cam->angleX = 234.833333f;
    cam->angleY = -28.666667f;
    cam->speed = 5.0f;


    sf::Color backgroundColor = sf::Color::Black;
    sf::RenderWindow window(sf::VideoMode(imageHeight, imageWidth), "lol");
    window.setMouseCursorVisible(false);
    window.setMouseCursorGrabbed(true);
    const sf::Vector2i mouseCenter(imageWidth / 2, imageHeight / 2);
    sf::Mouse::setPosition(mouseCenter, window);
    /* classic delta-based mouse look state: rotation follows real mouse motion
     * (MouseMoved event deltas) instead of the offset from the window center */
    sf::Vector2i lastMousePos = mouseCenter;
    sf::Vector2i mouseDelta(0, 0);
    bool warpPending = false;
    sf::Texture pixelsTexture;
    if (!pixelsTexture.create(imageWidth, imageHeight)) {
        fprintf(stderr, "sf::Texture::create error\n");
        return 1;
    }
    sf::Sprite pixels;
    pixels.setTexture(pixelsTexture);

    bool drawCross = true;
    double mouseSensitivity = MOUSE_SENSITIVITY;
    sf::Texture crossTexture;
    if (!crossTexture.loadFromFile("cross.png", sf::IntRect(0, 0, crossSize, crossSize))) {
        fprintf(stderr, "Error loading cross.jpg\n");
    }
    sf::Sprite crossSprite;
    crossSprite.setTexture(crossTexture);
    crossSprite.setPosition(imageWidth / 2. - crossSize / 2., imageHeight / 2. - crossSize / 2.);

    float3 moveStraight;
    float3 moveNotStraight;

    double t = 0.0;
    localLight.x = static_cast<int>(10 * cos(t)) + MAP_SIZE / 2;
    localLight.y = static_cast<int>(10 * sin(t)) + MAP_SIZE / 2;
    localLight.z = 10;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    while (window.isOpen()) {



        world[localLight.x * MAP_SIZE * MAP_SIZE + localLight.y * MAP_SIZE + localLight.z].setInactive();

        localLight.x = static_cast<int>(40 * cos(t)) + MAP_SIZE / 2;
        localLight.y = static_cast<int>(40 * sin(t)) + MAP_SIZE / 2;

        localLight.z = 10;
        t += 0.05;

        light.x = localLight.x * BOX_SIZE + BOX_SIZE / 2.f;
        light.y = localLight.y * BOX_SIZE + BOX_SIZE / 2.f;
        light.z = localLight.z * BOX_SIZE + BOX_SIZE / 2.f;

        world[localLight.x * MAP_SIZE * MAP_SIZE +
            localLight.y * MAP_SIZE +
            localLight.z].setLight();

        dim3 threads(16,16);
        dim3 blocks(imageWidth/threads.x,imageHeight/threads.y);




        traversePixels<<<blocks, threads>>>(screen, makeRayBasis(cam), world, light);
        //cudaDeviceSynchronize();

        cudaEventRecord(start);

        cudaMemcpy(hostScreen, screen, imageHeight * imageWidth * sizeof(uchar4), cudaMemcpyDeviceToHost);
        pixelsTexture.update(reinterpret_cast<const sf::Uint8 *>(hostScreen));

        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        float milliseconds = 0;
        cudaEventElapsedTime(&milliseconds, start, stop);
        sumScreenRenderTime += milliseconds;
        frames++;

        sf::Event event{};
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
            if (event.type == sf::Event::MouseMoved) {
                sf::Vector2i pos(event.mouseMove.x, event.mouseMove.y);
                if (warpPending && pos == mouseCenter) {
                    /* synthetic re-centering event, not real motion */
                    warpPending = false;
                } else {
                    mouseDelta += lastMousePos - pos;
                    lastMousePos = pos;
                }
            }
            if (event.type == sf::Event::KeyPressed) {
                if (event.key.code == sf::Keyboard::Escape)
                    window.close();
                if (event.key.code == sf::Keyboard::V)
                    drawCross = !drawCross;
                if (event.key.code == sf::Keyboard::I)
                    printDebug(cam);
                if (event.key.code == sf::Keyboard::Up) {
                    cam->speed++;
                }
                if (event.key.code == sf::Keyboard::Down) {
                    cam->speed--;
                }
                if (event.key.code == sf::Keyboard::Equal || event.key.code == sf::Keyboard::Add) {
                    mouseSensitivity *= 1.25;
                    fprintf(stderr, "mouse sensitivity: %f deg/px\n", mouseSensitivity);
                }
                if (event.key.code == sf::Keyboard::Hyphen || event.key.code == sf::Keyboard::Subtract) {
                    mouseSensitivity /= 1.25;
                    fprintf(stderr, "mouse sensitivity: %f deg/px\n", mouseSensitivity);
                }

            }
            /*if (event.type == sf::Event::MouseButtonPressed){
                if (event.mouseButton.button == sf::Mouse::Left)
                    deleteVoxel(cam, world);
                if (event.mouseButton.button == sf::Mouse::Right)
                    addVoxel(cam, world);
            }*/
        }

        if (sf::Mouse::isButtonPressed(sf::Mouse::Left)) {
            deleteVoxel(cam, world);
        }
        if (sf::Mouse::isButtonPressed(sf::Mouse::Right)) {
            addVoxel(cam, world);
        }
        /* apply accumulated motion; the sign matches the old center-offset formula */
        cam->angleX += mouseDelta.x * mouseSensitivity;
        cam->angleY += mouseDelta.y * mouseSensitivity;
        mouseDelta = sf::Vector2i(0, 0);
        /* keep the pointer near the center so it can't hit the window edge */
        sf::Mouse::setPosition(mouseCenter, window);
        lastMousePos = mouseCenter;
        warpPending = true;
        if (cam->angleY > 89.)
            cam->angleY = 89.;
        if (cam->angleY < -89.)
            cam->angleY = -89.;

        buildDirectionOfStraightMove(cam, &moveStraight);
        buildDirectionOfNotSoStraightMove(cam, &moveNotStraight);
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::W))
            if (bounds(cam->eyePosition + Normalize(moveStraight) * cam->speed))
                cam->eyePosition = cam->eyePosition + Normalize(moveStraight) * cam->speed;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::S))
            if (bounds(cam->eyePosition - Normalize(moveStraight) * cam->speed))
                cam->eyePosition = cam->eyePosition - Normalize(moveStraight) * cam->speed;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::A))
            if (bounds(cam->eyePosition + Normalize(moveNotStraight) * cam->speed))
                cam->eyePosition = cam->eyePosition + Normalize(moveNotStraight) * cam->speed;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::D))
            if (bounds(cam->eyePosition - Normalize(moveNotStraight) * cam->speed))
                cam->eyePosition = cam->eyePosition - Normalize(moveNotStraight) * cam->speed;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::LShift))
            if (bounds(cam->eyePosition + make_float3(0.f, cam->speed, 0.f)))
                cam->eyePosition.y += cam->speed;
        if (sf::Keyboard::isKeyPressed(sf::Keyboard::Space))
            if (bounds(cam->eyePosition - make_float3(0.f, cam->speed, 0.f)))
                cam->eyePosition.y -= cam->speed;
        window.clear(sf::Color::Magenta);
        window.draw(pixels);
        if (drawCross)
            window.draw(crossSprite);
        window.display();
    }
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(world);
    cudaFree(screen);
    free(hostScreen);
    std::cout << "frames: " << frames << std::endl;
    std::cout << "sumScreenRenderTime: " << sumScreenRenderTime << " ms, avg: "
              << (frames ? sumScreenRenderTime / frames : 0.f) << " ms/frame" << std::endl;

    return 0;
}
