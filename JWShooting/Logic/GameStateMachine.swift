//
//  GameStateMachine.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation
import GameplayKit

class GameState: GKState{
    unowned var fire: FireButton
    unowned var magazine: Magazine
    
    init(fire: FireButton, magazine: Magazine){
        self.fire = fire
        self.magazine = magazine
        
        super.init()
    }
}

class ReadyState: GameState{
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        if stateClass is ShootingState.Type && !magazine.needToReload() {
            return true
        }
        return false
    }
    
    override func didEnter(from previousState: GKState?) {
        magazine.reloadIfNeeded()
        stateMachine?.enter(ShootingState.self)
    }
    
}

class ShootingState: GameState{
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        if stateClass is ReloadingState.Type && magazine.needToReload() {
            return true
        }
        return false
    }
    
    override func didEnter(from previousState: GKState?) {
        fire.removeAction(forKey: ActionKey.reloading.key)
        fire.run(.animate(with: [SKTexture.init(imageNamed: Texture.fireButtonNormal.imageName)], timePerFrame: 0.1), withKey: ActionKey.reloading.key)
    }
}

class ReloadingState: GameState{
    let reloadingTime: Double = 0.25
    
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        if stateClass is ShootingState.Type && !magazine.needToReload() {
            return true
        }
        return false
    }
    
    let reloadingTexture = SKTexture(imageNamed: Texture.fireButtonReloading.imageName)
    lazy var fireButtonReloadingAction = {
        SKAction.sequence([
                            SKAction.animate(with: [reloadingTexture], timePerFrame: 0.1),
                            SKAction.rotate(byAngle: 360, duration: 30)
                        ])
    }()
    
    let bulletTexture = SKTexture(imageNamed: Texture.bulletTexture.imageName)
    lazy var bulletReloadingAction = {
        SKAction.animate(with: [bulletTexture], timePerFrame: 0.1)
    }()
    
    override func didEnter(from previousState: GKState?) {
        fire.isReloading = true
        fire.removeAction(forKey: ActionKey.reloading.key)
        fire.run(fireButtonReloadingAction, withKey: ActionKey.reloading.key)
        
        for (i, bullet) in magazine.bullets.reversed().enumerated(){
            var action = [SKAction]()
            
            let waitAction = SKAction.wait(forDuration: TimeInterval(reloadingTime * Double(i)))
            action.append(waitAction)
            action.append(bulletReloadingAction)
            action.append(SKAction.run{
                Audio.sharedInstance.playSound(soundFileName: Sound.reload.fileName)
                Audio.sharedInstance.player(with: Sound.reload.fileName)?.volume = 0.3
            })
            action.append(SKAction.run{
                bullet.reloaded()
            })
            
            if i == magazine.capacity - 1 {
                action.append(SKAction.run{ [unowned self] in
                    self.fire.isReloading = false
                    self.stateMachine?.enter(ShootingState.self)
                })
            }
            
            bullet.run(.sequence(action))
        }
        
    }
}
