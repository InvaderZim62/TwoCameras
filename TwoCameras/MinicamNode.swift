//
//  MinicamNode.swift
//  TwoCameras
//
//  Created by Phil Stern on 4/10/26.
//

import UIKit
import SceneKit

class MinicamNode: SCNNode {
    
    init(bodyLength: Float) {
        super.init()
        
        let cameraLength = bodyLength
        let cameraWidth = 0.25 * bodyLength
        let cameraHeight = 0.75 * bodyLength
        let reelWidth = 0.125 * bodyLength  // film reel width
        let reelRadius = 0.325 * bodyLength
        let frontReelOffset = 0.25 * bodyLength  // forward offset from center of camera body
        let lensLength = 0.75 * bodyLength
        let lensRadius = 0.25 * bodyLength
        let lensOffset = 0.075 * bodyLength  // amount lens/cone imbedded in camera body

        geometry = SCNBox(width: CGFloat(cameraWidth), height: CGFloat(cameraHeight), length: CGFloat(cameraLength), chamferRadius: 0.0)
        geometry?.firstMaterial?.diffuse.contents = UIColor.gray

        let frontReel = SCNCylinder(radius: CGFloat(reelRadius), height: CGFloat(reelWidth))
        frontReel.materials.first?.diffuse.contents = UIColor.gray
        let frontReelNode = SCNNode(geometry: frontReel)
        frontReelNode.transform = SCNMatrix4Rotate(frontReelNode.transform, .pi / 2, 0, 0, 1)
        frontReelNode.position = SCNVector3(x: 0, y: cameraHeight / 2 + reelRadius, z: -frontReelOffset)
        addChildNode(frontReelNode)
        
        let rearReel = SCNCylinder(radius: CGFloat(reelRadius), height: CGFloat(reelWidth))
        rearReel.materials.first?.diffuse.contents = UIColor.gray
        let rearReelNode = SCNNode(geometry: rearReel)
        rearReelNode.transform = SCNMatrix4Rotate(rearReelNode.transform, .pi / 2, 0, 0, 1)
        rearReelNode.position = SCNVector3(x: 0, y: cameraHeight / 2 + reelRadius, z: -frontReelOffset + 2 * reelRadius)
        addChildNode(rearReelNode)
        
        let lens = SCNCone(topRadius: 0, bottomRadius: CGFloat(lensRadius), height: CGFloat(lensLength))
        lens.materials.first?.diffuse.contents = UIColor.gray
        let lensNode = SCNNode(geometry: lens)
        lensNode.transform = SCNMatrix4Rotate(lensNode.transform, .pi / 2, 1, 0, 0)
        lensNode.position = SCNVector3(x: 0, y: 0, z: -cameraLength / 2 - lensOffset)
        addChildNode(lensNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
