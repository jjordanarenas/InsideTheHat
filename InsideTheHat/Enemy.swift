//
//  Enemy.swift
//  InsideTheHat
//
//  Created by Jorge Jordán on 13/10/15.
//  Copyright © 2015 Jorge Jordán. All rights reserved.
//

import Foundation
import SpriteKit

enum EnemyType : UInt32 {
    case ENEMY_LEFT_RIGHT = 0
    case ENEMY_RIGHT_LEFT = 1
}
class Enemy: SKNode {
    internal var rail: SKSpriteNode!
    internal var puppet: SKSpriteNode!
    internal var leftAction: SKAction!
    internal var rightAction: SKAction!
    internal var enemyType: EnemyType
    
    init(type: EnemyType) {
        // Set enemy type
        enemyType = type
        
        // Call parent's init method'
        super.init()
        
        // Initialize rail sprite
        rail = SKSpriteNode(imageNamed: "rail")
        
        // Initialize puppet sprite
        setPuppetTexture()
        
        // Add sprites to the node
        addChild(rail)
        addChild(puppet)
    }
    
    func setPuppetTexture() {
        switch enemyType {
        case .ENEMY_LEFT_RIGHT:
            // Initialize the puppet if nil
            if (puppet == nil) {
                puppet = SKSpriteNode(imageNamed: "enemyLeft")
            } else {
                // Update texture
                puppet.texture = SKTexture(imageNamed: "enemyLeft")
            }
            break
            
        case .ENEMY_RIGHT_LEFT:
            // Initialize the puppet if nil
            if (puppet == nil) {
                puppet = SKSpriteNode(imageNamed: "enemyRight")
            } else {
                // Update texture
                puppet.texture = SKTexture(imageNamed: "enemyRight")
            }
            break
        }
        
        puppet.anchorPoint = CGPointMake(0.5, 0.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}