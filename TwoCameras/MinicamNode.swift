//
//  MinicamNode.swift
//  TwoCameras
//
//  Created by Phil Stern on 4/10/26.
//

import UIKit
import SceneKit

class MinicamNode: SCNNode {
    
    override init() {
        super.init()
        
        geometry = SCNBox(width: 0.1, height: CGFloat(Constant.cameraHeight), length: CGFloat(Constant.cameraLength), chamferRadius: 0.0)
        geometry?.firstMaterial?.diffuse.contents = UIColor.gray

        let frontReal = SCNCylinder(radius: CGFloat(Constant.realRadius), height: 0.05)
        frontReal.materials.first?.diffuse.contents = UIColor.gray
        let frontRealNode = SCNNode(geometry: frontReal)
        frontRealNode.transform = SCNMatrix4Rotate(frontRealNode.transform, .pi / 2, 0, 0, 1)
        frontRealNode.position = SCNVector3(x: 0, y: Constant.cameraHeight / 2 + Constant.realRadius, z: -0.1)
        addChildNode(frontRealNode)
        
        let rearReal = SCNCylinder(radius: CGFloat(Constant.realRadius), height: 0.05)
        rearReal.materials.first?.diffuse.contents = UIColor.gray
        let rearRealNode = SCNNode(geometry: rearReal)
        rearRealNode.transform = SCNMatrix4Rotate(rearRealNode.transform, .pi / 2, 0, 0, 1)
        rearRealNode.position = SCNVector3(x: 0, y: Constant.cameraHeight / 2 + Constant.realRadius, z: -0.1 + 2 * Constant.realRadius)
        addChildNode(rearRealNode)
        
        let lens = SCNCone(topRadius: 0, bottomRadius: 0.1, height: CGFloat(Constant.lensLength))
        lens.materials.first?.diffuse.contents = UIColor.gray
        let lensNode = SCNNode(geometry: lens)
        lensNode.transform = SCNMatrix4Rotate(lensNode.transform, .pi / 2, 1, 0, 0)
        lensNode.position = SCNVector3(x: 0, y: 0, z: -(Constant.cameraLength + 0.2 * Constant.lensLength) / 2)
        addChildNode(lensNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
