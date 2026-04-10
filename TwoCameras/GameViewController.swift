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
    static let minicamDistance: Float = 2  // can't be at 0, for pinch to work
    static let cameraDistance: Float = 6
    static let cameraHeight: Float = 0.3  // minicam
    static let cameraLength: Float = 0.4
    static let realRadius: Float = 0.13
    static let lensLength: Float = 0.3
}

class GameViewController: UIViewController {

    var scnScene: SCNScene!

    var cameraNodeUpper: SCNNode!
    var cameraNodeLower: SCNNode!
    
    var minicamNode: MinicamNode!
    var minicamOffset = SCNVector3(0, 0, Constant.minicamDistance)  // in minicam coordinates
    var offsetLines = Array(repeating: SCNNode(), count: 3)  // minicamOffset vector as three colored lines connecting minicam to world center

    @IBOutlet weak var scnViewUpper: SCNView!
    @IBOutlet weak var scnViewLower: SCNView!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScenes()
        setupViews()
        setupCameras()
        
        let box = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.0)
        box.materials.first?.diffuse.contents = UIColor.gray
        let boxNode = SCNNode(geometry: box)
        boxNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        scnViewUpper.scene?.rootNode.addChildNode(boxNode)

        minicamNode = MinicamNode()
        minicamNode.position = minicamOffset
        scnViewUpper.scene?.rootNode.addChildNode(minicamNode)

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
            // rotate minicamNode
            // pan right: rotate world around world y-axis (rotate minicamNode about negative world y-axis)
            // pan up: rotate world about screen left-axis (rotate minicamNode about positive camera x-axis)
            let deltaRight = Float(translation.x / 150)
            let deltaUp = Float(-translation.y / 150)
            
            let deltaMinicam = convertVectorFromWorldToLocal(vector: SCNVector3(0, -deltaRight, 0), minicamNode.orientation)
            minicamNode.orientation = minicamNode.orientation.rotatedBy(deltaPitch: deltaUp + deltaMinicam.x, deltaYaw: deltaMinicam.y, deltaRoll: deltaMinicam.z)
            
        } else if recognizer.numberOfTouches == 2 {
            // offset minicamNode
            let deltaPosition = SCNVector3(Float(translation.x), Float(-translation.y), 0) / 180
            minicamOffset -= deltaPosition
        }
        
        minicamNode.position = convertVectorFromLocalToWorld(vector: minicamOffset, minicamNode.orientation)
        updateMinicamOffsetLines()
        recognizer.setTranslation(.zero, in: recognizer.view)
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        minicamOffset.z /= Float(recognizer.scale)  // should prevent this from reaching zero
        updateMinicamOffsetLines()
        minicamNode.position = convertVectorFromLocalToWorld(vector: minicamOffset, minicamNode.orientation)
        recognizer.scale = 1
    }
    
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        // bank minicamNode
        let deltaRoll = Float(recognizer.rotation)
        minicamNode.orientation = minicamNode.orientation.rotatedBy(deltaPitch: 0, deltaYaw: 0, deltaRoll: deltaRoll)
        let deltaQuat = SCNQuaternion(x: 0, y: 0, z: 1, w: deltaRoll)
        minicamOffset = convertVectorFromWorldToLocal(vector: minicamOffset, deltaQuat)
        updateMinicamOffsetLines()
        recognizer.rotation = 0
    }

    private func updateMinicamOffsetLines() {
        offsetLines.indices.forEach { showMinicamOffsetLineFor(index: $0) }
    }
    
    // remove and re-add lines with updated offsets
    private func showMinicamOffsetLineFor(index: Int) {
        offsetLines[index].removeFromParentNode()
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
//        offsetLines[index] = ModelEntity(mesh: .generateBox(size: size))
//        let material = SimpleMaterial(color: [.red, .green, .blue][index], isMetallic: false)
//        offsetLines[index].model?.materials = [material]
//        offsetLines[index].position = [[-minicamOffset.x / 2, -minicamOffset.y, -minicamOffset.z], [0, -minicamOffset.y / 2, -minicamOffset.z], [0, 0, -minicamOffset.z / 2]][index]
        minicamNode.addChildNode(offsetLines[index])
    }

    private func convertVectorFromLocalToWorld(vector: SCNVector3, _ quat: SCNQuaternion) -> SCNVector3 {
        // SceneKit doesn't have quaternion math functions (like .act), so convert to simd, using extensions below
        let simdQuat = simd_quatf(quat)
        let simdVector = simd_float3(vector)
        return SCNVector3(simdQuat.act(simdVector))
    }
    
    private func convertVectorFromWorldToLocal(vector: SCNVector3, _ quat: SCNQuaternion) -> SCNVector3 {
        // SceneKit doesn't have quaternion math functions (like .act), so convert to simd, using extensions below
        let simdQuat = simd_quatf(quat)
        let simdVector = simd_float3(vector)
        return SCNVector3(simdQuat.inverse.act(simdVector))
    }

    // MARK: - Setup
    
    private func setupScenes() {
        scnScene = SCNScene()
        scnScene.background.contents = UIColor.lightGray
    }

    private func setupViews() {
        scnViewUpper.allowsCameraControl = false  // false: move camera programmatically
        scnViewUpper.autoenablesDefaultLighting = true  // false: disable default (ambient) light, if another light source is specified
        scnViewUpper.debugOptions = .showPhysicsShapes  // show axes
        scnViewUpper.scene = scnScene
        scnViewUpper.delegate = self

        scnViewLower.allowsCameraControl = false
        scnViewLower.autoenablesDefaultLighting = true
        scnViewLower.debugOptions = .showPhysicsShapes
        scnViewLower.scene = scnScene
    }
    
    private func setupCameras() {
        // upper camera will be attached to minicam in renderer, below
        cameraNodeUpper = SCNNode()
        cameraNodeUpper.camera = SCNCamera()
        scnViewUpper.pointOfView = cameraNodeUpper
        scnScene.rootNode.addChildNode(cameraNodeUpper)
        
        // lower camera looking at whole scene (minicam and box) from slightly above
        cameraNodeLower = SCNNode()
        cameraNodeLower.camera = SCNCamera()
        let cameraAngle: Float = 20 * .pi / 180  // position camera 20 degrees above horizon
        cameraNodeLower.transform = SCNMatrix4Rotate(cameraNodeLower.transform, -cameraAngle, 1, 0, 0)  // rotate 20 degrees down
        cameraNodeLower.position = SCNVector3(x: 0, y: Constant.cameraDistance * sin(cameraAngle), z: Constant.cameraDistance * cos(cameraAngle))
        scnViewLower.pointOfView = cameraNodeLower
        scnScene.rootNode.addChildNode(cameraNodeLower)
    }
}

