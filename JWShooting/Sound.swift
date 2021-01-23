//
//  Sound.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/22.
//

import Foundation

enum Sound: String {
    case musicLoop = "Cheerful Annoyance.wav"
    case hit = "hit.wav"
    case reload = "reload.wav"
    case score = "score.wav"
    
    var fileName: String {
        return rawValue
    }
}
