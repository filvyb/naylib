import std/[os, unicode]
import raylib, raymath, rlgl

{.passC: "-I" & currentSourcePath().parentDir.}
proc testAnimation(): ModelAnimation {.cdecl, importc: "TestAnimation",
    header: "raylib_60_fixture.h".}
proc testModel(): Model {.cdecl, importc: "TestModel", header: "raylib_60_fixture.h".}
proc testMesh(): ptr Mesh {.cdecl, importc: "TestMesh", header: "raylib_60_fixture.h".}
proc testMeshVertexBuffers(): int32 {.cdecl, importc: "TestMeshVertexBuffers",
    header: "raylib_60_fixture.h".}

template expectIndexDefect(body: untyped) =
  block:
    var raised = false
    try:
      body
    except IndexDefect:
      raised = true
    doAssert raised

proc testAnimationAccess() =
  var model = testModel()
  var anim = testAnimation()
  doAssert RaylibVersion == (6, 0, 0)
  doAssert RlglVersion == (6, 0, 0)
  doAssert model.skeleton.boneCount == 1
  doAssert model.skeleton.bones[0].parent == -1
  doAssert model.skeleton.bindPose[0].scale.x == 1
  doAssert anim.boneCount == 1
  doAssert anim.keyframeCount == 2
  doAssert anim.keyframePoses[1, 0].translation.x == 2
  doAssert isModelAnimationValid(model, anim)

  updateModelAnimation(model, anim, 0.5)
  doAssert model.currentPose[0].translation.x == 1
  doAssert model.boneMatrices[0].m12 == 1
  updateModelAnimation(model, anim, 0, anim, 1, 0.25)
  doAssert model.currentPose[0].translation.x == 0.5

  var pose = anim.keyframePoses[1, 0]
  pose.translation.x = 4
  anim.keyframePoses[1, 0] = pose
  updateModelAnimation(model, anim, 0.5)
  doAssert model.currentPose[0].translation.x == 2
  model.skeleton.bones[0] = BoneInfo(parent: -1)
  model.skeleton.bindPose[0] = pose
  model.currentPose[0] = pose
  model.boneMatrices[0] = Matrix(m0: 1)

  expectIndexDefect: discard anim.keyframePoses[-1, 0]
  expectIndexDefect: discard anim.keyframePoses[2, 0]
  expectIndexDefect: discard anim.keyframePoses[0, 1]
  expectIndexDefect: discard model.skeleton.bones[1]
  expectIndexDefect: discard model.skeleton.bindPose[1]
  expectIndexDefect: discard model.currentPose[1]
  expectIndexDefect: discard model.boneMatrices[1]

  # Moving an animation into a managed container must free its poses exactly once.
  var animations: seq[ModelAnimation]
  animations.add(move(anim))
  doAssert animations[0].keyframePoses[1, 0].translation.x == 4

proc checkGraphicsBindings() =
  # Compile and link the changed graphics APIs; only run with an initialized GPU.
  drawCircleGradient(Vector2(x: 20, y: 30), 10, Red, Blue)
  let font = getFontDefault()
  discard measureTextCodepoints(font, [Rune(65)], 20, 1)
  let shader = rlgl.loadShader("", ShaderType.VertexShader)
  let program = rlgl.loadShaderProgram("", "")
  let linked = rlgl.loadShaderProgramEx(shader, shader)
  let compute = rlgl.loadShaderProgramCompute(shader)
  rlgl.unloadShader(shader)
  rlgl.unloadShaderProgram(program)
  rlgl.unloadShaderProgram(linked)
  rlgl.unloadShaderProgram(compute)

testAnimationAccess()
doAssert MaxMeshVertexBuffers == testMeshVertexBuffers()
let mesh = testMesh() # Borrowed static fixture; no GPU or owning Mesh destructor needed.
doAssert mesh[].boneIndices[0] == [1'u8, 2, 3, 4]
mesh[].boneIndices[0] = [4'u8, 3, 2, 1]
doAssert mesh[].boneIndices[0] == [4'u8, 3, 2, 1]
expectIndexDefect: discard mesh[].boneIndices[1]
block:
  var animations = loadModelAnimations(currentSourcePath().parentDir / "resources/animation.gltf")
  doAssert animations.len == 1
  doAssert animations[0].boneCount == 1
  doAssert animations[0].keyframeCount > 1
  let lastFrame = animations[0].keyframeCount - 1
  doAssert animations[0].keyframePoses[0, 0].translation.x == 0
  doAssert animations[0].keyframePoses[lastFrame, 0].translation.x == 2
let scaled = multiplyValue(Matrix(m0: 1, m5: 2, m10: 3, m15: 1), 2)
doAssert scaled.m0 == 2 and scaled.m5 == 4 and scaled.m10 == 6
doAssert scaled.m15 == 2
if paramCount() > 0:
  initWindow(100, 100, "Binding checks")
  checkGraphicsBindings()
  closeWindow()
