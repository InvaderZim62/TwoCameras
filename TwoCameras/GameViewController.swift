//
//  GameViewController.swift
//  TwoCameras
//
//  Created by Phil Stern on 4/9/26.
//
//  Two views sharing the same scene, each with their own camera
//  from: https://stackoverflow.com/a/35119153/2526464
//

import UIKit
import QuartzCore
import SceneKit

struct Constant {
    static let minicamDistance: Float = 5  // can't be at 0, for pinch to work
    static let cameraDistance: Float = 12
    static let showOffsetLines = true
}

class GameViewController: UIViewController {

    var scnScene: SCNScene!

    var cameraNodeUpper: SCNNode!
    var cameraNodeLower: SCNNode!
    
    var minicamNode = MinicamNode(bodyLength: 1)
    var minicamOffset = SCNVector3(0, 0, Constant.minicamDistance)  // in minicam coordinates
    var minicamOffsetLines = Array(repeating: SCNNode(), count: 3)  // minicamOffset vector as three colored lines connecting minicam to world center

    @IBOutlet weak var scnViewUpper: SCNView!
    @IBOutlet weak var scnViewLower: SCNView!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScenes()
        setupViews()
        setupCameras()
        
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0.0)
        box.materials.first?.diffuse.contents = UIColor.gray
        let boxNode = SCNNode(geometry: box)
        boxNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        scnViewUpper.scene?.rootNode.addChildNode(boxNode)

        minicamNode.position = minicamOffset
        scnViewUpper.scene?.rootNode.addChildNode(minicamNode)
        showMinicamOffsetLines()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        view.addGestureRecognizer(rotation)
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        
        if recognizer.numberOfTouches == 1 {
            // rotate minicam
            let deltaRight = Float(translation.x / 150)
            let deltaUp = Float(-translation.y / 150)
            
            // deltaRight rotates the camera about the world neg. y-axis;
            // deltaUp rotates the camera about the camera pos. x-axis;
            // deltaRight must be converted to camera coordinates before adding deltaUp
            let deltaMinicam = convertVectorFromWorldToLocal(vector: SCNVector3(0, -deltaRight, 0), minicamNode.simdOrientation)
            
            let totalRotation = sqrt(pow(deltaMinicam.magnitude, 2) + pow(deltaUp, 2))
            minicamNode.transform = SCNMatrix4Rotate(minicamNode.transform, totalRotation,  // incremental rotation
                                                     deltaMinicam.x + deltaUp,
                                                     deltaMinicam.y,
                                                     deltaMinicam.z)
        } else if recognizer.numberOfTouches == 2 {
            // offset minicam
            // move minicam along minicam x/y axes
            let deltaPosition = SCNVector3(Float(translation.x), Float(-translation.y), 0) / 180
            minicamOffset -= deltaPosition
        }
        
        minicamNode.position = convertVectorFromLocalToWorld(vector: minicamOffset, minicamNode.simdOrientation)
        showMinicamOffsetLines()
        recognizer.setTranslation(.zero, in: recognizer.view)
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        minicamOffset.z /= Float(recognizer.scale)  // should prevent this from reaching zero
        showMinicamOffsetLines()
        minicamNode.position = convertVectorFromLocalToWorld(vector: minicamOffset, minicamNode.simdOrientation)
        recognizer.scale = 1
    }
    
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        // roll minicam
        // roll minicam around minicam z-axis
        let deltaRoll = Float(recognizer.rotation)
        minicamNode.transform = SCNMatrix4Rotate(minicamNode.transform, deltaRoll, 0, 0, 1)  // incremental rotation
        let deltaQuat = simd_quatf(angle: deltaRoll, axis: [0, 0, 1])
        minicamOffset = convertVectorFromWorldToLocal(vector: minicamOffset, deltaQuat)
        showMinicamOffsetLines()
        recognizer.rotation = 0
    }

    private func showMinicamOffsetLines() {
        guard Constant.showOffsetLines else { return }
        minicamOffsetLines.indices.forEach { updateMinicamOffsetLineFor(index: $0) }
    }
    
    // remove and re-add lines with updated offsets
    private func updateMinicamOffsetLineFor(index: Int) {
        minicamOffsetLines[index].removeFromParentNode()
        var size = SCNVector3(0.01, 0.01, 0.01)
        switch index {
        case 0:
            size.x = abs(minicamOffset.x)
        case 1:
            size.y = abs(minicamOffset.y)
        case 2:
            size.z = abs(minicamOffset.z)
        default:
            break
        }
        let line = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: 0)
        line.firstMaterial?.diffuse.contents = [UIColor.red, .green, .blue][index]
        minicamOffsetLines[index] = SCNNode(geometry: line)
        minicamOffsetLines[index].position = [SCNVector3(-minicamOffset.x / 2, -minicamOffset.y, -minicamOffset.z),
                                       SCNVector3(0, -minicamOffset.y / 2, -minicamOffset.z),
                                       SCNVector3(0, 0, -minicamOffset.z / 2)][index]
        minicamNode.addChildNode(minicamOffsetLines[index])
    }
    
    private func convertVectorFromLocalToWorld(vector: SCNVector3, _ quat: simd_quatf) -> SCNVector3 {
        let simdVector = simd_float3(vector)  // use simd, since SceneKit doesn't have quaternion math functions (like .act)
        return SCNVector3(quat.act(simdVector))
    }
    
    private func convertVectorFromWorldToLocal(vector: SCNVector3, _ quat: simd_quatf) -> SCNVector3 {
        let simdVector = simd_float3(vector)
        return SCNVector3(quat.inverse.act(simdVector))
    }

    // MARK: - Setup
    
    private func setupScenes() {
        scnScene = SCNScene()
        scnScene.background.contents = UIColor.lightGray
    }

    private func setupViews() {
        // both views share the same scene
        scnViewUpper.allowsCameraControl = false  // false: move camera programmatically
        scnViewUpper.autoenablesDefaultLighting = true  // false: disable default (ambient) light, if another light source is specified
        scnViewUpper.debugOptions = .showPhysicsShapes  // show axes
        scnViewUpper.scene = scnScene

        scnViewLower.allowsCameraControl = false
        scnViewLower.autoenablesDefaultLighting = true
        scnViewLower.debugOptions = .showPhysicsShapes
        scnViewLower.scene = scnScene
    }
    
    private func setupCameras() {
        // upper camera is attached to minicam
        cameraNodeUpper = SCNNode()
        cameraNodeUpper.camera = SCNCamera()
        scnViewUpper.pointOfView = cameraNodeUpper
        minicamNode.addChildNode(cameraNodeUpper)
        
        // lower camera looks at whole scene (box and minicam)
        cameraNodeLower = SCNNode()
        cameraNodeLower.camera = SCNCamera()
        let cameraAngle: Float = 20 * .pi / 180  // position camera 20 degrees above horizon
        cameraNodeLower.transform = SCNMatrix4Rotate(cameraNodeLower.transform, -cameraAngle, 1, 0, 0)  // rotate 20 degrees down
        cameraNodeLower.position = SCNVector3(x: 0, y: Constant.cameraDistance * sin(cameraAngle), z: Constant.cameraDistance * cos(cameraAngle))
        scnViewLower.pointOfView = cameraNodeLower
        scnScene.rootNode.addChildNode(cameraNodeLower)
    }
}
