//
//  StageScene.swift
//  JWShooting
//
//  Created by 辛泽西 on 2021/1/21.
//

import Foundation
import SpriteKit
import GameplayKit

class StageScene: SKScene {
    
    //Nodes
    var rifle: SKSpriteNode?
    var crosshair: SKSpriteNode?
    var fire = FireButton()
    var duckScoreNode: SKNode!
    var targetScoreNode: SKNode!
    
    var magazine: Magazine!
    
    //Touches
    var selectedNodes: [UITouch : SKSpriteNode] = [:]
    
    //Game logic
    var manager: GameManager!
    
    //Game state machine
    var gameStateMachine: GKStateMachine!
    
    var touchDifferent: (CGFloat, CGFloat)?
    
    override func didMove(to view: SKView) {
        manager = GameManager(scene: self)
        loadUI()
        
        Audio.sharedInstance.playSound(soundFileName: Sound.musicLoop.fileName)
        Audio.sharedInstance.player(with: Sound.musicLoop.fileName)?.volume = 0.3
        Audio.sharedInstance.player(with: Sound.musicLoop.fileName)?.numberOfLoops = -1
        
        gameStateMachine = GKStateMachine(states: [
            ReadyState(fire: fire, magazine: magazine),
            ShootingState(fire: fire, magazine: magazine),
            ReloadingState(fire: fire, magazine: magazine)])
        
        gameStateMachine.enter(ReadyState.self)
        
        manager.activeDucks()
        manager.activeTargets()
    }
    
    //Score
    var totalScore = 0
    let targetScore = 10
    let duckScore = 10
    
    //Count
    var duckCount = 0
    var targetCount = 0
    
    var duckMoveDuration: TimeInterval!
    
    let targetXPosition: [Int] = [160, 240, 320, 400, 480, 560, 640]
    var usingTargetXPositon = Array<Int>()
    
    let ammunitionQuantity = 5
    
    var zPositionDecimal = 0.001 {
        didSet{
            if zPositionDecimal == 1{
                zPositionDecimal = 0.001
            }
        }
    }
}

//MARK: - GameLoop
extension StageScene{
    override func update(_ currentTime: TimeInterval) {
        syncRiflePosition()
        setBoundry()
    }
}

//MARK: - Touches
extension StageScene{
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let crosshair = crosshair else {return}
        //guard let touch = touches.first else {return}
        
        for touch in touches {
            let location = touch.location(in: self)
            if let node = self.atPoint(location) as? SKSpriteNode {
                if !selectedNodes.values.contains(crosshair) && !(node is FireButton){
                    selectedNodes[touch] = crosshair
                    let xDifference = touch.location(in: self).x - crosshair.position.x
                    let yDifference = touch.location(in: self).y - crosshair.position.y
                    touchDifferent = (xDifference, yDifference)
                }
                
                //Actual shooting
                if node is FireButton {
                    selectedNodes[touch] = fire
                    
                    //Check if is reloading
                    if !fire.isReloading{
                        fire.isPressed = true
                        magazine.shoot()
                        
                        //Play sound
                        Audio.sharedInstance.playSound(soundFileName: Sound.hit.fileName)
                        
                        if magazine.needToReload() {
                            gameStateMachine.enter(ReloadingState.self)
                        }
                        
                        //Find shoot node
                        let shootNode = manager.findShootNode(at: crosshair.position)
                        
                        guard let (scoreText, shotImageName) = manager.findTextAndImageName(for: shootNode.name) else {return}
                        
                        //Add shot image
                        manager.addShot(imageNamed: shotImageName, to: shootNode, on: crosshair.position)
                        
                        //Add score text
                        manager.addTextNode(on: crosshair.position, from: scoreText)
                        
                        //Play score sound
                        Audio.sharedInstance.playSound(soundFileName: Sound.score.fileName)
                        
                        
                        //Update score node
                        manager.update(text: String(manager.duckCount * manager.duckScore), node: &duckScoreNode)
                        manager.update(text: String(manager.targetCount * manager.targetScore), node: &targetScoreNode)
                        
                        //Animate shoot node
                        shootNode.physicsBody = nil
                        if let node = shootNode.parent{
                            node.run(.sequence([
                                                .wait(forDuration: 0.2),
                                                .scaleY(to: 0.0, duration: 0.2)]))
                        }
                    }
                }
            }
            
        }
        
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let crosshair = crosshair else {return}
        guard let touchDifferent = touchDifferent else {return}
        
