//
//  RecordingScreen.swift
//  Cirquit
//
//  Created by Jon Lord on 05/03/2015.
//  Copyright (c) 2015 MMT Digital. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI

class RecordingScreen: UIViewController {

    var fileManager = NSFileManager()
    var recorder: AVAudioRecorder!
    var player:AVAudioPlayer!
    var meterTimer:NSTimer!
    var recordSettings = [
        AVFormatIDKey: kAudioFormatAppleLossless,
        AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
        AVEncoderBitRateKey : 320000,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey : 44100.0
    ]
    
    var currentFileName = "CirquitRecording.m4a"
    var mixFileName = "CirquitRecordingForMix.m4a"
    var mixedFileName = "CirquitRecordingMixed.m4a"
    

    @IBOutlet var waveBarView: UIView!
    let waveForm = UIView()
    let waveSeconds = NSMutableArray()
    
    var currentSecond: CGFloat = 0

    @IBOutlet var lblTimer: UILabel!

    // EVENTS
    override func viewDidLoad() {
        super.viewDidLoad()
        setSessionPlayback()
        
        setUpWaveform()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "MoveToPlayScreen") {
            // pass data to next view
            let destinationVC = segue.destinationViewController as RecordingScreen
        }
        
    }
    
    func setUpWaveform() {
        waveForm.layer.position = CGPointMake(320, waveBarView.frame.height / 2)
        waveForm.frame.size = CGSize(width: view.frame.width, height: waveBarView.frame.height)
        waveBarView?.addSubview(waveForm)
    
        let secondWidth = CGFloat(2)
        
        for index in 0...100 {
            let position = secondWidth * CGFloat(index) + CGFloat(2)
            let waveSecond = UIView(frame: CGRectMake(position, 0, secondWidth, 2))
            waveSecond.layer.cornerRadius = 0
            waveSecond.backgroundColor = UIColor.whiteColor()
            waveForm.addSubview(waveSecond)
            waveSeconds.addObject(waveSecond)
        }
        
    }
    
    func startWaveformAnimate() {
        
        UIView.animateWithDuration(20, delay: 0, options: .CurveLinear, animations: {
            self.waveForm.layer.position.x = self.waveForm.frame.width / 2;
        }, completion: {
                (finished: Bool) in
                self.startWaveformAnimate();
        });
        
    }

    func resetWaveform() {
        waveForm.layer.removeAllAnimations()
        waveForm.layer.position.x = self.view.frame.width + waveForm.frame.width / 2
    }
    
    func updateWaveform(second: Int, peak: Float) {
        
        
        if (currentSecond % 2 == 0 && currentSecond < 100) {
        
            var test = waveSeconds.objectAtIndex(Int(currentSecond)) as UIView
            test.backgroundColor = UIColor.whiteColor()
        
            var number = fabsf(peak)
            
            var totalHeight = 50 - number;
        
            
            UIView.animateWithDuration(0.2, animations: {
                test.frame.size.height = CGFloat(totalHeight)
                test.layer.position.y -= CGFloat(totalHeight / 2 - 1)
            })
            
            
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
            
            var url = getMixedSoundFileURL()!
            var urlPath = url.path!
            var success = fileManager.fileExistsAtPath(urlPath)
            if (success)
            {
                var instanceOfCustomObject: SoundFactory = SoundFactory()
                instanceOfCustomObject.mergeMySoundFile(getMainSoundFileURL()!, withFriendsSoundFile: url, toCreateSoundFileNamed: getMixedSoundFileURL()!)
            }
            else
            {
                var error: NSError?
                var successRemove = fileManager.removeItemAtURL(getMixedSoundFileURL()!, error: &error)
                var successRename = fileManager.moveItemAtURL(getMainSoundFileURL()!, toURL: getMixedSoundFileURL()!, error: &error)
            }
            
            lblTimer.text = "20 SECONDS LEFT"
            self.performSegueWithIdentifier("MoveToPlayScreen", sender: self)
            resetWaveform()
        }
    }
    
    
    @IBOutlet var btnPlay: UIButton!
    @IBAction func btnPlay_Tap(sender: UIButton) {
        playLastRecording()
    }
    
    @IBOutlet var btnMix: UIButton!
    @IBAction func btnMix_Tap(sender: UIButton) {

        // Rename File to save for merging
        var error: NSError?
        var success = fileManager.moveItemAtURL(getMainSoundFileURL()!, toURL: getMixSoundFileURL()!, error: &error)
    }
    
    @IBOutlet var btnTrash: UIButton!
    @IBAction func btnTrash_Tap(sender: UIButton) {
        
        if player != nil && player.playing {
            player.stop()
        }
        
        var error: NSError?
        var success = fileManager.removeItemAtURL(getMainSoundFileURL()!, error: &error)
        success = fileManager.removeItemAtURL(getMixSoundFileURL()!, error: &error)
        success = fileManager.removeItemAtURL(getMixedSoundFileURL()!, error: &error)
        
        
    }
    
    
    // RECORDING
    func playLastRecording() {
        
        var error: NSError?
        self.player = AVAudioPlayer(contentsOfURL: getMixedSoundFileURL()!, error: &error)
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
                    
                    // Start waveform animation
                    self.startWaveformAnimate()
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
            
            currentSecond += 0.5
            
            updateWaveform(sec, peak: peak0)
    
            if (sec == 20) {
                // Cancel recording
                timer.invalidate()
                recordingEnded()
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

        var soundFileURL = getMainSoundFileURL()
        
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
    
    
    func getMixedSoundFileURL() -> NSURL?
    {
        return getSoundFileURL(mixedFileName)
    }
    func getMainSoundFileURL() -> NSURL?
    {
        return getSoundFileURL(currentFileName)
    }
    func getMixSoundFileURL() -> NSURL?
    {
        return getSoundFileURL(mixFileName)
    }
    
    func getSoundFileURL(currentFileName: String!) -> NSURL?
    {
        var mainSoundFileURL:NSURL?
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var docsDir: AnyObject = dirPaths[0]
        var soundFilePath = docsDir.stringByAppendingPathComponent(currentFileName)
        mainSoundFileURL = NSURL(fileURLWithPath: soundFilePath)

        return mainSoundFileURL
    }
    
    
    @IBAction func showEmail(sender : AnyObject) {
        var emailTitle = "Mix from Cirquit"
        var messageBody = "I've just recorded the following mix using Cirquit!"
        var mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        
        
        let url = getMixedSoundFileURL()
        let data = NSData(contentsOfURL: url!)
        
        mc.addAttachmentData(data, mimeType: "audio/mp4 .m4a", fileName: "My Cirquit Mix.m4a")
        
        self.presentViewController(mc, animated: true, completion: nil)
    }
    
    func mailComposeController(controller:MFMailComposeViewController, didFinishWithResult result:MFMailComposeResult, error:NSError) {
        switch result.value {
        case MFMailComposeResultCancelled.value:
            println("Mail cancelled")
        case MFMailComposeResultSaved.value:
            println("Mail saved")
        case MFMailComposeResultSent.value:
            println("Mail sent")
        case MFMailComposeResultFailed.value:
            println("Mail sent failure: \(error.localizedDescription)")
        default:
            break
        }
        self.dismissViewControllerAnimated(false, completion: nil)
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

extension RecordingScreen : MFMailComposeViewControllerDelegate {

    

}