extension GameViewController: SCNSceneRendererDelegate {  // requires scnView.delegate = self
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        cameraNodeUpper.transform = minicamNode.transform
    }
}

extension SCNQuaternion {
    // incrementally rotate quaternion
    func rotatedBy(deltaPitch: Float, deltaYaw: Float, deltaRoll: Float) -> SCNQuaternion {
        let quat = self
        
        // quaternion rates (aeronautical standard, except: p -> q, q -> r, r -> p)
        let deltaQw = (-quat.x * deltaPitch - quat.y * deltaYaw - quat.z * deltaRoll) / 2
        let deltaQx = ( quat.w * deltaPitch - quat.z * deltaYaw + quat.y * deltaRoll) / 2
        let deltaQy = ( quat.z * deltaPitch + quat.w * deltaYaw - quat.x * deltaRoll) / 2
        let deltaQz = (-quat.y * deltaPitch + quat.x * deltaYaw + quat.w * deltaRoll) / 2
        
        // intergate quaternion rates
        var qw = quat.w + deltaQw
        var qx = quat.x + deltaQx
        var qy = quat.y + deltaQy
        var qz = quat.z + deltaQz
        
        // normalize quaternions to prevent integration error growth
        let qnorm = sqrt(pow(qw, 2) + pow(qx, 2) + pow(qy, 2) + pow(qz, 2))
        
        qw /= qnorm
        qx /= qnorm
        qy /= qnorm
        qz /= qnorm

        return SCNQuaternion(qx, qy, qz, qw)
    }
}

extension simd_quatf {
    init(_ quat: SCNQuaternion) {
        self.init(ix: quat.x, iy: quat.y, iz: quat.z, r: quat.w)
    }
}

extension SCNVector3 {
    init (_ vector: simd_float3) {
        self.init(vector.x, vector.y, vector.z)
    }
}
