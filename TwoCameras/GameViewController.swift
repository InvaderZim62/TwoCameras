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
    static let cameraDistance: Float = 8
    static let cameraHeight: Float = 0.3  // minicam
    static let cameraLength: Float = 0.4
    static let realRadius: Float = 0.13
    static let lensLength: Float = 0.3
}

class GameViewController: UIViewController {

    var scnScene: SCNScene!

    var cameraNodeUpper: SCNNode!
    var cameraNodeLower: SCNNode!
    
    var minicamNode: SCNNode!
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

        createMinicam()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        view.addGestureRecognizer(rotation)
    }
    
    private func createMinicam() {
        let minicam = SCNBox(width: 0.1, height: CGFloat(Constant.cameraHeight), length: CGFloat(Constant.cameraLength), chamferRadius: 0.0)
        minicam.materials.first?.diffuse.contents = UIColor.gray
        minicamNode = SCNNode(geometry: minicam)
        minicamNode.position = minicamOffset
        minicamNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        scnViewUpper.scene?.rootNode.addChildNode(minicamNode)
        
        let frontReal = SCNCylinder(radius: CGFloat(Constant.realRadius), height: 0.05)
        frontReal.materials.first?.diffuse.contents = UIColor.gray
        let frontRealNode = SCNNode(geometry: frontReal)
        frontRealNode.transform = SCNMatrix4Rotate(frontRealNode.transform, .pi / 2, 0, 0, 1)
        frontRealNode.position = SCNVector3(x: 0, y: Constant.cameraHeight / 2 + Constant.realRadius, z: -0.1)
        minicamNode.addChildNode(frontRealNode)
        
        let rearReal = SCNCylinder(radius: CGFloat(Constant.realRadius), height: 0.05)
        rearReal.materials.first?.diffuse.contents = UIColor.gray
        let rearRealNode = SCNNode(geometry: rearReal)
        rearRealNode.transform = SCNMatrix4Rotate(rearRealNode.transform, .pi / 2, 0, 0, 1)
        rearRealNode.position = SCNVector3(x: 0, y: Constant.cameraHeight / 2 + Constant.realRadius, z: -0.1 + 2 * Constant.realRadius)
        minicamNode.addChildNode(rearRealNode)
      
        let lens = SCNCone(topRadius: 0, bottomRadius: 0.1, height: CGFloat(Constant.lensLength))
        lens.materials.first?.diffuse.contents = UIColor.gray
        let lensNode = SCNNode(geometry: lens)
        lensNode.transform = SCNMatrix4Rotate(lensNode.transform, .pi / 2, 1, 0, 0)
        lensNode.position = SCNVector3(x: 0, y: 0, z: -(Constant.cameraLength + 0.2 * Constant.lensLength) / 2)
        minicamNode.addChildNode(lensNode)
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: recognizer.view)
        
        if recognizer.numberOfTouches == 1 {
            // rotate minicamNode
            // pan right: rotate world around world y-axis (rotate minicamNode about negative world y-axis)
            // pan up: rotate world about screen left-axis (rotate minicamNode about positive camera x-axis)
            let deltaRight = Float(translation.x / 150)
            let deltaUp = Float(-translation.y / 150)
            
            let deltaMinicam = transformVectorFromWorldToLocal(vector: SCNVector3(0, -deltaRight, 0), minicamNode.orientation)
            minicamNode.orientation = minicamNode.orientation.rotatedBy(deltaPitch: deltaUp + deltaMinicam.x, deltaYaw: deltaMinicam.y, deltaRoll: deltaMinicam.z)
            
        } else if recognizer.numberOfTouches == 2 {
            // offset minicamNode
            let deltaPosition = SCNVector3(Float(translation.x), Float(-translation.y), 0) / 180
            minicamOffset -= deltaPosition
        }
        
        minicamNode.position = transformVectorFromLocalToWorld(vector: minicamOffset, minicamNode.orientation)
        updateMinicamOffsetLines()
        recognizer.setTranslation(.zero, in: recognizer.view)
    }
    
    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        minicamOffset.z /= Float(recognizer.scale)  // should prevent this from reaching zero
        updateMinicamOffsetLines()
        minicamNode.position = transformVectorFromLocalToWorld(vector: minicamOffset, minicamNode.orientation)
        recognizer.scale = 1
    }
    
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        // bank minicamNode
        let deltaRoll = Float(recognizer.rotation)
        minicamNode.orientation = minicamNode.orientation.rotatedBy(deltaPitch: 0, deltaYaw: 0, deltaRoll: deltaRoll)
        let deltaQuat = SCNQuaternion(x: 0, y: 0, z: 1, w: deltaRoll)
        minicamOffset = transformVectorFromWorldToLocal(vector: minicamOffset, deltaQuat)
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

    // transform vector from body to world coordinates
    private func transformVectorFromLocalToWorld(vector: SCNVector3, _ quat: SCNQuaternion) -> SCNVector3 {
        let t0 = -quat.x * vector.x - quat.y * vector.y - quat.z * vector.z
        let t1 =  quat.w * vector.x + quat.y * vector.z - quat.z * vector.y
        let t2 =  quat.w * vector.y - quat.x * vector.z + quat.z * vector.x
        let t3 =  quat.w * vector.z + quat.x * vector.y - quat.y * vector.x
        
        let v1 = -t0 * quat.x + t1 * quat.w - t2 * quat.z + t3 * quat.y
        let v2 = -t0 * quat.y + t1 * quat.z + t2 * quat.w - t3 * quat.x
        let v3 = -t0 * quat.z - t1 * quat.y + t2 * quat.x + t3 * quat.w
        
        return SCNVector3(v1, v2, v3)
    }
    
    private func transformVectorFromWorldToLocal(vector: SCNVector3, _ quat: SCNQuaternion) -> SCNVector3 {
        let t0 = quat.x * vector.x + quat.y * vector.y + quat.z * vector.z
        let t1 = quat.w * vector.x - quat.y * vector.z + quat.z * vector.y
        let t2 = quat.w * vector.y + quat.x * vector.z - quat.z * vector.x
        let t3 = quat.w * vector.z - quat.x * vector.y + quat.y * vector.x
        
        let v1 = t0 * quat.x + t1 * quat.w + t2 * quat.z - t3 * quat.y
        let v2 = t0 * quat.y - t1 * quat.z + t2 * quat.w + t3 * quat.x
        let v3 = t0 * quat.z + t1 * quat.y - t2 * quat.x + t3 * quat.w
        
        return SCNVector3(v1, v2, v3)
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
        let cameraAngle: Float = 20 * .pi / 180  // position camera 20 degrees above horizon

        // upper camera looking at aft of jet (from slightly above)
        cameraNodeUpper = SCNNode()
        cameraNodeUpper.camera = SCNCamera()
        cameraNodeUpper.transform = SCNMatrix4Rotate(cameraNodeUpper.transform, -cameraAngle, 1, 0, 0)  // rotate 20 degrees down
        cameraNodeUpper.position = SCNVector3(x: 0, y: Constant.cameraDistance * sin(cameraAngle), z: Constant.cameraDistance * cos(cameraAngle))
        scnViewUpper.pointOfView = cameraNodeUpper
        scnScene.rootNode.addChildNode(cameraNodeUpper)
        
        // lower camera looking at right side of jet (from slightly above)
        cameraNodeLower = SCNNode()
        cameraNodeLower.camera = SCNCamera()
        cameraNodeLower.transform = SCNMatrix4Rotate(cameraNodeLower.transform, .pi / 2, 0, 1, 0)  // rotate 90 degrees left
        cameraNodeLower.transform = SCNMatrix4Rotate(cameraNodeLower.transform, -cameraAngle, 1, 0, 0)  // and 20 degrees down
        cameraNodeLower.position = SCNVector3(x: Constant.cameraDistance * cos(cameraAngle), y: Constant.cameraDistance * sin(cameraAngle), z: 0)
        scnViewLower.pointOfView = cameraNodeLower
        scnScene.rootNode.addChildNode(cameraNodeLower)
    }
    
//    private func setupCameras() {
//        // upper camera looking at center of scene from minicamNode position
//        cameraNodeUpper = SCNNode()
//        cameraNodeUpper.camera = SCNCamera()
//        cameraNodeUpper.position = minicamNode.position
//        scnViewUpper.pointOfView = cameraNodeUpper
//        scnScene.rootNode.addChildNode(cameraNodeUpper)
//        
//        // lower camera looking at aft of minicamNode
//        cameraNodeLower = SCNNode()
//        cameraNodeLower.camera = SCNCamera()
//        cameraNodeLower.position = SCNVector3(x: 0, y: 0, z: Constant.cameraDistance)
//        scnViewLower.pointOfView = cameraNodeLower
//        scnScene.rootNode.addChildNode(cameraNodeLower)
//    }
}

extension GameViewController: SCNSceneRendererDelegate {  // requires scnView.delegate = self
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        cameraNodeLower.transform = minicamNode.transform
//        cameraNodeUpper.transform = minicamNode.transform
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
