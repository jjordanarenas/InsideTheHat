//
//  GameScene.swift
//  InsideTheHat
//
//  Created by Jorge Jordán on 12/09/15.
//  Copyright (c) 2015 Jorge Jordán. All rights reserved.
//

import GoogleMobileAds
import SpriteKit
import AVFoundation

enum TutorialSteps : UInt32 {
    case TUTORIAL_STEP_1 = 0
    case TUTORIAL_STEP_2 = 1
    case TUTORIAL_STEP_3 = 2
    case TUTORIAL_STEP_4 = 3
    case TUTORIAL_STEP_5 = 4
    case TUTORIAL_ENDED = 5
}

class GameScene: SKScene, GADInterstitialDelegate {
    private var rabbit: SKSpriteNode!
    private var wall: SKSpriteNode!
    private var leftDoor: SKSpriteNode!
    private var centerDoor: SKSpriteNode!
    private var rightDoor: SKSpriteNode!
    private var isCollisionDetected: Bool = false
    private var labelScore: SKLabelNode!
    private var resetWave: Bool = false
    private var score: Int = 0
    private var backgroundMusic:AVAudioPlayer!
    private var wrongDoorSound: AVAudioPlayer!
    private var correctDoorSound: AVAudioPlayer!
    private var isMovementAllowed: Bool = true
    private let kRunningSpeed: CGFloat = 250.0
    private var enemy: Enemy!
    private var isEnemyCollisionDetected: Bool = false
    private var backgroundBottom: SKSpriteNode!
    private var backgroundTop: SKSpriteNode!
    private var treesBottom: SKSpriteNode!
    private var treesTop: SKSpriteNode!
    private var lastFrameTime : CFTimeInterval = 0
    private var deltaTime : CFTimeInterval = 0
    private let kBackgroundSpeed: CGFloat = 250.0
    private let kTreesSpeed: CGFloat = 450.0
    private var jumpingRabbitFrames : [SKTexture]!
    private var smashingRabbitFrames : [SKTexture]!
    private let kNumJumpTextures = 11
    private let kNumSmashTextures = 11
    private var redLifeBar: SKShapeNode!
    private var greenLifeBar: SKShapeNode!
    private let kMaxNumLifePoints = 10
    private var lifePoints: Int = 0
    private var labelGameOver: SKLabelNode!
    private var labelResetGame: SKLabelNode!
    private var tutorialStep: TutorialSteps = .TUTORIAL_STEP_1
    private var tutorialImage: SKSpriteNode!
    private var labelTutorial: SKLabelNode!
    private var tutorialFrame: SKShapeNode!
    private var labelBestScore: SKLabelNode!
    private var bestScore: Int = 0
    private var userDefaults: NSUserDefaults!
    private var kUserDefaultBestScore = "user_default_best_score"
    private var isTutorialCompleted: Bool = false
    private var kUserDefaultTutorialCompleted = "user_default_tutorial_completed"
    private var maxWaves: Int = 0
    private var waveNumber: Int = 1
    private var leftDoorsInfo: [String]!
    private var centerDoorsInfo: [String]!
    private var rightDoorsInfo: [String]!
    private var soundOffOnButton: UIButton!
    private var isSoundOn: Bool = true
    private var interstitial: GADInterstitial!
    var viewController: GameViewController!
    
    override func didMoveToView(view: SKView) {
        self.readLevelInfo()
        self.initializeUserDefaults()
        // If it's the first time the tutorial appears
        if !isTutorialCompleted && tutorialStep != .TUTORIAL_ENDED {
            self.initializeTutorial()
        }
        self.preloadInterstitial()
        self.initializeMusic()
        self.initializeMainCharacter()
        self.initializeWall()
        self.initializeWallMovement()
        self.initializeDoors()
    	self.initializeDoorsMovement()
        self.initializeLabels()
        self.initializeEnemy()
        self.initializeParallaxEffect()
        self.initializeAnimations()
        self.startJumpingRabbit()
        self.initializeLifeBar()
        self.initializeSoundOffOnButton()
    }
    
