//
//  RecordingScreen.swift
//  Cirquit
//
//  Created by Jon Lord on 05/03/2015.
//  Copyright (c) 2015 MMT Digital. All rights reserved.
//

import UIKit
import AVFoundation


class RecordingScreen: UIViewController {

    var recorder: AVAudioRecorder!
    var player:AVAudioPlayer!
    var meterTimer:NSTimer!
    var soundFileURL:NSURL?
    var recordSettings = [
        AVFormatIDKey: kAudioFormatAppleLossless,
        AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
        AVEncoderBitRateKey : 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100.0
    ]
    
    @IBOutlet var lblTimer: UILabel!

    // EVENTS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSessionPlayback()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "MoveToPlayScreen") {
            // pass data to next view
            let destinationVC = segue.destinationViewController as RecordingScreen
            destinationVC.soundFileURL = soundFileURL
        }
        
    }
    
    
    // ACTIONS
    @IBOutlet var btnRecord: UIButton!
    @IBAction func btnRecord_Tap(sender: UIButton) {
        
        if recorder != nil && recorder.recording {
            recorder.stop()
        }
        
        var setup = recorder == nil
        recordWithPermission(setup)
    }
    
    @IBAction func btnRecord_Released(sender: UIButton) {
        
        recordingEnded()
    }
    
    func recordingEnded()
    {
        if recorder != nil && recorder.recording {
            recorder.stop()
            self.performSegueWithIdentifier("MoveToPlayScreen", sender: self)
        }
    }
    
    
    @IBOutlet var btnPlay: UIButton!
    @IBAction func btnPlay_Tap(sender: UIButton) {
        playLastRecording()
    }
    
    
    
    @IBOutlet var btnTrash: UIButton!
    @IBAction func btnTrash_Tap(sender: UIButton) {
        
        if player != nil && player.playing {
            player.stop()
        }
        
        if let navController = self.navigationController {
            navController.popViewControllerAnimated(true)
        }
    }
    
    
    // RECORDING
    func playLastRecording() {
        
        var error: NSError?
        self.player = AVAudioPlayer(contentsOfURL: soundFileURL!, error: &error)
        if player == nil {
            if let e = error {
                println(e.localizedDescription)
            }
        }
        player.delegate = self
        player.prepareToPlay()
        player.volume = 1.0
        player.play()
        
        
    }
    func recordWithPermission(setup:Bool) {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        // ios 8 and later
        if (session.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    self.setSessionPlayAndRecord()
                    if setup {
                        self.setupRecorder()
                    }
                    self.recorder.record()
                    self.meterTimer = NSTimer.scheduledTimerWithTimeInterval(0.1,
                        target:self,
                        selector:"updateAudioMeter:",
                        userInfo:nil,
                        repeats:true)
                }
            })
        }
    }
    
    func updateAudioMeter(timer:NSTimer) {
        
        if recorder.recording {
            let dFormat = "%02d"
            let min:Int = Int(recorder.currentTime / 60)
            let sec:Int = Int(recorder.currentTime % 60)
            let s = "\(String(format: dFormat, min)):\(String(format: dFormat, sec))"
            
            let secondsLeft = 20 - sec;
            lblTimer.text = secondsLeft.description + " Seconds Left"
            
            recorder.updateMeters()
            var apc0 = recorder.averagePowerForChannel(0)
            var peak0 = recorder.peakPowerForChannel(0)
            
            if (sec == 20) {
                // Cancel recording
                timer.invalidate()
            }
            
        }
    }
    
    // MANAGE PLAYER
    func setSessionPlayback() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setCategory(AVAudioSessionCategoryPlayback, error:&error) {
            println("could not set session category")
            if let e = error {
                println(e.localizedDescription)
            }
        }
        if !session.setActive(true, error: &error) {
            println("could not make session active")
            if let e = error {
                println(e.localizedDescription)
            }
        }
    }
    
    
    func setSessionPlayAndRecord() {
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?
        if !session.setCategory(AVAudioSessionCategoryPlayAndRecord, error:&error) {
            println("could not set session category")
            if let e = error {
                println(e.localizedDescription)
            }
        }
        if !session.setActive(true, error: &error) {
            println("could not make session active")
            if let e = error {
                println(e.localizedDescription)
            }
        }
    }
    
    
    func setupRecorder() {
        
        var format = NSDateFormatter()
        format.dateFormat="yyyy-MM-dd-HH-mm-ss"
        var currentFileName = "recording-\(format.stringFromDate(NSDate())).m4a"
        
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var docsDir: AnyObject = dirPaths[0]
        var soundFilePath = docsDir.stringByAppendingPathComponent(currentFileName)
        soundFileURL = NSURL(fileURLWithPath: soundFilePath)
        
        var error: NSError?
        recorder = AVAudioRecorder(URL: soundFileURL!, settings: recordSettings, error: &error)
        if let e = error {
            println(e.localizedDescription)
        } else {
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
        }
    }
    
}


// MARK: AVAudioRecorderDelegate
extension RecordingScreen : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!,
        successfully flag: Bool) {


            // iOS8 and later
//            var alert = UIAlertController(title: "Recorder",
//                message: "Finished Recording",
//                preferredStyle: .Alert)
//            alert.addAction(UIAlertAction(title: "Keep", style: .Default, handler: {action in
//                println("keep was tapped")
//            }))
//            alert.addAction(UIAlertAction(title: "Delete", style: .Default, handler: {action in
//                println("delete was tapped")
//                self.recorder.deleteRecording()
//            }))
//            self.presentViewController(alert, animated:true, completion:nil)
    }
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder!,
        error: NSError!) {
            println("\(error.localizedDescription)")
    }
}

// MARK: AVAudioPlayerDelegate
extension RecordingScreen : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {

    }
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        println("\(error.localizedDescription)")
    }
}