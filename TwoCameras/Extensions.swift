//
//  Extensions.swift
//  BingBangBoing
//
//  Created by Phil Stern on 2/6/26.
//

import UIKit
import SceneKit  // for SCNVector3

extension SCNVector3 {
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }

    static func *(lhs: SCNVector3, scaler: Float) -> SCNVector3 {
        return SCNVector3(x: lhs.x * scaler, y: lhs.y * scaler, z: lhs.z * scaler)
    }

    static func /(lhs: SCNVector3, scaler: Float) -> SCNVector3 {
        return SCNVector3(x: lhs.x / scaler, y: lhs.y / scaler, z: lhs.z / scaler)
    }

    static prefix func -(rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(x: -rhs.x, y: -rhs.y, z: -rhs.z)
    }
    
    static func +=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = lhs + rhs
    }
    
    static func -=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = lhs - rhs
    }

    func dot(_ rhs: SCNVector3) -> Float {
        return self.x * rhs.x + self.y * rhs.y + self.z * rhs.z
    }

    var magnitude: Float {
        return sqrt(x * x + y * y + z * z)
    }
}

extension SCNVector3: @retroactive Equatable {
    public static func == (lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
    

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    func distance(from point: CGPoint) -> Double {
        return Double(sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2)))
    }
}
