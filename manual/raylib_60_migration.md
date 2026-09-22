# Migrating to raylib 6.0

The bundled raylib sources are pinned to the [6.0 release](https://github.com/raysan5/raylib/releases/tag/6.0),
commit `dbc56a87da87d973a9c5baa4e7438a9d20121d28`. Both `RaylibVersion` and
`RlglVersion` are `(6, 0, 0)`.

## Models and animation

| Previous API | raylib 6.0 API |
| --- | --- |
| `mesh.boneIds` | `mesh.boneIndices` |
| `mesh.boneMatrices` | `model.boneMatrices` |
| `model.boneCount` | `model.skeleton.boneCount` |
| `model.bones` | `model.skeleton.bones` |
| `model.bindPose` | `model.skeleton.bindPose` |
| `anim.frameCount` | `anim.keyframeCount` |
| `anim.framePoses[frame, bone]` | `anim.keyframePoses[frame, bone]` |
| `anim.bones` | Removed; bone information belongs to the model skeleton |

`model.currentPose[bone]` exposes the current pose. Skeleton, pose and bone-matrix
arrays retain bounds-checked index access; allocation counts remain read-only.

`updateModelAnimation(model, anim, frame)` now takes a `float32` frame, allowing
interpolation between keyframes. A new overload blends two animations:

```nim
updateModelAnimation(model, animA, frameA, animB, frameB, blend)
```

`updateModelAnimationBones` and `drawModelPoints` were removed upstream.

`loadModelAnimations` still returns `RArray[ModelAnimation]` with automatic cleanup.
Individual animations remain noncopyable. Their destructor frees the keyframe poses;
the array destructor frees the outer allocation. The model destructor also frees
`currentPose` and `boneMatrices`, which raylib 6.0's `UnloadModel` omits.

The existing `-d:NaylibRlSupportMeshGpuSkinning=false` option now controls the
upstream `SUPPORT_GPU_SKINNING` flag. `MaxMeshVertexBuffers` is 9 with GPU skinning
and 7 without it.

## Drawing, text and math

- `drawCircleGradient` takes a `Vector2` center instead of separate x/y coordinates.
- `measureTextCodepoints(font, codepoints, fontSize, spacing)` accepts `openArray[Rune]`.
- `raymath.multiplyValue(matrix, value)` multiplies every matrix component by a scalar.
- `ShaderLocationIndex.BoneMatrices` becomes `MatrixBonetransforms`, and
  `VertexInstanceTx` becomes `VertexInstancetransform`.

## Low-level rlgl shaders

| Previous API | raylib 6.0 API |
| --- | --- |
| `compileShader(code, shaderType)` | `loadShader(code, shaderType)` |
| `loadShaderCode(vsCode, fsCode)` | `loadShaderProgram(vsCode, fsCode)` |
| `loadShaderProgram(vertexId, fragmentId)` | `loadShaderProgramEx(vertexId, fragmentId)` |
| `loadComputeShaderProgram(computeId)` | `loadShaderProgramCompute(computeId)` |
| `GlVersion.Opengl11Software` | `GlVersion.OpenglSoftware` |

`rlgl.unloadShader(id)` releases an individual shader. Qualify `rlgl.loadShader`
when importing both `raylib` and `rlgl`. Empty strings for the two shader-program
sources still select the default shaders.

## Verification

`nim c -r tests/raylib_60.nim` runs without a display and checks animation loading,
interpolation, blending, bounds checks, ownership and matrix scalar multiplication.
It is included in `nimble test`, followed by the existing platform compilation checks.