        for touch in touches {
            if let node = selectedNodes[touch]{
                let location = touch.location(in: self)
                if node.name == "fire"{
                    
                } else {
                    let newCrosshairPositon = CGPoint(x: location.x - touchDifferent.0, y: location.y - touchDifferent.1)
                    
                    crosshair.position = newCrosshairPositon
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if selectedNodes[touch] != nil {
                if let fire = selectedNodes[touch] as? FireButton{
                    fire.isPressed = false
                }
                selectedNodes[touch] = nil
            }
        }
    }
    
    //15926392132
}

//MARK: - Action
extension StageScene{
    func loadUI(){
        //Rifle and Crosshair
        if let scene = scene{
            rifle = childNode(withName: "rifle") as? SKSpriteNode
            crosshair = childNode(withName: "crosshair") as? SKSpriteNode
            crosshair?.position = CGPoint(x: scene.frame.midX, y: scene.frame.midY)
        }
        //Add Icons
        let duckIcon = SKSpriteNode(imageNamed: Texture.duckIcon.imageName)
        duckIcon.position = CGPoint(x: 36, y: 365)
        duckIcon.zPosition = 11
        addChild(duckIcon)
        
        let targetIcon = SKSpriteNode(imageNamed: Texture.targetIcon.imageName)
        targetIcon.position = CGPoint(x: 36, y: 325)
        targetIcon.zPosition = 11
        addChild(targetIcon)
        
        //Add score nodes
        duckScoreNode = manager.generateTextNode(from: "0")
        duckScoreNode.position = CGPoint(x: 60, y: 365)
        duckScoreNode.zPosition = 11
        duckScoreNode.xScale = 0.5
        duckScoreNode.yScale = 0.5
        addChild(duckScoreNode)
        
        targetScoreNode = manager.generateTextNode(from: "0")
        targetScoreNode.position = CGPoint(x: 60, y: 325)
        targetScoreNode.zPosition = 11
        targetScoreNode.xScale = 0.5
        targetScoreNode.yScale = 0.5
        addChild(targetScoreNode)
        
        //Add fire button
        fire.position = CGPoint(x: 720, y: 80)
        fire.xScale = 1.7
        fire.yScale = 1.7
        fire.zPosition = 11
        addChild(fire)
        
        //Add empty magazine
        let magazineNode = SKNode()
        magazineNode.position = CGPoint(x: 760, y: 20)
        magazineNode.zPosition = 11
        
        var bullets = Array<Bullet>()
        
        for i in 0...manager.ammunitionQuantity - 1{
            let bullet = Bullet()
            bullet.position = CGPoint(x: -30 * i, y: 0)
            bullets.append(bullet)
            magazineNode.addChild(bullet)
        }
        
        magazine = Magazine(bullets: bullets)
        addChild(magazineNode)
        
    }
    
    
    
    func syncRiflePosition() {
        guard let rifle = rifle else {return}
        guard let crosshair = crosshair else {return}
        
        rifle.position.x = crosshair.position.x + 100
    }
    
