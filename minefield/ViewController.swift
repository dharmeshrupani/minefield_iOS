//
//  ViewController.swift
//  Mineswifter
//
//  Created by Benjamin Reynolds on 7/26/14.
//  Copyright (c) 2014 MakeGamesWithUs. All rights reserved.
//

import UIKit
import GoogleMobileAds
import AudioToolbox

class ViewController: UIViewController,GADBannerViewDelegate ,GADInterstitialDelegate{
    
    @IBOutlet weak var viewOutMain: UIView!
    @IBOutlet weak var viewOutMain1: UIView!
    @IBOutlet weak var viewOutMain2: UIView!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var movesLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var counter = 0
    var timer : NSTimer?

    var interstitial: GADInterstitial!

    var totalOut = 0;
    let BOARD_SIZE:Int = 10
    var board:Board
    var squareButtons:[SquareButton] = []
    
    var moves:Int = 0 {
        didSet {
            self.movesLabel.text = "Moves: \(moves)"
            self.movesLabel.sizeToFit()
        }
    }
    var timeTaken:Int = 0  {
        didSet {
            self.timeLabel.text = "Time: \(timeTaken)"
            self.timeLabel.sizeToFit()
        }
    }
    var oneSecondTimer:NSTimer?
    
//MARK: Initialization
    
    required init?;?(coder aDecoder: NSCoder)

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    {
        self.board = Board(size: BOARD_SIZE)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.removeOutScreen()
        
        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())

        print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.loadRequest(GADRequest())

        self.interstitial = createAndLoadInterstitial()

        self.initializeBoard()
        self.startNewGame()
    }
    
    func removeOutScreen(){
    viewOutMain.frame = CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)
    viewOutMain1.frame = CGRectMake(0,-self.view.frame.size.height/2,self.view.frame.size.width, self.view.frame.size.height/2)
    viewOutMain2.frame = CGRectMake(0,self.view.frame.size.height,self.view.frame.size.width, self.view.frame.size.height/2)
    viewOutMain.hidden=true
    }
    
    func initializeBoard() {
        for row in 0 ..< board.size {
            for col in 0 ..< board.size {
                
                let square = board.squares[row][col]
                
                let squareSize:CGFloat = self.boardView.frame.width / CGFloat(BOARD_SIZE)
                
                let squareButton = SquareButton(squareModel: square, squareSize: squareSize);
                squareButton.setTitle("[x]", forState: .Normal)
                squareButton.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
                squareButton.addTarget(self, action: "squareButtonPressed:", forControlEvents: .TouchUpInside)
                self.boardView.addSubview(squareButton)
                
                self.squareButtons.append(squareButton)
            }
        }
    }
    
    func resetBoard() {
        // resets the board with new mine locations & sets isRevealed to false for each square
        self.board.resetBoard()
        // iterates through each button and resets the text to the default value
        for squareButton in self.squareButtons {
            squareButton.setTitle("[x]", forState: .Normal)
        }
    }
    
    func startNewGame() {
        //start new game
        self.resetBoard()
        self.timeTaken = 0
        self.moves = 0
        self.oneSecondTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("oneSecond"), userInfo: nil, repeats: true)
    
        totalOut += 1
        if totalOut > 3
        {
            totalOut = 0;
            if self.interstitial.isReady {
                self.interstitial.presentFromRootViewController(self)
            }
        }
    }
    
    func oneSecond() {
        self.timeTaken++
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//MARK: Button Actions
    
    @IBAction func newGamePressed() {
        print("new game", terminator: "")
        self.endCurrentGame()
        self.startNewGame()
        
        UIView.animateWithDuration(0.5, animations: {
            self.removeOutScreen()
        })
    }
    
    @IBAction func restartGamePressed() {
        self.startNewGame()
        UIView.animateWithDuration(0.5, animations: {
            self.removeOutScreen()
        })
    }
    
    func squareButtonPressed(sender: SquareButton) {
//        println("Pressed row:\(sender.square.row), col:\(sender.square.col)")
//        sender.setTitle("", forState: .Normal)
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);

        if !sender.square.isRevealed {
            sender.square.isRevealed = true
            sender.setTitle("\(sender.getLabelText())", forState: .Normal)
            self.moves++
        }
        
        if sender.square.isMineLocation {
            self.minePressed()
        }
    }
    
    func minePressed() {
        self.endCurrentGame()
        // show an alert when you tap on a mine
        let alertView = UIAlertView()
        alertView.addButtonWithTitle("New Game")
        alertView.title = "BOOM!"
        alertView.message = "You tapped on a mine."
        //alertView.show()
        alertView.delegate = self
        viewOutMain.hidden=false

        UIView.animateWithDuration(0.5, animations: {
            self.viewOutMain1.frame = CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height/2)
            self.viewOutMain2.frame = CGRectMake(0,self.view.frame.size.height/2,self.view.frame.size.width, self.view.frame.size.height/2)
        })

        

        self.vibrate()
        if let soundURL = NSBundle.mainBundle().URLForResource("GameOut1", withExtension: "mp3")
        {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound);
        }
        
        
    }
    
    func alertView(View: UIAlertView!, clickedButtonAtIndex buttonIndex: Int) {
        //start new game when the alert is dismissed
        self.startNewGame()
    }
    
    func endCurrentGame() {
        self.oneSecondTimer!.invalidate()
        self.oneSecondTimer = nil
    }


    //Full screen ads
    
    func gameOver() {
        if self.interstitial.isReady
        {
            self.interstitial.presentFromRootViewController(self)
        }
        // Rest of game over logic goes here.
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        interstitial.delegate = self
        interstitial.loadRequest(GADRequest())
        return interstitial
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        self.interstitial = createAndLoadInterstitial()
    }
    
    //Vibrate phone
    func vibratePhone() {
        counter = counter+1
        switch counter {
        case 1, 2:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        default:
            timer?.invalidate()
        }
    }
    
    func vibrate() {
        counter = 0
        timer = NSTimer.scheduledTimerWithTimeInterval(0.6, target: self, selector: "vibratePhone", userInfo: nil, repeats: true)
    }
}

