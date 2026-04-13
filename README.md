# Two Cameras

Two Cameras is a ScneneKit app.  It demonstrates how you can have two views of the same scene,
each with its own camera.  It also demonstrates how to duplicate the standard camera controls
built into SceneKit.

The lower view has a fixed camera, positioned to show a box fixed at the center of the scene and
a model of a camera (minicam) moving around the scene.  The upper view has a camera attached to
the minicam.  As you pan, pinch, and rotate the screen, the minicam moves using the duplicated
camera controls.

![Two cameras](https://github.com/user-attachments/assets/b2ad2524-c529-4032-b0f4-c0b5626c23b0)

These are the important parts of the code:

```swift
    // both views share the same scene
    scnScene = SCNScene()
    scnViewUpper.scene = scnScene
    scnViewLower.scene = scnScene

    // upper camera is attached to minicam
    cameraNodeUpper = SCNNode()
    cameraNodeUpper.camera = SCNCamera()
    scnViewUpper.pointOfView = cameraNodeUpper
    minicamNode.addChildNode(cameraNodeUpper)
    
    // lower camera looks at whole scene (box and minicam)
    cameraNodeLower = SCNNode()
    cameraNodeLower.camera = SCNCamera()
    cameraNodeLower.position = SCNVector3(x: 0, y: 0, z: 12)
    scnViewLower.pointOfView = cameraNodeLower
    scnScene.rootNode.addChildNode(cameraNodeLower)
```
