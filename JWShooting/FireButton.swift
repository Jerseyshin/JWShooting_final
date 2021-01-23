//
//  FireButton.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation
import SpriteKit

class FireButton: SKSpriteNode{
    var isReloading = false
    
    var isPressed = false {
        didSet{
            guard !isReloading else {return}
            if isPressed {
                texture = SKTexture(imageNamed: Texture.fireButtonPressed.imageName)
            }else{
                texture = SKTexture(imageNamed: Texture.fireButtonNormal.imageName)
            }
        }
    }
    
    init(){
        let texture = SKTexture(imageNamed: Texture.fireButtonNormal.imageName)
        super.init(texture: texture, color: .clear, size: texture.size())
        
        name = "fire"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
