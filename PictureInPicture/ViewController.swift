//
//  ViewController.swift
//  PictureInPicture
//
//  Created by Pankaj Kulkarni on 13/01/19.
//  Copyright © 2019 Pankaj Kulkarni. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak var frameOfFirstVideo: UIImageView!
    var transformOfFirstVideoFrame: CGAffineTransform?
    
    @IBOutlet weak var frameOfSecondVideo: UIImageView!
    var transformOfSecondVideoFrame: CGAffineTransform?
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    var isFirstAssetLoaded = false
    var isSecondAssetLoaded = false
    var firstAsset: AVURLAsset!
    var secondAsset: AVURLAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoURL = Bundle.main.url(forResource: "IMG_1354", withExtension: "m4v")!
        
        firstAsset = AVURLAsset(url: videoURL)
        secondAsset = AVURLAsset(url: videoURL)
        
        let assetKeysToLoad = ["tracks", "duration", "composable"]
        
        firstAsset.loadValuesAsynchronously(forKeys: assetKeysToLoad) {
            self.isFirstAssetLoaded = true
        }
        
        secondAsset.loadValuesAsynchronously(forKeys: assetKeysToLoad) {
            self.isSecondAssetLoaded = true
        }
    }

    @IBAction func sliderChanged(_ sender: UISlider) {
        
        let rotationalTransform = CGAffineTransform(rotationAngle: CGFloat(sender.value))
        
        frameOfFirstVideo.transform = rotationalTransform
        transformOfFirstVideoFrame = rotationalTransform
        self.view.setNeedsDisplay()
        
    }
    
    
    @IBAction func secondSliderChanged(_ sender: UISlider) {
        let rotationalTransform = CGAffineTransform(rotationAngle: CGFloat(sender.value))
        
        frameOfSecondVideo.transform = rotationalTransform
        transformOfSecondVideoFrame = rotationalTransform
        self.view.setNeedsDisplay()
        
    }
    
    
    @IBAction func pictureInPicturePressed(_ sender: UIButton) {
        
        
        guard isFirstAssetLoaded else {
            print("First asset is not yet loaded")
            return
        }
        
        guard isSecondAssetLoaded else {
            print("Second asset is not yet loaded")
            return
        }
        
        let mixComposition = AVMutableComposition()
//        let audioMix = AVMutableAudioMix()
        
        // Create first compostion track from first asset
        let firstCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let timeRange = CMTimeRange(start: CMTime.zero, duration: firstAsset.duration)
        let firstVideoTrack = firstAsset.tracks(withMediaType: AVMediaType.video).first!
        
        do {
            try firstCompositionTrack?.insertTimeRange(timeRange, of: firstVideoTrack, at: CMTime.zero)
        } catch {
            fatalError("Error inserting time range into first compostion track! :\(error)")
        }
        
        // Add the audio of the first track to the video
//        let firstAudioCompostionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
//
//        let firstAudioTrack = firstAsset.tracks(withMediaType: .audio).first!
//
//        do {
//            try firstAudioCompostionTrack?.insertTimeRange(timeRange, of: firstAudioTrack, at: CMTime.zero)
//        } catch {
//            fatalError("Error inserting audio asset into first audio composition track - \(error)")
//        }
        
//        // Set audio input parameter
//        let audioMixInputParameter = AVMutableAudioMixInputParameters(track: firstAudioCompostionTrack)
//        audioMixInputParameter.setVolume(1.0, at: CMTime.zero)
//        audioMix.inputParameters = [audioMixInputParameter]
        
        // Create second compostion track from second asset
        let secondCompostionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let secondVideoTrack = secondAsset.tracks(withMediaType: .video).first!
        
        do {
            try secondCompostionTrack?.insertTimeRange(timeRange, of: secondVideoTrack, at: CMTime.zero)
        } catch {
            fatalError("Error inserting time range into second compostion track! :\(error)")
        }
        
        // Create one video composition instruction. It will have multiple video composition layer instructions
        // We can have as many video ccompostion instructions as we need.
        let videoCompostionInstruction = AVMutableVideoCompositionInstruction()
        videoCompostionInstruction.backgroundColor = UIColor.clear.cgColor
        
        videoCompostionInstruction.timeRange = timeRange
        
//        let finalVideoSize = firstVideoTrack.naturalSize
        let finalVideoSize = VAConstants.screenSize
        
        // Create vide composition layer instruction for the first video track
        let firstLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstVideoTrack)
        
        // Half this video in height and width and set it in the bottom right corner!
