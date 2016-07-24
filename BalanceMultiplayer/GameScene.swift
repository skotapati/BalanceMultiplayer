//
//  GameScene.swift
//  BalanceMultiplayer
//
//  Created by Siddharth on 7/23/16.
//  Copyright © 2016 Siddharth. All rights reserved.
//

import SpriteKit
import GameplayKit
import Messages

 public class GameScene: SKScene {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    internal var selectedBlock = SKShapeNode(rectOf: CGSize(width: 100, height: 100))
    internal var blockNum = 0
    internal var blockX = CGFloat(0)
    internal var blockY = CGFloat(200)
    internal var xSpeed = 3
    internal var blockHeight = 200
    internal var blockWidth = 200
    internal var maxRight = 300
    internal var movingRight = true
    internal var score = 0
    internal var imageSource = "ball.png"
    internal var gameRunning = true
    internal var BlockNames = ""
    internal var BlockXs = ""
    internal var shapes = ["box","bigBox","chair"]
    internal var BlockList = [String: BlockInfo]()
    internal var newSession : MSSession?
    internal var newMessage : MSMessage?
    internal var currentConversation : MSConversation?
    internal var screenShot : UIImage?
    
    
    
    override public func didMove(to view: SKView) {
        BlockList["box"] = BlockInfo.init(blockHeight: 200, blockWidth: 200, imageSource: "fish.png")
        BlockList["bigBox"] = BlockInfo.init(blockHeight: 300, blockWidth: 300, imageSource: "ball.png")
        BlockList["chair"] = BlockInfo.init(blockHeight: 350, blockWidth: 250, imageSource: "chair.png")
        // Get label node from scene and store it for use later
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(M_PI), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green()
            self.addChild(n)
        }
        let shape = Int(arc4random_uniform(UInt32(shapes.count)))
        if(gameRunning){
            spawn(block: shapes[Int(shape)])
        }
        UIGraphicsBeginImageContext((view?.frame.size)!)
        self.view?.drawHierarchy(in: (self.view?.bounds)!, afterScreenUpdates: false)
        screenShot = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        newMessage?.url = currentStateURL() as URL
        let layout = MSMessageTemplateLayout()
            if(gameRunning){
                layout.caption = "I got us to "+String(score-1)+" points in Terrible Tower!"
                layout.subcaption = "Help us get even farther"
                layout.image = screenShot
            }else{
                layout.caption = "We reached a total of "+String(score-1)+" points in Terrible Tower!"
                layout.subcaption = "Go to your keyboard to start a new game!"
            }
        currentConversation = MSConversation.init()
        newSession = MSSession.init()
        newMessage = MSMessage.init(session: newSession!)
        newMessage?.url = currentStateURL() as URL
        newMessage?.url = currentStateURL() as URL
        newMessage?.layout = layout
        currentConversation?.insert(newMessage!, completionHandler:nil)
    }
    
    func spawn(block: String) -> SKShapeNode{
        let info = BlockList[block]
        selectedBlock.physicsBody?.affectedByGravity = true
        BlockXs += String(selectedBlock.position.x)+", "
        blockY += CGFloat((info?.blockHeight)!-35)
        let temp = maxRight * 2;
        blockX = CGFloat(arc4random_uniform(UInt32(temp)))-CGFloat(maxRight)
        selectedBlock = SKShapeNode(rectOf: CGSize(width: (info?.blockWidth)!, height: (info?.blockHeight)!))
        selectedBlock.physicsBody = SKPhysicsBody.init(rectangleOf: CGSize(width: (info?.blockWidth)! - 35, height: (info?.blockHeight)! - 35))
        selectedBlock.physicsBody?.affectedByGravity = false
        selectedBlock.position.x = blockX
        selectedBlock.position.y = blockY
        selectedBlock.fillColor = SKColor.white()
        selectedBlock.fillTexture = SKTexture.init(imageNamed: (info?.imageSource)!)
        self.addChild(selectedBlock)
        BlockNames += block+", "
        score+=1
        self.label?.text = String(score)
        return selectedBlock
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue()
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red()
            self.addChild(n)
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override public func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if(self.camera?.position.y<=CGFloat(blockY)){
            self.camera?.position.y += CGFloat(2.5)
        }
        if(movingRight && selectedBlock.position.x<CGFloat(maxRight)){
            selectedBlock.position.x += CGFloat(xSpeed)
        } else if(movingRight && selectedBlock.position.x>=CGFloat(maxRight)){
            movingRight = false
        } else if(!movingRight && selectedBlock.position.x>=CGFloat(0-maxRight)){
            selectedBlock.position.x -= CGFloat(xSpeed)
        } else if(!movingRight && selectedBlock.position.x<=CGFloat(0-maxRight)){
            movingRight = true
        }
        let lossDetector = self.childNode(withName: "BottomDetector")
        if(lossDetector?.position.y <= -760){
            if(gameRunning){
                gameRunning = false
                newMessage?.url = currentStateURL() as URL
                let layout = MSMessageTemplateLayout()
                layout.caption = "We reached a total of "+String(score-1)+" points in Terrible Tower!"
                layout.subcaption = "Go start a new game!"
                currentConversation = MSConversation.init()
                newSession = MSSession.init()
                newMessage = MSMessage.init(session: newSession!)
                newMessage?.url = currentStateURL() as URL
                newMessage?.url = currentStateURL() as URL
                newMessage?.layout = layout
                currentConversation?.insert(newMessage!, completionHandler:nil)
            }
        }
    }
    public func currentStateURL() -> NSURL {
        guard let components = NSURLComponents(string: "data:") else {
            fatalError("Invalid base url")
        }
        let blocks = NSURLQueryItem(name: "BlockList", value: BlockNames)
        let positions = NSURLQueryItem(name: "PositionList", value: BlockXs)
        let isGameRunning = NSURLQueryItem(name: "IsRunning", value: String(gameRunning))
        components.queryItems = [blocks as URLQueryItem, positions as URLQueryItem, isGameRunning as URLQueryItem]
        guard let url = components.url else{
            fatalError("Invalid URL components.")
        }
        return url
    }
    
    
    
    public func readInput(){
        var shapes = BlockNames.components(separatedBy: ", ")
        var positions = BlockXs.components(separatedBy: ", ")
        var i = 0
        score = 0
        while(i<shapes.count){
            var placedObject = spawn(block: shapes[i])
            placedObject.position.x = CGFloat(Int(positions[i])!)
            i += 1
        }
    }
    func viewDidLoad() {
        // Do any additional setup after loading the view.
        guard let components = NSURLComponents(url: (newMessage?.url!)!, resolvingAgainstBaseURL: false) else {
            fatalError("The message contains an invalid URL")
        }
        
        if let queryItems = components.queryItems {
            BlockNames = queryItems[0].value!
            BlockXs = queryItems[1].value!
            score = 0;
            readInput()
        }
        currentConversation = MSConversation.init()
        newSession = MSSession.init()
        newMessage = MSMessage.init(session: newSession!)
        newMessage?.url = currentStateURL() as URL
        let layout = MSMessageTemplateLayout()
        layout.caption = "I got us to "+String(score)+" points in Terrible Tower!"
        layout.subcaption = "Help us get even farther"
        newMessage?.url = currentStateURL() as URL
        newMessage?.layout = layout
        currentConversation?.insert(newMessage!, completionHandler:nil)
    }
    func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        // var components = URLComponents()
        // components.queryItems = iceCream.queryItems
        
        currentConversation = MSConversation.init()
        newSession = MSSession.init()
        newMessage = MSMessage.init(session: newSession!)
        newMessage?.url = currentStateURL() as URL
        let layout = MSMessageTemplateLayout()
        layout.caption = "I got us to "+String(score)+" points in Terrible Tower!"
        layout.subcaption = "Help us get even farther"
        newMessage?.url = currentStateURL() as URL
        currentConversation?.insert(newMessage!, completionHandler:nil)
    }
struct BlockInfo{
    var blockHeight = CGFloat(200)
    var blockWidth = CGFloat(200)
    var imageSource = "Images/751_multi.jpg"
}
}