    func initializeMainCharacter() {
        // Creating the rabbit sprite using an image file and adding it to the scene
        rabbit = SKSpriteNode(imageNamed: "rabbit")
        // Positioning the rabbit centered
        rabbit.position = CGPoint(x:(view!.bounds.size.width/2), y: rabbit.size.height)
        // Specifying zPosition
        rabbit.zPosition = 2

        addChild(rabbit)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            if isMovementAllowed {
                // Moving the rabbit to the touched position
                let location = touch.locationInNode(self)
                if !isTutorialCompleted && self.tutorialStep != .TUTORIAL_ENDED && self.nodeAtPoint(location).name == "tutorial_frame" {
                    self.updateTutorial()
                } else if isTutorialCompleted || self.tutorialStep == .TUTORIAL_ENDED {
                    self.moveRabbitToNextLocation(location)
                }
            }
            
            // Check if label touched
            if  self.nodeAtPoint(touch.locationInNode(self)).name == "reset_label" {
                
                self.restartGame()
            }
        }
    }
    
    func moveRabbitToNextLocation(touchLocation: CGPoint) {
        let rabbitSpeed: CGFloat = 360.0
                
        var moveAction:SKAction!
        var duration: CGFloat = 0.0
        var nextPosition: CGPoint
                
        if touchLocation.x <= view!.bounds.size.width/3 {
            // Setting the next position
            nextPosition = CGPoint(x: leftDoor.position.x, y: rabbit.position.y)
            // We want the rabbit to move on a constant speed
            duration = self.distanceBetween(point: rabbit.position, andPoint: nextPosition) / rabbitSpeed
            // Move the rabbit to the touched position
            moveAction = SKAction.moveToX(nextPosition.x, duration: Double(duration))
        } else if touchLocation.x > view!.bounds.size.width/3 && touchLocation.x <= 2 * view!.bounds.size.width/3 {
            // Setting the next position
            nextPosition = CGPoint(x: view!.bounds.size.width/2, y: rabbit.position.y)
            // We want the rabbit to move on a constant speed
            duration = self.distanceBetween(point: rabbit.position, andPoint: nextPosition) / rabbitSpeed
            // Move the rabbit to the touched position
            moveAction = SKAction.moveToX(nextPosition.x, duration: Double(duration))
        } else {
            // Setting the next position
            nextPosition = CGPoint(x: rightDoor.position.x, y: rabbit.position.y)
            // We want the rabbit to move on a constant speed
            duration = self.distanceBetween(point: rabbit.position, andPoint: nextPosition) / rabbitSpeed
            // Move the rabbit to the touched position
            moveAction = SKAction.moveToX(nextPosition.x, duration: Double(duration))
        }
        // Executing the action
        rabbit.runAction(moveAction)
    }
        
    func distanceBetween(point p1:CGPoint, andPoint p2:CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }
    
    func initializeWall() {
        // Creating the wall sprite using an image file
        wall = SKSpriteNode(imageNamed: "wall")
        // Positioning the wall centered
        wall.position = CGPoint(x:(view!.bounds.size.width/2), y: view!.bounds.size.height + wall.frame.size.height/2)
        // Specifying zPosition
        wall.zPosition = 3
        // Adding the wall to the scene
        addChild(wall)
    }
    
    func initializeWallMovement() {
        // Setting the wall's final position
        let nextWallPosition = CGPoint(x: wall.position.x, y: -wall.frame.size.height/2)
        // We want the wall to move on a constant speed
        let duration = self.distanceBetween(point: wall.position, andPoint: nextWallPosition) / kRunningSpeed
        // Move the wall to the next position
        let moveWallAction = SKAction.moveToY(nextWallPosition.y, duration: Double(duration))
        
        // Reset the wall's position
        let resetPositionAction = SKAction.runBlock {
            self.wall.position = CGPoint(x:(self.view!.bounds.size.width/2), y: self.view!.bounds.size.height + self.wall.frame.size.height/2)
        }
        
        // Creating a delay action
        let delayAction = SKAction.waitForDuration(2.0)
        let sequence = SKAction.sequence([moveWallAction, resetPositionAction, delayAction])
        // Running the non-ending sequence
        wall.runAction(SKAction.repeatActionForever(sequence))
    }

    func initializeDoors() {
        // Initializing left door
        self.setDoorAttributes("left")
        // Positioning left door
        leftDoor.position = CGPoint(x:(view!.bounds.size.width/2) - (25 * leftDoor.frame.size
            .width / 20), y: self.view!.bounds.size.height + leftDoor.frame.size.height/2)
        // Specifying zPosition
        leftDoor.zPosition = 1
        // Adding the door to the scene
        addChild(leftDoor)
        
        // Initializing center door
        self.setDoorAttributes("center")
        // Positioning center door
        centerDoor.position = CGPoint(x:(view!.bounds.size.width/2), y: self.view!.bounds.size.height + centerDoor.frame.size.height/2)
        // Specifying zPosition
        centerDoor.zPosition = 1
        // Adding the door to the scene
        addChild(centerDoor)
        
        // Initializing right door
        self.setDoorAttributes("right")
        // Positioning right door
        rightDoor.position = CGPoint(x:(view!.bounds.size.width/2) + (25 * rightDoor.frame.size
            .width / 20), y: self.view!.bounds.size.height + rightDoor.frame.size.height/2)
        // Specifying zPosition
        rightDoor.zPosition = 1
        // Adding the door to the scene
        addChild(rightDoor)
    }

    func setDoorAttributes(position: String) {
        switch position {
            case "wrong_left_door", "correct_left_door", "left":
                // Setting the door sprite randomly
                if leftDoorsInfo[waveNumber-1] == "wrong" {
                    // Initialize the door if null
                    if (leftDoor == nil) {
                        leftDoor = SKSpriteNode(imageNamed: "wrong_door")
                    }
                    // Update texture and name attributes
                    leftDoor.texture = SKTexture(imageNamed: "wrong_door")
                    leftDoor.name = "wrong_left_door"
                } else {
                    // Initialize the door if null
                    if (leftDoor == nil) {
                        leftDoor = SKSpriteNode(imageNamed: "correct_door")
                    }
                    // Update texture and name attributes
                    leftDoor.texture = SKTexture(imageNamed: "correct_door")
                    leftDoor.name = "correct_left_door"
                }
            
            case "wrong_center_door", "correct_center_door", "center":
                // Setting the door sprite randomly
                if centerDoorsInfo[waveNumber-1] == "wrong" {
                    // Initialize the door if null
                    if (centerDoor == nil) {
                        centerDoor = SKSpriteNode(imageNamed: "wrong_door")
                    }
                    // Update texture and name attributes
                    centerDoor.texture = SKTexture(imageNamed: "wrong_door")
                    centerDoor.name = "wrong_center_door"
                } else {
                    // Initialize the door if null
                    if (centerDoor == nil) {
                        centerDoor = SKSpriteNode(imageNamed: "correct_door")
                    }
                    // Update texture and name attributes
                    centerDoor.texture = SKTexture(imageNamed: "correct_door")
                    centerDoor.name = "correct_center_door"
                }

            case "wrong_right_door", "correct_right_door", "right":
                // Setting the door sprite randomly
                if rightDoorsInfo[waveNumber-1] == "wrong" {
                    // Initialize the door if null
                    if (rightDoor == nil) {
                        rightDoor = SKSpriteNode(imageNamed: "wrong_door")
                    }
                    // Update texture and name attributes
                    rightDoor.texture = SKTexture(imageNamed: "wrong_door")
                    rightDoor.name = "wrong_right_door"
                } else {
                    // Initialize the door if null
                    if (rightDoor == nil) {
                        rightDoor = SKSpriteNode(imageNamed: "correct_door")
                    }
                    // Update texture and name attributes
                    rightDoor.texture = SKTexture(imageNamed: "correct_door")
                    rightDoor.name = "correct_right_door"
                }

            default: break
        }
    }

    func initializeDoorsMovement() {
        var leftDoorAction: SKAction!
        var centerDoorAction: SKAction!
        var rightDoorAction: SKAction!
        
        self.enumerateChildNodesWithName("*_door") {
            node, stop in

            // Setting the door's final position
            let nextDoorPosition = CGPoint(x: node.position.x, y: -(self.wall.frame.size.height - node.frame.size.height / 2))
            // We want the door to move on a constant speed
            let duration = self.distanceBetween(point: node.position, andPoint: nextDoorPosition) / self.kRunningSpeed
            // Move the door to the next position
            let moveDoorAction = SKAction.moveToY(nextDoorPosition.y, duration: Double(duration))

            // Reset the door's position
            let resetPositionAction = SKAction.runBlock {
                // Reset door's attributes
                self.setDoorAttributes(node.name!)
                node.position = CGPoint(x:node.position.x, y: self.view!.bounds.size.height + node.frame.size.height/2)

                // Make door visible
                node.hidden = false
                // The doors wave will restart
                self.resetWave = true
            }

            // Preparing the actions
            let delayAction = SKAction.waitForDuration(2.0)
            let sequence = SKAction.sequence([moveDoorAction, resetPositionAction, delayAction])
        
            // Set the sequence into the correct door
            switch node.name! {
                case "wrong_left_door", "correct_left_door":
                    leftDoorAction = SKAction.repeatActionForever(sequence)
                case "wrong_center_door", "correct_center_door":
                    centerDoorAction = SKAction.repeatActionForever(sequence)
                case "wrong_right_door", "correct_right_door":
                    rightDoorAction = SKAction.repeatActionForever(sequence)
                default: break
            }
        }
    
        // Running door’s actions
        leftDoor.runAction(leftDoorAction)
        centerDoor.runAction(centerDoorAction)
        rightDoor.runAction(rightDoorAction)

    }
    
    func detectCollisions() {
        self.enumerateChildNodesWithName("*_door") {
            node, stop in
            
            // Check if the frames intersect
            if node.frame.intersects(self.rabbit.frame) && (node.position.y - node.frame.height/2) <= self.rabbit.position.y {
                if node.name?.containsString("wrong") == true {
                    // Collision detected
              		self.isCollisionDetected = true
                
                    // Reproduce sound
                    self.playWrongDoorSound()

                    // Stop jumping animation
                    self.rabbit.removeActionForKey("jumping_rabbit")
                    // Run smashing animation
                    self.startSmashingRabbit()
                    
                    self.showInterstitial()
                } else {
                    // Reproduce sound
                    self.playCorrectDoorSound()
                }
            // Make door invisible
            node.hidden = true
            // Disable movement
            self.isMovementAllowed = false
            }
        }
        
        // Check puppet collision
        if enemy.puppet.frame.intersects(rabbit.frame) && (enemy.puppet.position.y - enemy.puppet.frame.height/2) <= rabbit.position.y {
            
            // Collision detected
            isEnemyCollisionDetected = true
            
            // Reproduce sound
            self.playWrongDoorSound()
            
            // Stop jumping animation
            self.rabbit.removeActionForKey("jumping_rabbit")
            // Run smashing animation
            self.startSmashingRabbit()
        }
    }

    func initializeLabels() {
        // Initialize the label with a font name
        labelScore = SKLabelNode(fontNamed:"MarkerFelt-Thin")
        // Set color, size and position
        labelScore.fontColor = UIColor.blackColor()
        labelScore.fontSize = 20
        labelScore.position = CGPoint(x:(view!.bounds.size.width - 2 * labelScore.fontSize), y:(view!.bounds.size.height - 2 * labelScore.fontSize))
        // Specifying zPosition
        labelScore.zPosition = 5
        labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        // Set text
        labelScore.text = "Score: \(score)"
        
        // Add the label to the scene
        addChild(labelScore)
        
        // Initialize the label as a copy
        labelBestScore = labelScore.copy() as! SKLabelNode
        // Set color, size and position
        labelBestScore.fontColor = UIColor.orangeColor()
        labelBestScore.position.y = labelScore.position.y - 30
        // Set text
        labelBestScore.text = "Best: \(bestScore)"
        
        // Add the label to the scene
        addChild(labelBestScore)
    }

    func initializeWave() {
        if self.isCollisionDetected {
            self.lifePoints--
            self.updateLifeBar()
            // If we have lost all the life points
            if self.lifePoints == 0 {
                self.gameOver()
            }
            
        // Revert flag's value
            self.isCollisionDetected = false
        } else {
            // Update score if collision avoided
            self.score += 10
            self.labelScore.text = "Score: \(self.score)"
        }
        //Update flag
        self.resetWave = false
        // Enable movement
        self.isMovementAllowed = true
        
        // Increase wave
        if waveNumber < maxWaves {
            waveNumber++
        } else {
            waveNumber = 1
        }
    }

    func initializeMusic() {
	     // Specifying the file's route in the project'
        var path = NSBundle.mainBundle().pathForResource("insidethehat_background", ofType:"mp3")
        var fileURL = NSURL(fileURLWithPath: path!)
        
        do {
            // Initialize variable
            backgroundMusic = try AVAudioPlayer(contentsOfURL: fileURL)
            // Reproduce song indefinitely
            backgroundMusic.numberOfLoops = -1
            // Play music
            if isSoundOn {
                backgroundMusic.play()
            }
            // Preparing wrong door sound
            path = NSBundle.mainBundle().pathForResource("wrong_door", ofType:"mp3")
            fileURL = NSURL(fileURLWithPath: path!)
            wrongDoorSound = try AVAudioPlayer(contentsOfURL: fileURL)
            wrongDoorSound.volume = 1.0
            wrongDoorSound.prepareToPlay()
            
            // Preparing correct door sound
            path = NSBundle.mainBundle().pathForResource("correct_door", ofType:"mp3")
            fileURL = NSURL(fileURLWithPath: path!)
            correctDoorSound = try AVAudioPlayer(contentsOfURL: fileURL)
            correctDoorSound.volume = 0.9
            correctDoorSound.prepareToPlay()

  	    } catch {
            print("Error playing background music")
        }
    }

    func playWrongDoorSound() {
        if isSoundOn {
            // Play wrong door sound
            wrongDoorSound.play()
        }
    }

    func playCorrectDoorSound() {
        if isSoundOn {
            // Play correct door sound
            correctDoorSound.play()
        }
    }

    func initializeEnemy() {
        // Create enemy type
        let enemyType: EnemyType = EnemyType(rawValue: arc4random_uniform(2))!
        
        // Initialize the enemy with type
        enemy = Enemy(type: enemyType)
        
        // Specify zPosition values
        enemy.rail.zPosition = 0
        enemy.puppet.zPosition = 1
        
        // Set initial position
        enemy.rail.position = CGPoint(x:(view!.bounds.size.width/2), y: view!.bounds.size.height + wall.frame.size.height/2)
        
        switch enemyType {
        case .ENEMY_LEFT_RIGHT:
            // Set enemy's position
            enemy.puppet.position = CGPoint(x:leftDoor.position.x, y: view!.bounds.size.height + wall.frame.size.height/2)
            break
            
        case .ENEMY_RIGHT_LEFT:
            // Set enemy's position
            enemy.puppet.position = CGPoint(x:rightDoor.position.x, y: view!.bounds.size.height + wall.frame.size.height/2)
            break
        }
        
        // Add enemy to the scene
        addChild(enemy)
        
        // Initialize enemy's actions
        initializeEnemyActions()
    }
    
    func initializeEnemyActions() {
        // Enemy's lateral speed
        let enemyLateralSpeed: CGFloat = 250.0
        
        // Initialize enemy's type
        var enemyType: EnemyType = .ENEMY_LEFT_RIGHT
        
        // Sprite's actions
        var verticalMovementAction: SKAction!
        var lateralMovementAction: SKAction!
        
        // Setting the rail's final position
        let nextRailPosition = CGPoint(x: enemy.rail.position.x, y: -wall.frame.size.height / 2)
        // We want the rail to move on a constant speed
        let railDuration = self.distanceBetween(point: enemy.rail.position, andPoint: nextRailPosition) / self.kRunningSpeed
        // Move the rail to the next position
        let moveRailAction = SKAction.moveToY(nextRailPosition.y, duration: Double(railDuration))
        
        // Reset the rail's position
        let resetPositionAction = SKAction.runBlock {
            // If the rabbit collides with the enemy
            if self.isEnemyCollisionDetected {
                self.lifePoints--
                self.updateLifeBar()
                // If we have lost all the life points
                if self.lifePoints == 0 {
                    self.gameOver()
                } else {
                    self.showInterstitial()
                }
            }
            
            // Reset flag
            self.isEnemyCollisionDetected = false
            
            // Reset rail's position
            self.enemy.rail.position = CGPoint(x:self.view!.bounds.size.width/2, y: self.view!.bounds.size.height + self.wall.frame.size.height/2)
            
            // Reset enemy's type
            enemyType = EnemyType(rawValue: arc4random_uniform(2))!
            self.enemy.enemyType = enemyType
            
            // Stop previous action
            self.enemy.puppet.removeActionForKey("puppet_action")
            
            switch enemyType {
            case .ENEMY_LEFT_RIGHT:
                // Reset texture
                self.enemy.setPuppetTexture()
                // Reset position
                self.enemy.puppet.position = CGPoint(x:self.leftDoor.position.x, y: self.view!.bounds.size.height + self.wall.frame.size.height/2)
                // Run action
                self.enemy.puppet.runAction(SKAction.repeatActionForever(self.enemy.leftAction), withKey: "puppet_action")
                break
                
            case .ENEMY_RIGHT_LEFT:
                // Reset texture
                self.enemy.setPuppetTexture()
                // Reset position
                self.enemy.puppet.position = CGPoint(x:self.rightDoor.position.x, y: self.view!.bounds.size.height + self.wall.frame.size.height/2)
                
                // Run action               
                self.enemy.puppet.runAction(SKAction.repeatActionForever(self.enemy.rightAction), withKey: "puppet_action")
                break
            }
        }
        
        // Delay action
        let delayAction = SKAction.waitForDuration(2.0)
        
        // Creating sequence of actions
        let railSequence = SKAction.sequence([delayAction, moveRailAction, resetPositionAction])
        
        // Initializing vertical movement action
        verticalMovementAction = SKAction.repeatActionForever(railSequence)
        
        // We want the puppet to move on a constant speed
        let puppetDuration = self.distanceBetween(point: rightDoor.position, andPoint: leftDoor.position) / enemyLateralSpeed
        
        // Initialize lateral actions
        let moveEnemyLeftAction = SKAction.moveToX(leftDoor.position.x, duration: Double(puppetDuration))
        let moveEnemyRightAction = SKAction.moveToX(rightDoor.position.x, duration: Double(puppetDuration))
        
        // Initialize sequence of actions
        enemy.leftAction = SKAction.sequence([moveEnemyRightAction, moveEnemyLeftAction])
        enemy.rightAction = SKAction.sequence([moveEnemyLeftAction, moveEnemyRightAction])
        
        switch enemy.enemyType {
        case .ENEMY_LEFT_RIGHT:
            // Initializing puppet's action
            lateralMovementAction = SKAction.repeatActionForever(enemy.leftAction)
            break
            
        case .ENEMY_RIGHT_LEFT:
            // Initializing puppet's action
            lateralMovementAction = SKAction.repeatActionForever(enemy.rightAction)
            break
        }
        
        // Running vertical movement actions
        enemy.rail.runAction(verticalMovementAction)
        enemy.puppet.runAction(verticalMovementAction)
        
        // Running lateral movement action
        enemy.puppet.runAction(lateralMovementAction, withKey: "puppet_action")
    }
    
    func initializeParallaxEffect() {
        // Initialize background layers
        backgroundBottom = SKSpriteNode(imageNamed: "background")
        backgroundBottom.anchorPoint = .zero
        backgroundBottom.zPosition = -1
        
        // Copy the previous node into another
        backgroundTop = backgroundBottom.copy() as! SKSpriteNode
        // Set top layer position
        backgroundTop.position = CGPoint(x: backgroundBottom.position.x, y: backgroundBottom.position.y + backgroundBottom.size.height)
        
        // Initialize tree layers
        treesBottom = SKSpriteNode(imageNamed: "trees")
        treesBottom.zPosition = 4
        treesBottom.position = CGPoint(x:(view!.bounds.size.width/2), y: view!.bounds.size.height/2)
        
        // Copy the previous node into another
        treesTop = treesBottom.copy() as! SKSpriteNode
        // Set top layer position
        treesTop.position = CGPoint(x: treesBottom.position.x, y: treesBottom.position.y + treesBottom.size.height)
        
        // Add background layers to the scene
        addChild(backgroundBottom)
        addChild(backgroundTop)
        
        // Add tree layers to the scene
        addChild(treesBottom)
        addChild(treesTop)
    }
    
    func updateParallaxLayers(currentTime: CFTimeInterval) {
        // Initialize the last frame value
        if lastFrameTime <= 0 {
            lastFrameTime = currentTime
        }
        
        // Update the delta time
        deltaTime = currentTime - lastFrameTime
        
        // Update the last frame time
        lastFrameTime = currentTime
        
        // Apply the delta to the layer's position
        self.moveParallaxLayer(backgroundBottom, topLayer:backgroundTop, speed:kBackgroundSpeed)
        self.moveParallaxLayer(treesBottom, topLayer:treesTop,
            speed:kTreesSpeed)
    }
    
    func moveParallaxLayer(bottomLayer : SKSpriteNode, topLayer : SKSpriteNode, speed : CGFloat) -> Void {
        // Initialize next position
        var nextPosition = CGPointZero
        
        for parallaxLayer in [bottomLayer, topLayer] {
            // Update next position
            nextPosition = parallaxLayer.position
            nextPosition.y -= CGFloat(speed * CGFloat(deltaTime))
            // Update layer position
            parallaxLayer.position = nextPosition
            
            // If the layer is out of view
            if parallaxLayer.frame.maxY < self.frame.minY {
                // Reset layer position
                parallaxLayer.position =
                    CGPoint(x: parallaxLayer.position.x, y: parallaxLayer.position.y +                            parallaxLayer.size.height * 2)
            }
        }
    }
    
    func initializeAnimations() {
        // Reference for the atlas
        let animationsAtlas = SKTextureAtlas(named: "AnimationsImages")
        // Initialize arrays
        var auxJumpFrames = [SKTexture]()
        var auxSmashFrames = [SKTexture]()
        // Variable for the textures
        var jumpTexture: String
        var smashTexture: String
        
        for var i = 1; i <= kNumJumpTextures; i++ {
            // Get the corresponding texture
            jumpTexture = "rabbitJump\(i)"
            // Add texture to the array
            auxJumpFrames.append(animationsAtlas.textureNamed(jumpTexture))
        }
        
        for var i = 1; i <= kNumSmashTextures; i++ {
            // Get the corresponding texture
            smashTexture = "rabbitSmash\(i)"
            // Add texture to the array
            auxSmashFrames.append(animationsAtlas.textureNamed(smashTexture))
        }
        
        // Initialize the array of textures
        jumpingRabbitFrames = auxJumpFrames
        smashingRabbitFrames = auxSmashFrames
    }
    
    func startJumpingRabbit() {
        // Run jumping animation       
        rabbit.runAction(SKAction.repeatActionForever(SKAction.animateWithTextures(jumpingRabbitFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey:"jumping_rabbit")
    }
    
    func startSmashingRabbit() {
        // Create smashing animation
        let smashingRabbitAnimation = SKAction.animateWithTextures(smashingRabbitFrames,
            timePerFrame: 0.05,
            resize: false,
            restore: true)
        // Action to restart the jumping action
        let resetJumpingAnimation = SKAction.runBlock {
            self.startJumpingRabbit()
        }
        // Create sequence with the desired actions
        let sequence = SKAction.sequence([smashingRabbitAnimation, resetJumpingAnimation])
        // Run the sequence
        rabbit.runAction(sequence)
    }
    
    func initializeLifeBar() {
        // Initialize life points
        lifePoints = kMaxNumLifePoints
        
        // Initialize red bar
        redLifeBar = SKShapeNode(rectOfSize: CGSize(width: self.view!.bounds.width/2, height: 20.0))
        // Set bar's position
        redLifeBar.position.x = redLifeBar.frame.size.width/2 + 20
        redLifeBar.position.y = labelScore.position.y + labelScore.frame.size.height/2
        // No border
        redLifeBar.lineWidth = 0
        // Specify zPosition
        redLifeBar.zPosition = 5
        // Set bar color
        redLifeBar.fillColor = UIColor.redColor()
        
        // Initialize green bar
        greenLifeBar = SKShapeNode(rectOfSize: CGSize(width: self.view!.bounds.width/2, height: 20.0))
        // Set bar's position
        greenLifeBar.position.x = redLifeBar.position.x
        greenLifeBar.position.y = redLifeBar.position.y
        // No border
        greenLifeBar.lineWidth = 0
        // Specify zPosition
        greenLifeBar.zPosition = 5
        // Set bar color
        greenLifeBar.fillColor = UIColor.greenColor()
        
        // Add bars to the scene
        addChild(redLifeBar)
        addChild(greenLifeBar)
    }
    
    func updateLifeBar() {
        // Previous bar's position
        let lastPosition = greenLifeBar.position.x
        // Previous bar's width
        let lastWidth = greenLifeBar.frame.width
        // Size of lost life
        let lostLife = redLifeBar.frame.width/CGFloat(kMaxNumLifePoints)
        
        // Delete previous green bar
        greenLifeBar.removeFromParent()
        // Initialize new green bar
        greenLifeBar = SKShapeNode(rectOfSize: CGSize(width: lastWidth - lostLife, height: 20.0))
        // Set bar position
        greenLifeBar.position.x = lastPosition - lostLife/2
        greenLifeBar.position.y = redLifeBar.position.y
        // No border
        greenLifeBar.lineWidth = 0
        // Specify zPosition
        greenLifeBar.zPosition = 5
        // Set bar color
        greenLifeBar.fillColor = UIColor.greenColor()
        
        // Add bar to the scene
        addChild(greenLifeBar)
    }
    
    func gameOver() {
        // Initialize the label with a font name
        labelGameOver = SKLabelNode(fontNamed:"MarkerFelt-Thin")
        // Set color, size and position
        labelGameOver.fontColor = UIColor.redColor()
        labelGameOver.fontSize = 60
        labelGameOver.position = CGPoint(x:view!.bounds.size.width/2, y:view!.bounds.size.height)
        // Specifying zPosition
        labelGameOver.zPosition = 5
        // Set text
        labelGameOver.text = "GAME OVER"
        // Add the label to the scene
        addChild(labelGameOver)
        
        // Update best score
        self.updateBestScore()
        
        // Creating movement action
        let actionMoveDown = SKAction.moveTo(CGPoint(x:view!.bounds.size.width/2, y:view!.bounds.size.height/2), duration: 0.25)
        // Creating movement action
        let actionMoveUp = SKAction.moveTo(CGPoint(x:view!.bounds.size.width/2, y:view!.bounds.size.height/2 + 60), duration: 0.25)
        // Creating block action
        let stopGame = SKAction.runBlock {
            // Stop game
            self.view?.paused = true
        }
        // Creating block action
        let stopMusic = SKAction.runBlock {
            // Stop background music
            self.backgroundMusic.stop()
        }
        
        // Creating block action
        let showLabelResetAction = SKAction.runBlock {
            // Show reset game label
            self.showLabelReset()
        }
        let sequence = SKAction.sequence([actionMoveDown, actionMoveUp, actionMoveDown, stopMusic, showLabelResetAction, stopGame])
        // Run sequence
        labelGameOver.runAction(sequence)
        
        self.showInterstitial()
    }
    
    func preloadInterstitial() {
        self.interstitial = GADInterstitial(adUnitID: "ca-app-pub-5767684210972160/6577154339")
        self.interstitial.delegate = self
        let request = GADRequest()
        // Requests test ads on test devices.
        request.testDevices = [kGADSimulatorID]
        
        self.interstitial.loadRequest(request)
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        // Continue game
        self.view?.paused = false
        self.preloadInterstitial()
    }

    func showInterstitial() {
        if self.interstitial.isReady {
            // Stop game
            self.view?.paused = true
            self.interstitial.presentFromRootViewController(viewController)
        }
    }
    
    func showLabelReset() {
        // Initialize the label with a font name
        labelResetGame = SKLabelNode(fontNamed:"MarkerFelt-Thin")
        // Set color, size and position
        labelResetGame.fontColor = UIColor.greenColor()
        labelResetGame.fontSize = 30
        labelResetGame.position = CGPoint(x:view!.bounds.size.width/2, y:view!.bounds.size.height/2 - 60)
        // Specifying zPosition
        labelResetGame.zPosition = 5
        // Set text
        labelResetGame.text = "Reset Game"
        // Set node's name
        labelResetGame.name = "reset_label"
        
        // Add the label to the scene
        addChild(labelResetGame)
    }
    
    func restartGame() {
        // Reset values
        score = 0
        lastFrameTime = 0
        deltaTime = 0
        waveNumber = 1
        
        // Set doors to nill
        leftDoor = nil
        centerDoor = nil
        rightDoor = nil
        
        // Remove all children on scene
        self.removeAllChildren()
        // Remove all actions
        self.removeAllActions()
        
        self.view?.paused = false
        // Restart the game
        self.view?.presentScene(self)
    }
    
    func initializeTutorial() {
        
        // Create action
        let pauseForTutorial = SKAction.runBlock {
            // Pause game for the tutorial
            self.view?.paused = true
            
            // Initialize tutorial image
            self.tutorialImage = SKSpriteNode(imageNamed: "hand")
            // Set image position
            self.tutorialImage.position = CGPoint(x:self.view!.bounds.size.width/6, y: self.view!.bounds.size.height/3)
            // Specifying zPosition
            self.tutorialImage.zPosition = 7
            
            // Add the image to the scene
            self.addChild(self.tutorialImage)
            
            // Initialize tutorial frame
            self.tutorialFrame = SKShapeNode(rectOfSize: CGSize(width: self.view!.bounds.width/3, height: self.view!.bounds.size.height))
            // Set frame's position
            self.tutorialFrame.position = CGPoint(x:self.view!.bounds.size.width/6, y: self.view!.bounds.size.height/2)
            // No border
            self.tutorialFrame.lineWidth = 0
            // Specify zPosition
            self.tutorialFrame.zPosition = 6
            // Set frame color
            self.tutorialFrame.fillColor = UIColor.whiteColor()
            // Set alpha value
            self.tutorialFrame.alpha = 0.5
            // Set node's name
            self.tutorialFrame.name = "tutorial_frame"
            
            // Add frame to scene
            self.addChild(self.tutorialFrame)
            
            // Initialize label
            self.labelTutorial = SKLabelNode(fontNamed:"MarkerFelt-Thin")
            // Set color, size and position
            self.labelTutorial.fontColor = UIColor.blackColor()
            self.labelTutorial.fontSize = 30
            self.labelTutorial.position.x = self.tutorialImage.position.x
            self.labelTutorial.position.y = self.tutorialImage.position.y + 50
            // Specifying zPosition
            self.labelTutorial.zPosition = 7
            // Set text
            self.labelTutorial.text = "Touch"
            
            // Add the label to the scene
            self.addChild(self.labelTutorial)
        }
        
        // Creating a delay action
        let delayAction = SKAction.waitForDuration(1.0)
        let sequence = SKAction.sequence([delayAction, pauseForTutorial])
        // Running the non-ending sequence
        self.runAction(sequence)
    }
    
    func updateTutorial() {
        // Auxiliar variables
        var moveAction:SKAction!
        var duration: CGFloat = 0.0
        var nextPosition: CGPoint
        
        switch tutorialStep {
            
        case .TUTORIAL_STEP_1:
            // Hide tutorial elements
            self.tutorialImage.hidden = true
            self.labelTutorial.hidden = true
            self.tutorialFrame.hidden = true
            
            // Setting the next position
            nextPosition = CGPoint(x: leftDoor.position.x, y: rabbit.position.y)
            // We want the rabbit to move on a constant speed
            duration = self.distanceBetween(point: self.rabbit.position, andPoint: nextPosition) / 360.0
            // Move the rabbit to the touched position
            moveAction = SKAction.moveToX(nextPosition.x, duration: Double(duration))
            
            let updateTutorialAction = SKAction.runBlock {
                // Update tutorial step
                self.tutorialStep = .TUTORIAL_STEP_2
                self.updateTutorial()
            }
            // Create sequence
            let sequence = SKAction.sequence([moveAction, updateTutorialAction])
            // Run the sequence
            self.rabbit.runAction(sequence)
            
            // Release the game for the tutorial
            self.view?.paused = false
            break
        
        case .TUTORIAL_STEP_2:
            // Create action
            let pauseForTutorial = SKAction.runBlock {
                // Pause game for the tutorial
                self.view?.paused = true
                
                // Update tutorial image
                self.tutorialImage.position = CGPoint(x:5*self.view!.bounds.size.width/6, y: self.view!.bounds.size.height/3)
                self.tutorialImage.hidden = false
                // Update tutorial frame
                self.tutorialFrame.position = CGPoint(x:5*self.view!.bounds.size.width/6, y: self.view!.bounds.size.height/2)
                self.tutorialFrame.hidden = false
                // Update tutorial label
                self.labelTutorial.position.x = self.tutorialImage.position.x
                self.labelTutorial.hidden = false
                // Update tutorial step
                self.tutorialStep = .TUTORIAL_STEP_3
            }
            
            // Creating a delay action
            let delayAction = SKAction.waitForDuration(4.25)
            // Create sequence
            let sequence = SKAction.sequence([delayAction, pauseForTutorial])
            // Run the sequence
            self.runAction(sequence)
            break
            
        case .TUTORIAL_STEP_3:
            // Hide tutorial elements
            self.tutorialImage.hidden = true
            self.labelTutorial.hidden = true
            self.tutorialFrame.hidden = true
            
            // Release the game for the tutorial
            self.view?.paused = false
            
            // Setting the next position
            nextPosition = CGPoint(x: rightDoor.position.x, y: rabbit.position.y)
            // We want the rabbit to move on a constant speed
            duration = self.distanceBetween(point: self.rabbit.position, andPoint: nextPosition) / 360.0
            // Move the rabbit to the touched position
            moveAction = SKAction.moveToX(nextPosition.x, duration: Double(duration))
            
            // Create action
            let updateTutorialAction = SKAction.runBlock {
                // Update tutorial step
                self.tutorialStep = .TUTORIAL_STEP_4
                self.updateTutorial()
            }
            // Create sequence
            let sequence = SKAction.sequence([moveAction, updateTutorialAction])
            
            // Run the sequence
            self.rabbit.runAction(sequence)
            break
            
        case .TUTORIAL_STEP_4:
            
            // Create action
            let pauseForTutorial = SKAction.runBlock {
                // Set image position
                self.tutorialImage.position = CGPoint(x:self.view!.bounds.size.width/2, y: self.view!.bounds.size.height/3)
                
                // Update tutorial label
                self.labelTutorial.text = "RUN!"
                self.labelTutorial.position.x = self.tutorialImage.position.x
                self.labelTutorial.hidden = false
                
                // Update tutorial step
                self.tutorialStep = .TUTORIAL_STEP_5
                self.updateTutorial()
            }
            
            // Creating a delay action
            let delayAction = SKAction.waitForDuration(2.25)
            // Create sequence
            let sequence = SKAction.sequence([delayAction, pauseForTutorial])
            // Run the sequence
            self.runAction(sequence)
            break
            
        case .TUTORIAL_STEP_5:
            
            // Create action
            let endOfMovementAction = SKAction.runBlock {
                // Remove tutorial elements
                self.tutorialImage.removeFromParent()
                self.labelTutorial.removeFromParent()
                self.tutorialFrame.removeFromParent()
                
                // Update tutorial step
                self.tutorialStep = .TUTORIAL_ENDED
                
                // Update tutorial flag
                self.isTutorialCompleted = true
                self.userDefaults.setBool(self.isTutorialCompleted, forKey: self.kUserDefaultTutorialCompleted)
            }
            
            // Creating a delay action
            let delayAction = SKAction.waitForDuration(1.25)
            // Create sequence
            let sequence = SKAction.sequence([delayAction, endOfMovementAction])
            // Run the sequence
            self.runAction(sequence)
            break
            
        default: break
        }
    }
    
    func initializeUserDefaults() {
        // Initialize user defaults
        if (userDefaults == nil) {
            userDefaults = NSUserDefaults.standardUserDefaults()
        }
        // If the user default exists
        if userDefaults.integerForKey(kUserDefaultBestScore) > 0 {
            bestScore = userDefaults.integerForKey(kUserDefaultBestScore)
        }
        
        if userDefaults.boolForKey(kUserDefaultTutorialCompleted) {
            isTutorialCompleted = userDefaults.boolForKey(kUserDefaultTutorialCompleted)
        }
    }
    
    func updateBestScore() {
        if score > bestScore {
            userDefaults.setInteger(score, forKey: kUserDefaultBestScore)
            labelBestScore.text = "Best: \(score)"
        }
    }
    
    func readLevelInfo() {
        // Declare dictionary variable
        var levelDictionary: NSDictionary!
        var waveInfo: NSDictionary
        
        leftDoorsInfo = [String]()
        centerDoorsInfo = [String]()
        rightDoorsInfo = [String]()
        
        // Get level dictionary root
        if let path = NSBundle.mainBundle().pathForResource("Level_info", ofType: "plist") {
            levelDictionary = NSDictionary(contentsOfFile: path)
        }
        
        // Initialize max number of waves
        maxWaves = levelDictionary!.valueForKey("numWaves") as! Int
        
        // Get info for all the waves
        for var i: Int = 1; i <= maxWaves; i++ {
            waveInfo = levelDictionary!.valueForKey("wave - \(i)") as! NSDictionary
            leftDoorsInfo.append(waveInfo.valueForKey("leftDoor") as! String)
            centerDoorsInfo.append(waveInfo.valueForKey("centerDoor") as! String)
            rightDoorsInfo.append(waveInfo.valueForKey("rightDoor") as! String)
        }
    }
    
    func initializeSoundOffOnButton() {
        // Initialize UIButton
        soundOffOnButton = UIButton(frame: CGRectMake(view!.bounds.size.width - rabbit.frame.width, view!.bounds.size.height - rabbit.frame.width, rabbit.frame.width, rabbit.frame.width))
        // Set image to button
        soundOffOnButton.setImage(UIImage(named: "soundOffOn"), forState: UIControlState.Normal)
        // Specify function to trigger
        soundOffOnButton.addTarget(self, action: "alternateSound", forControlEvents: UIControlEvents.TouchUpInside)
        // Add button to view
        self.view!.addSubview(soundOffOnButton)
    }
    
    func alternateSound() {
        if isSoundOn {
            // Stop background music
            isSoundOn = false
            backgroundMusic.stop()
        } else {
            // Restart background music
            isSoundOn = true
            backgroundMusic.play()
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        // Detect collisions
        if !self.isCollisionDetected {
            self.detectCollisions()
        }

        // If a new wave has to start
        if resetWave {
            self.initializeWave()
        }
        
        // Update layers on parallax effect
        self.updateParallaxLayers(currentTime)
    }
}
