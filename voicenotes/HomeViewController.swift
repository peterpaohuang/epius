//
//  ViewController.swift
//  voicenotes
//
//  Created by Peter Pao-Huang on 5/19/18.
//  Copyright © 2018 Peter Pao-Huang. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import Speech


class HomeViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITableViewDelegate, UITableViewDataSource, SFSpeechRecognizerDelegate {
    
    //variables
    var recordingSession:AVAudioSession!
    var audioRecorder:AVAudioRecorder!
    var audioPlayer:AVAudioPlayer!
    var audioData:Data!
    
    var numberOfRecords:Int = 0
    
    var recognitionTask:SFSpeechRecognitionTask?
    
    var ongoingRecord:NSDictionary? = nil
    var ongoingRecordTranscription:String = ""
    
    //constants
    let post_record_url = "http://127.0.0.1:3000/api/records"
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()

    
    //outlets
    @IBOutlet weak var detectedTextLabel: UITextView!
    @IBOutlet weak var segmentedTextLabel: UITextView!
    @IBOutlet weak var recordLabel: UIButton!
    @IBOutlet weak var recordTableView: UITableView!
    
    fileprivate func startRecording() throws {
        // 1
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        // 2
        node.installTap(onBus: 0, bufferSize: 1024,
                        format: recordingFormat) { [unowned self]
                            (buffer, _) in
                            self.request.append(buffer)
        }
        
        // 3
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            [unowned self]
            (result, _) in
            if let transcription = result?.bestTranscription {
                self.detectedTextLabel.text = transcription.formattedString
            }
        }
    }
    fileprivate func stopRecording() {
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
    }
    @IBAction func recordButton(_ sender: UIButton) {
        //Check if we have an active recorder
        if audioRecorder == nil {
            numberOfRecords += 1
            let fileName = getDirectory().appendingPathComponent("\(numberOfRecords).m4a")
            
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue]
            
            //Start Audio Recording
            do {
                audioRecorder = try AVAudioRecorder(url: fileName, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()
                
                recordLabel.setTitle("Stop Recording", for: .normal)
                // Creating record
                createRecord()
                detectedTextLabel.addObserver(self, forKeyPath: "text", options: [.old, .new], context: nil)
                
                
            }
            catch {
                displayAlert(title: "Oops!", message: "Recording Failed")
            }
            
            //Live Transcription
            do {
                try self.startRecording()
            } catch let error {
                print("There was a problem starting recording: \(error.localizedDescription)")
            }
            
            
            
        }
        else {
            //Stoping Audio Recording
            audioRecorder.stop()
            audioData = try? Data(contentsOf: (audioRecorder?.url)!)
            print(audioData)
            stopRecording()
            //Sending Recording to API
           
            
            //Setting audio back to nil
            audioRecorder = nil
            
            UserDefaults.standard.set(numberOfRecords, forKey: "myNumber")
            recordTableView.reloadData()
            
            recordLabel.setTitle("Start Recording", for: .normal)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Setting Up Session
        recordingSession = AVAudioSession.sharedInstance()
        
        if let number:Int = UserDefaults.standard.object(forKey: "myNumber") as? Int {
            numberOfRecords = number
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission
            {
                print ("ACCEPTED")
            }
            
        }
        print(numberOfRecords)
        

    }
    //Function that gets path to directory
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    //Function that displays alert
    func displayAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    //Setting up Table View//

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRecords
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordCell", for: indexPath)
        cell.textLabel?.text = String(indexPath.row + 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let path = getDirectory().appendingPathComponent("\(indexPath.row).m4a")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.play()
        }
        catch {
            
        }
    }
    func createRecord() {
        let parameters: Parameters = ["title": "Some Recording", "transcription": "nothing yet", "summary": "nothing yet", "user_id": "\(current_user_session!["id"] as! Int)" ]
        
        Alamofire.request(
            self.post_record_url,
            method: .post,
            parameters: parameters,
            headers:nil).responseJSON {
                (response) in
                self.ongoingRecord = response.result.value as! NSDictionary?
                print(self.ongoingRecord!)
                let json = JSON(self.ongoingRecord!)
                self.ongoingRecordTranscription = json["transcription"].string!
        }
        /* USE WHEN SENDING AUDIO WORKS
        let parameters: Parameters = ["title": "Some Recording", "transcription": "nothing yet", "summary": "nothing yet", "user_id": "\(current_user_session!["id"] as! Int)" ]
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(self.audioData, withName: "audio", fileName: "\(self.numberOfRecords).m4a", mimeType: "audio/m4a")
                for (key, value) in parameters {
                    multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
                }
                
        },
            to: post_record_url,
            method:.post,
            
            encodingCompletion: {
                encodingResult in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    print("s")
                    upload.responseJSON { response in
                        print(response.request!)  // original URL request
                        print(response.response!) // URL response
                        print(response.data!)     // server data
                        print(response.result)   // result of response serialization
                        
                        if let JSON = response.result.value {
                            print("JSON: \(JSON)")
                        }
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                }
        })*/
    }
    func updateRecord(transcript: String) {
        let update_record_url = self.post_record_url + "/\(self.ongoingRecord!["id"] as! Int)"
        let parameters: Parameters = ["record_id": self.ongoingRecord!["id"] as! Int, "title": "Some Recording", "transcription": transcript, "summary": "nothing yet", "user_id": "\(current_user_session!["id"] as! Int)" ]
        
        Alamofire.request(
            update_record_url,
            method: .put,
            parameters: parameters,
            headers:nil).responseJSON {
                (response) in
                self.ongoingRecord = response.result.value as! NSDictionary?
                let json = JSON(self.ongoingRecord!)
                self.segmentedTextLabel.text! = json["transcription"].string!
                
        }
    }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "text" {
            self.updateRecord(transcript: change?[.newKey] as! String)
            // print("old:", change?[.oldKey])
            //print("new:", change?[.newKey])
            // change?[.newKey] = "xh" + self.updateRecord()
        }
    }
}