//        let scale = CGAffineTransform(scaleX: 0.5, y: 0.5)
//        let move = CGAffineTransform(translationX: finalVideoSize.width/2.0, y: finalVideoSize.height/2.0)
//
//        firstLayerInstruction.setTransform(scale.concatenating(move), at: CMTime.zero)
        
        // Create a video of size 0.3 x 0.3, move it to center and rotate by 30 degrees
        // Compute scale of the first video
//        let scale = CGAffineTransform(scaleX: 0.3, y: 0.3)
        let firstFrameSize = CGSize(width: frameOfFirstVideo.layer.bounds.width, height: frameOfFirstVideo.layer.bounds.height)
        // TODO: At present while scaling is not taking into account the natural size of video
        let scale = VAConstants.scale(of: firstFrameSize)
//        let scale = CGAffineTransform(scaleX: 1, y: 1)
        
//        let move = CGAffineTransform(translationX: finalVideoSize.width/2.0, y: finalVideoSize.height/2.0)
        let move = VAConstants.move(position: frameOfFirstVideo.center, inFrame: frameOfFirstVideo.layer.bounds, toVideoSize: finalVideoSize)
        
        // Set position to appropriate position
//        let rotate = CGAffineTransform(rotationAngle: CGFloat.pi/6.0)
        if let rotate = transformOfFirstVideoFrame {
            firstLayerInstruction.setTransform(rotate.concatenating(scale).concatenating(move), at: CMTime.zero)
//            firstLayerInstruction.transform
        } else {
            firstLayerInstruction.setTransform(move.concatenating(scale), at: CMTime.zero)
        }
        
        
        // Create second layer compostion instructions for the second video track
        
        let secondLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondVideoTrack)
//        let scaleSecondVideo = CGAffineTransform(scaleX: 1, y: 1)
        // Scale down the second vidoe by 50% both width and height wise
        let scaleSecondVideo = CGAffineTransform(scaleX: 0.25, y: 0.25)
        let moveSecondVideo = CGAffineTransform(translationX: finalVideoSize.width/1.25, y: 0)
        
        secondLayerInstruction.setTransform(scaleSecondVideo.concatenating(moveSecondVideo), at: CMTime.zero)
        
        
        // Add both video compostion layer instructions to main video compostion instruction
        videoCompostionInstruction.layerInstructions = [firstLayerInstruction, secondLayerInstruction]
        
        // Create video compostion. It will have one or more video compoistion instructions.
        // The instructions themselves will have one or more layer instructions
        
        let videoComposition = AVMutableVideoComposition()
        
        videoComposition.instructions = [videoCompostionInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
//        videoComposition.renderSize = CGSize(width: firstVideoTrack.naturalSize.width, height: firstVideoTrack.naturalSize.height)
        videoComposition.renderSize = finalVideoSize // Same sa UIScreen.bounds
//        videoComposition.renderSize = firstVideoTrack.naturalSize
        
        // For debuggging purpose
        videoComposition.isValid(for: nil, timeRange: CMTimeRangeMake(start: CMTime.zero, duration: CMTime.positiveInfinity), validationDelegate: self)
        
        // Add animation layer with a background image
        
        videoComposition.animationTool = VAConstants.createAnimationTool(withBackgoundImage: (backgroundImageView.image?.cgImage)!, withSize: finalVideoSize)
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .full
        let date = dateFormatter.string(from: Date())
        let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")
        
        // Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComposition
//        exporter.audioMix = audioMix
        
        print("Starting export asynchronously...")
        // Perform export asynchronously
        exporter.exportAsynchronously() {
            print("Finished export.. moving file to photo library...")
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
        
        
    }

    
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else { return }
        
        let saveVideoToPhotos = {
            PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL) }) { saved, error in
                let success = saved && (error == nil)
                let title = success ? "Success" : "Error"
                let message = success ? "Video saved" : "Failed to save video"
                
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        // Ensure permission to access Photo Library
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    saveVideoToPhotos()
                }
            })
        } else {
            saveVideoToPhotos()
        }
    }
    
}

extension ViewController: AVVideoCompositionValidationHandling {
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidValueForKey key: String) -> Bool {
        print("The key, \(key) not found!")
        return true
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingEmptyTimeRange timeRange: CMTimeRange) -> Bool {
        print("Empty time range found!")
        return true
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTimeRangeIn videoCompositionInstruction: AVVideoCompositionInstructionProtocol) -> Bool {
        print("Invalid time range in video compostion instruction")
        return true
    }
    
    func videoComposition(_ videoComposition: AVVideoComposition, shouldContinueValidatingAfterFindingInvalidTrackIDIn videoCompositionInstruction: AVVideoCompositionInstructionProtocol, layerInstruction: AVVideoCompositionLayerInstruction, asset: AVAsset) -> Bool {
        print("Found an invalid track")
        return true
    }
    
    
    
}
