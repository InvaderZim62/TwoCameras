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
    static let boxSize: CGFloat = 1
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
        
        let box = SCNBox(width: Constant.boxSize, height: Constant.boxSize, length: Constant.boxSize, chamferRadius: 0.0)
        box.materials.first?.diffuse.contents = UIColor.gray
        let boxNode = SCNNode(geometry: box)
        boxNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)  // needed for .showPhysicsShapes
        scnView.scene?.rootNode.addChildNode(boxNode)
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
