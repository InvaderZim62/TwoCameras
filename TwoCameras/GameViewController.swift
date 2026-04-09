//
//  GameViewController.swift
//  TwoCameras
//
//  Created by Phil Stern on 4/9/26.
//
//  Two views sharing the same scene, each with their own camera
//

import UIKit
import QuartzCore
import SceneKit

struct Constant {
    static let nominalCameraDistance: Float = 4
}

class GameViewController: UIViewController {

    var scnScene: SCNScene!

    var cameraNodeUpper: SCNNode!
    var cameraNodeLower: SCNNode!
    
    var jetNode: SCNNode!

    @IBOutlet weak var scnViewUpper: SCNView!
    @IBOutlet weak var scnViewLower: SCNView!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScenes()
        setupViews()
        setupCameras()
        
        addJet()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnViewUpper.addGestureRecognizer(tap)
    }
    
    private func addJet() {
        let jet = SCNBox(width: 0.3, height: 0.1, length: 1, chamferRadius: 0.0)
        jet.materials.first?.diffuse.contents = UIColor.gray
        jetNode = SCNNode(geometry: jet)
        jetNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        
        let wing = SCNBox(width: 1.2, height: 0.1, length: 0.2, chamferRadius: 0.0)
        wing.materials.first?.diffuse.contents = UIColor.gray
        let wingNode = SCNNode(geometry: wing)
        jetNode.addChildNode(wingNode)
        
        let tail = SCNBox(width: 0.1, height: 0.3, length: 0.2, chamferRadius: 0.0)
        tail.materials.first?.diffuse.contents = UIColor.gray
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(x: 0, y: 0.15, z: 0.4)
        jetNode.addChildNode(tailNode)

        scnViewUpper.scene?.rootNode.addChildNode(jetNode)
    }
    
    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        jetNode.transform = SCNMatrix4Rotate(jetNode.transform, .pi / 8, 0, 1, 0)
    }

    // MARK: - Setup
    
    private func setupScenes() {
        scnScene = SCNScene()
        scnScene.background.contents = UIColor.lightGray
    }

    private func setupViews() {
        scnViewUpper.allowsCameraControl = true  // false: move camera programmatically
        scnViewUpper.autoenablesDefaultLighting = true  // false: disable default (ambient) light, if another light source is specified
        scnViewUpper.debugOptions = .showPhysicsShapes  // show axes
        scnViewUpper.scene = scnScene

        scnViewLower.allowsCameraControl = true
        scnViewLower.autoenablesDefaultLighting = true
        scnViewLower.debugOptions = .showPhysicsShapes
        scnViewLower.scene = scnScene
    }
    
    private func setupCameras() {
        // upper camera looking at aft of jet
        cameraNodeUpper = SCNNode()
        cameraNodeUpper.camera = SCNCamera()
        cameraNodeUpper.position = SCNVector3(x: 0, y: 0, z: Constant.nominalCameraDistance)
        scnViewUpper.pointOfView = cameraNodeUpper
        scnScene.rootNode.addChildNode(cameraNodeUpper)
        
        // lower camera looking at right side of jet
        cameraNodeLower = SCNNode()
        cameraNodeLower.camera = SCNCamera()
        cameraNodeLower.transform = SCNMatrix4Rotate(cameraNodeLower.transform, .pi / 2, 0, 1, 0)
        cameraNodeLower.position = SCNVector3(x: Constant.nominalCameraDistance, y: 0, z: 0)
        scnViewLower.pointOfView = cameraNodeLower
        scnScene.rootNode.addChildNode(cameraNodeLower)
    }
}