    func setBoundry() {
        //guard let rifle = rifle else {return}
        guard let crosshair = crosshair else {return}
        
        if crosshair.position.x < scene!.frame.minX{
            crosshair.position.x = scene!.frame.minX
        }
        
        if crosshair.position.x > scene!.frame.maxX{
            crosshair.position.x = scene!.frame.maxX
        }
        
        if crosshair.position.y < scene!.frame.minY{
            crosshair.position.y = scene!.frame.minY
        }
        
        if crosshair.position.y > scene!.frame.maxY{
            crosshair.position.y = scene!.frame.maxY
        }
    }
    
    
    func generateDuck(hasTarget: Bool = false) -> Duck {
        var duck: SKSpriteNode
        var stick: SKSpriteNode
        var duckImageName: String
        var duckNodeName: String
        let node = Duck(hasTarget: hasTarget)
        var texture = SKTexture()
        
        if hasTarget{
            duckImageName = "duck_target/\(Int.random(in: 1...3))"
            texture = SKTexture(imageNamed: duckImageName)
            duckNodeName = "duck_target"
        }else{
            duckImageName = "duck/\(Int.random(in: 1...3))"
            texture = SKTexture(imageNamed: duckImageName)
            duckNodeName = "duck"
        }
        duck = SKSpriteNode(texture: texture)
        duck.name = duckNodeName
        duck.position = CGPoint(x: 0, y: 140)
        duck.xScale = 0.8
        duck.yScale = 0.8
        
        let physicsBody = SKPhysicsBody(texture: texture, alphaThreshold: 0.5, size: texture.size())
        physicsBody.affectedByGravity = false
        physicsBody.isDynamic = false
        
        duck.physicsBody = physicsBody
        
        stick = SKSpriteNode(imageNamed: "stick/\(Int.random(in: 1...2))")
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: 0, y: 0)
        stick.xScale = 0.8
        stick.yScale = 0.8
        
        node.addChild(stick)
        node.addChild(duck)
        
        return node
    }
    
    func generateTarget() -> Target {
        var target: SKSpriteNode
        var stick: SKSpriteNode
        let node = Target()
        let texture = SKTexture(imageNamed: "target/\(Int.random(in: 1...3))")
        
        target = SKSpriteNode(texture: texture)
        
        stick = SKSpriteNode(imageNamed: "stick_metal")
        
        target.xScale = 0.5
        target.yScale = 0.5
        stick.xScale = 0.5
        stick.yScale = 0.5
        
        target.position = CGPoint(x:0, y:95)
        target.name = "target"
        stick.anchorPoint = CGPoint(x: 0.5, y: 0)
        stick.position = CGPoint(x: 0, y: 0)
        
        node.addChild(stick)
        node.addChild(target)
        return node
    }
    
    func activeDucks_ss() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let duck = self.generateDuck(hasTarget: Bool.random())
            duck.position = CGPoint(x: -10, y: Int.random(in: 60...90))
            duck.zPosition = Int.random(in: 0...1) == 0 ? 4 : 6
            duck.zPosition += CGFloat(self.zPositionDecimal)
            self.zPositionDecimal += 0.001
            
            self.addChild(duck)
            
