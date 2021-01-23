//
//  Duck.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation
import SpriteKit

class Duck: SKNode{
    var hasTarget: Bool!
    
    init(hasTarget: Bool = false){
        super.init()
        
        self.hasTarget = hasTarget
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
