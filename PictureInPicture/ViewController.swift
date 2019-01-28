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
    
    var redViewPosition: CGPoint!
    
    
    @IBOutlet var panGestureRecogniser: UIPanGestureRecognizer!
    @IBOutlet var pinchGestureRecogniser: UIPinchGestureRecognizer!
    @IBOutlet var rotateGestureRecogniser: UIRotationGestureRecognizer!
    
    // MARK: - Gesture handling
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        
        // #Option 1
//        if sender.state == .began {
//            // Store the initila state
//            redViewPosition = sender.view?.center
//        }
//
//        let card = sender.view!
//        let point = sender.translation(in: view)
//        card.center = CGPoint(x: redViewPosition.x + point.x, y: redViewPosition.y + point.y)
//
////        // Bring it ack to original position
////        if sender.state == .ended {
////            UIView.animate(withDuration: 0.3) {
////                card.center = self.redViewPosition
////            }
////        }
        
        // #Option 2
        if let card = sender.view {
        let translation = sender.translation(in: view)
        card.center = CGPoint(x: card.center.x + translation.x, y: card.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: view)
        
        }
    }
    
    @IBAction func handlePinch(_ sender: UIPinchGestureRecognizer) {
        
        sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
        sender.scale = 1
        
        
    }
    
    
    @IBAction func handleRotation(_ sender: UIRotationGestureRecognizer) {
        
        sender.view?.transform = (sender.view?.transform.rotated(by: sender.rotation))!
        sender.rotation = 0
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        print("Tapped: \(sender.view)")
    }
    
    
    fileprivate func loadVideoAssets() {
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

    private func setDelegateOfGestureRecognisers() {
        panGestureRecogniser.delegate = self
        pinchGestureRecogniser.delegate = self
        rotateGestureRecogniser.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadVideoAssets()
        setDelegateOfGestureRecognisers()
        
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
        let moveSecondVideo = CGAffineTransform(translationX: finalVideoSize.width/2, y: finalVideoSize.height/2)
        
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
        
        
       exportNewlyComposedVideo(composition: mixComposition, videoComposition: videoComposition, audioMix: AVMutableAudioMix())
        
    }

    
    func exportNewlyComposedVideo(composition mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, audioMix: AVMutableAudioMix) {
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
        exporter.audioMix = audioMix
        
        print("Starting export asynchronously...")
        // Perform export asynchronously
        exporter.exportAsynchronously() {
            print("Finished export.. moving file to photo library...")
            DispatchQueue.main.async {
                self.exportDidFinish(exporter)
            }
        }
        
    }
    
    
    @IBAction func recordPressed(_ sender: UIButton) {
   
        let mutableComposition = AVMutableComposition()
        
        let firstAddedMutableVideoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let timeRange = CMTimeRange(start: CMTime.zero, duration: firstAsset.duration)
        
        let firstVideoTrackOfFirstAsset = firstAsset.tracks(withMediaType: .video).first!
        
        do {
            try firstAddedMutableVideoTrack?.insertTimeRange(timeRange, of: firstVideoTrackOfFirstAsset, at: CMTime.zero)
            
        } catch {
            fatalError("Error inserting time range into first compostion track! :\(error)")
        }
        
        let mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        mutableVideoCompositionInstruction.timeRange = timeRange
        
        let mutableVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstAddedMutableVideoTrack!)
        
        mutableVideoLayerInstruction.setTransform(firstVideoTrackOfFirstAsset.preferredTransform, at: CMTime.zero)
        
        mutableVideoCompositionInstruction.layerInstructions = [mutableVideoLayerInstruction]
        
        let mutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mutableVideoComposition.renderSize = UIScreen.main.bounds.size
        
        // Add audio track
        let audioMix = AVMutableAudioMix()
        let mutableAudioComposition = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioAssetTrack = firstAsset.tracks(withMediaType: .audio).first!
        
        do {
            try mutableAudioComposition?.insertTimeRange(timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            fatalError("Error inserting time range into first audio track! :\(error)")
        }
        
        let mutableAudioMixInputParameter = AVMutableAudioMixInputParameters(track: audioAssetTrack)
        
        mutableAudioMixInputParameter.setVolume(1.0, at: CMTime.zero)
        
        audioMix.inputParameters = [mutableAudioMixInputParameter]
        
        // Create and add animation tool
        let backgroundLayer = CALayer()
        backgroundLayer.contents = backgroundImageView.image?.cgImage
        backgroundLayer.frame = UIScreen.main.bounds
        backgroundLayer.masksToBounds = true
        
        let videoLayer = CALayer()
        let topLeftPosition = CGPoint(x: frameOfFirstVideo.center.x - (frameOfFirstVideo.bounds.width/2), y: UIScreen.main.bounds.height - frameOfFirstVideo.center.y - frameOfFirstVideo.bounds.height/2)
        videoLayer.frame = CGRect(origin: topLeftPosition, size:frameOfFirstVideo.bounds.size)
        
        let diplayFrameLayer = CALayer()
        diplayFrameLayer.frame = videoLayer.frame
        diplayFrameLayer.setAffineTransform(frameOfFirstVideo.transform.inverted())
        diplayFrameLayer.contents = frameOfFirstVideo.image?.cgImage!
        diplayFrameLayer.masksToBounds = true
        diplayFrameLayer.contentsGravity = .resizeAspect
        
        // Add masking specifically for the xMasTemplate1Frame2 (mask image name is: xMasTemplate1Frame2Mask)
        let maskLayer = CALayer()
        maskLayer.contents = UIImage(named: "xMasTemplate1Frame2Mask")?.cgImage
        maskLayer.frame = diplayFrameLayer.bounds
        maskLayer.contentsGravity = .resizeAspect
        videoLayer.mask = maskLayer
        videoLayer.masksToBounds = true
        videoLayer.setAffineTransform(frameOfFirstVideo.transform.inverted())
        
        let parentLayer = CALayer()
        parentLayer.frame = UIScreen.main.bounds
        
        parentLayer.addSublayer(backgroundLayer)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(diplayFrameLayer)
        
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        exportNewlyComposedVideo(composition: mutableComposition, videoComposition: mutableVideoComposition,audioMix: audioMix)
    }
    
    
    
    func exportDidFinish(_ session: AVAssetExportSession) {
        
        guard session.status == AVAssetExportSession.Status.completed,
            let outputURL = session.outputURL else {
                
                print("Export failed!")
                return
        }
        
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
    
    @IBOutlet weak var redView: UIView!
    @IBAction func inspectRedView(_ sender: UIButton) {
        print("Center: \(redView.center)")
        print("Frame: \(redView.frame)")
        print("Bounds: \(redView.bounds)")
        print("Transform: \(redView.transform)")
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

extension ViewController: VideoCompositionManagerProtocol {
    
    func exportCompleted(saved: Bool, error: Error?) {
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

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
