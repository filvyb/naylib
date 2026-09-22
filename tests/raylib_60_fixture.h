#include "raylib.h"
#include <string.h>

static int TestMeshVertexBuffers(void)
{
#if SUPPORT_GPU_SKINNING
    return 9;
#else
    return 7;
#endif
}

static Mesh *TestMesh(void)
{
    static unsigned char indices[4] = { 1, 2, 3, 4 };
    static Mesh mesh = { 0 };
    mesh.vertexCount = 1;
    mesh.boneCount = 5;
    mesh.boneIndices = indices;
    return &mesh;
}

// Allocate through raylib so the Nim destructors exercise the real ownership API.
static Transform TestPose(float x)
{
    Transform pose = { 0 };
    pose.translation.x = x;
    pose.rotation.w = 1.0f;
    pose.scale = (Vector3){ 1.0f, 1.0f, 1.0f };
    return pose;
}

static ModelAnimation TestAnimation(void)
{
    ModelAnimation anim = { 0 };
    anim.boneCount = 1;
    anim.keyframeCount = 2;
    anim.keyframePoses = MemAlloc(2*sizeof(ModelAnimPose));
    for (int i = 0; i < 2; i++)
    {
        anim.keyframePoses[i] = MemAlloc(sizeof(Transform));
        anim.keyframePoses[i][0] = TestPose(2.0f*i);
    }
    return anim;
}

static Model TestModel(void)
{
    Model model = { 0 };
    model.skeleton.boneCount = 1;
    model.skeleton.bones = MemAlloc(sizeof(BoneInfo));
    memset(model.skeleton.bones, 0, sizeof(BoneInfo));
    model.skeleton.bones[0].parent = -1;
    model.skeleton.bindPose = MemAlloc(sizeof(Transform));
    model.skeleton.bindPose[0] = TestPose(0.0f);
    model.currentPose = MemAlloc(sizeof(Transform));
    model.currentPose[0] = TestPose(0.0f);
    model.boneMatrices = MemAlloc(sizeof(Matrix));
    memset(model.boneMatrices, 0, sizeof(Matrix));
    return model;
}
