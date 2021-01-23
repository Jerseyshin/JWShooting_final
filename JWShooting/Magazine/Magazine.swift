//
//  Magazine.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation
import SpriteKit

class Magazine {
    var bullets: [Bullet]!
    var capacity: Int!
    
    init(bullets: [Bullet]){
        self.bullets = bullets
        self.capacity = bullets.count
    }
    
    func shoot() {
        bullets.first { $0.wasShot() == false }?.shoot()
    }
    
    func needToReload() -> Bool {
        return bullets.allSatisfy {$0.wasShot() == true}
    }
    
    func reloadIfNeeded() {
        if needToReload() {
            for bullet in bullets {
                bullet.reloadIfNeeded()
            }
        }
    }
}
