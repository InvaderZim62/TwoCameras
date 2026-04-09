//
//  GameViewController.swift
//  TwoCameras
//
//  Created by Phil Stern on 4/9/26.
//

import UIKit
import QuartzCore
import SceneKit

struct Constant {
    static let nominalCameraDistance: Float = 8
}

class GameViewController: UIViewController {

    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        
        addJet()
    }
    
    private func addJet() {
        let jet = SCNBox(width: 0.3, height: 0.1, length: 1, chamferRadius: 0.0)
        jet.materials.first?.diffuse.contents = UIColor.gray
        let jetNode = SCNNode(geometry: jet)
        jetNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        scnView.scene?.rootNode.addChildNode(jetNode)
        
        let wing = SCNBox(width: 1.2, height: 0.1, length: 0.2, chamferRadius: 0.0)
        wing.materials.first?.diffuse.contents = UIColor.gray
        let wingNode = SCNNode(geometry: wing)
        jetNode.addChildNode(wingNode)
        
        let tail = SCNBox(width: 0.1, height: 0.3, length: 0.2, chamferRadius: 0.0)
        tail.materials.first?.diffuse.contents = UIColor.gray
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(x: 0, y: 0.15, z: 0.4)
        jetNode.addChildNode(tailNode)
    }

    // MARK: - Setup

    private func setupView() {
        scnView = self.view as? SCNView
        scnView.allowsCameraControl = true  // false: move camera programmatically
        scnView.autoenablesDefaultLighting = true  // false: disable default (ambient) light, if another light source is specified
        scnView.debugOptions = .showPhysicsShapes  // for debugging
    }
    
    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = UIColor.lightGray
        scnView.scene = scnScene
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: Constant.nominalCameraDistance)
        scnScene.rootNode.addChildNode(cameraNode)
    }
}
