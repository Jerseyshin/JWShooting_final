//
//  Texture.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation

enum Texture: String{
    case fireButtonNormal = "fire_normal"
    case fireButtonPressed = "fire_pressed"
    case fireButtonReloading = "fire_reloading"
    case bulletEmptyTexture = "icon_bullet_empty"
    case bulletTexture = "icon_bullet"
    case shotBlue = "shot_blue"
    case shotBrown = "shot_brown"
    case duckIcon = "icon_duck"
    case targetIcon = "icon_target"
    
    var imageName: String{
        return rawValue
    }
}