            if duck.hasTarget {
                self.duckMoveDuration = TimeInterval(Int.random(in: 2...4))
            }else{
                self.duckMoveDuration = TimeInterval(Int.random(in: 5...7))
            }
            duck.run(.sequence([
                .moveTo(x: 850, duration: self.duckMoveDuration),
                .removeFromParent()]))
        }
    }
    
    func activeTargets_ss() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            let target = self.generateTarget()
            var xPosition = self.targetXPosition.randomElement()!
            
            while self.usingTargetXPositon.contains(xPosition) {
                xPosition = self.targetXPosition.randomElement()!
            }
            
            self.usingTargetXPositon.append(xPosition)
            target.position = CGPoint(x: xPosition, y: Int.random(in: 128...145))
            target.zPosition = 1
            target.yScale = 0
            self.addChild(target)
            
            let physicsBody = SKPhysicsBody(circleOfRadius: 35.5)
            physicsBody.affectedByGravity = false
            physicsBody.isDynamic = false
            physicsBody.allowsRotation = false
            
            target.run(.sequence([.scaleY(to: 1, duration: 0.2),
                                  .run{
                                    if let node = target.childNode(withName: "target") {
                                        node.physicsBody = physicsBody
                                    }
                                  },
                                  .wait(forDuration: TimeInterval(Int.random(in: 3...4))),
                                  .scaleY(to: 0, duration: 0.2),
                                  .run {
                                    self.usingTargetXPositon.remove(at: self.usingTargetXPositon.firstIndex(of: xPosition)!)
                                  }]))
        }
    }
    
    func findShootNode_ss(at position: CGPoint) -> SKSpriteNode {
        var shootNode = SKSpriteNode()
        var biggestZPosition: CGFloat = 0.0
        
        self.physicsWorld.enumerateBodies(at: position) { (body, pointer) in
            guard let node = body.node as? SKSpriteNode else {return}
            
            if node.name == "duck" || node.name == "duck_target" || node.name == "target" {
                if let parentNode = node.parent {
                    if parentNode.zPosition > biggestZPosition{
                        biggestZPosition = parentNode.zPosition
                        shootNode = node
                    }
                }
            }
        }
        
        return shootNode
    }
    
    
    func addShot_ss(imageNamed imageName: String, to node: SKSpriteNode, on position: CGPoint){
        let convertedPosition = self.convert(position, to: node)
        let shot = SKSpriteNode(imageNamed: imageName)
        
        shot.position = convertedPosition
        node.addChild(shot)
        
        shot.run(.sequence([
                            .wait(forDuration: 2),
                            .fadeAlpha(to: 0, duration: 0.3),
                            .removeFromParent()]))
    }
    
    func generateTextNode_ss(from text: String, leadingAnchorPoint: Bool = true) -> SKNode {
        let node = SKNode()
        var width: CGFloat = 0.0
        
        for charactor in text {
            var charactorNode = SKSpriteNode()
            
            if charactor == "0" {
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.zero.textureName)
            }else if charactor == "1"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.one.textureName)
            }else if charactor == "2"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.two.textureName)
            }else if charactor == "3"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.three.textureName)
            }else if charactor == "4"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.four.textureName)
            }else if charactor == "5"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.five.textureName)
            }else if charactor == "6"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.six.textureName)
            }else if charactor == "7"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.seven.textureName)
            }else if charactor == "8"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.eight.textureName)
            }else if charactor == "9"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.nine.textureName)
            }else if charactor == "+"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.plus.textureName)
            }else if charactor == "*"{
                charactorNode = SKSpriteNode(imageNamed: ScoreNumber.multiplication.textureName)
            }else{
                continue
            }
            
            node.addChild(charactorNode)
            
            charactorNode.anchorPoint = CGPoint(x: 0, y: 0.5)
            charactorNode.position = CGPoint(x: width, y: 0.0)
            
            width += charactorNode.size.width
        }
        
        if leadingAnchorPoint{
            return node
        } else {
            let anotherNode = SKNode()
            
            anotherNode.addChild(node)
            node.position = CGPoint(x: -width/2, y: 0)
            
            return anotherNode
        }
    }
    
    func addTextNode_ss(on position: CGPoint, from text: String){
        let scorePosition = CGPoint(x: position.x + 10, y: position.y + 30)
        let scoreNode = generateTextNode_ss(from: text)
        scoreNode.position = scorePosition
        scoreNode.zPosition = 9
        scoreNode.xScale = 0.5
        scoreNode.yScale = 0.5
        self.addChild(scoreNode)
        
        scoreNode.run(.sequence([
                                    .wait(forDuration: 0.5),
                                    .fadeOut(withDuration: 0.2),
                                    .removeFromParent()]))
    }
    
    func findTextAndImageName_ss(for nodeName: String?) -> (String, String)?{
        var scoreText = ""
        var shotImageName = ""
        
        switch nodeName{
        case "duck":
            scoreText = "+\(duckScore)"
            duckCount += 1
            totalScore += duckScore
            shotImageName = Texture.shotBlue.imageName
        case "duck_target":
            scoreText = "+\(duckScore + targetScore)"
            duckCount += 1
            targetCount += 1
            totalScore += duckScore + targetScore
            shotImageName = Texture.shotBlue.imageName
        case "target":
            scoreText = "+\(targetScore)"
            targetCount += 1
            totalScore += targetScore
            shotImageName = Texture.shotBrown.imageName
        default:
            return nil
        }
        
        return (scoreText, shotImageName)
    }
    
    func update_ss(text: String, node: inout SKNode, leadingAnchorPoint: Bool = true){
        let position = node.position
        let zPosition = node.zPosition
        let xScale = node.xScale
        let yScale = node.yScale
        
        node.removeFromParent()
        
        node = generateTextNode_ss(from: text)
        node.position = position
        node.zPosition = zPosition
        node.xScale = xScale
        node.yScale = yScale
        
        self.addChild(node)
    }
    
}
