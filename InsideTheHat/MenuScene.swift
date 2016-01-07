//
//  MenuScene.swift
//  InsideTheHat
//
//  Created by Jorge Jordán on 21/10/15.
//  Copyright © 2015 Jorge Jordán. All rights reserved.
//

import Foundation
import SpriteKit

class MenuScene: SKScene {
    private var background: SKSpriteNode!
    private var labelInitGame: SKLabelNode!
    
    override func didMoveToView(view: SKView) {
        self.initializeMenu()
    }
    
    func initializeMenu() {
        // Initialize menu background
        background = SKSpriteNode(imageNamed: "menu")
        background.zPosition = -1
        background.position = CGPoint(x:(view!.bounds.size.width/2), y: view!.bounds.size.height/2)
        
        // Add the background
        addChild(background)
        
        // Initialize the label with a font name
        labelInitGame = SKLabelNode(fontNamed:"Arial Bold")
        // Set color, size and position
        labelInitGame.fontColor = UIColor(red: 0.929, green: 0.129, blue: 0.486, alpha: 1.0)
        labelInitGame.fontSize = 60
        labelInitGame.position = CGPoint(x:view!.bounds.size.width/2, y:view!.bounds.size.height/2)
        // Set text
        labelInitGame.text = "Init Game"
        // Set node's name
        labelInitGame.name = "init_game_label"
        
        // Add the label to the scene
        addChild(labelInitGame)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            
            let location = touch.locationInNode(self)
            
            // Check if label touched
            if  self.nodeAtPoint(location).name == "init_game_label" {
                self.initGame()
            }
        }
    }
    
    func initGame() {
        // Create scene transition
        let sceneTransition = SKTransition.doorsOpenVerticalWithDuration(1.25)
        // Create next scene
        let gameScene = GameScene(size: view!.bounds.size)
        // Present next scene with transition
        self.view?.presentScene(gameScene, transition: sceneTransition)
    }
}