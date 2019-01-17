//
//  VideoCompositionManager.swift
//  PictureInPicture
//
//  Created by Pankaj Kulkarni on 17/01/19.
//  Copyright © 2019 Pankaj Kulkarni. All rights reserved.
//

import Foundation
import AVFoundation
import MobileCoreServices
import Photos


protocol VideoCompositionManagerProtocol {
    func exportCompleted (saved: Bool, error: Error?)
}

class VideoCompositionManager {
    
    enum VideoCompositionManagerError: Error {
        case missingInput
        
    }
    
    // MARK - User Input (Some are optional)
    public var delegate: VideoCompositionManagerProtocol?
    
    private var assetURLs = [URL]()
    private var backgroundImage: CGImage? = nil
    private var maskImages = [CGImage]()
    
    // size, position and orientation of the video
    private var videoFrames = [CGRect]()
    private var videoCenterPositions = [CGPoint]()
    private var rotationTransforms = [CGAffineTransform]()
    
    // MARK - Compute and store these properties
    private var videoAssets = [AVURLAsset]()
    private var mutableCompositeVideoTracks = [AVMutableCompositionTrack?]()
    private var videoAssetTracks = [AVAssetTrack]()
    private var timeRanges = [CMTimeRange]()
    
    
    // AVFoundation classes
    private let mutableComposition = AVMutableComposition()
    let videoCompostionInstruction = AVMutableVideoCompositionInstruction()
    
    private var isPlayingVideoOneAfterOther = false
    
    public func addVideoAssetURL (url: URL) {
        assetURLs.append(url)
    }
    
    public func setBackgroundImage(image: CGImage) {
        backgroundImage = image
    }
    
    public func addMaskImage(image: CGImage) {
        maskImages.append(image)
    }
    
    public func addCenter(_ center: CGPoint, andFrame frame: CGRect, withOrientationTransform transform: CGAffineTransform) {
        videoCenterPositions.append(center)
        videoFrames.append(frame)
        rotationTransforms.append(transform)
    }
    
    public func create() {
        
        guard assetURLs.count > 0,
            videoFrames.count > 0,
            videoCenterPositions.count > 0,
            rotationTransforms.count > 0 else {
                delegate?.exportCompleted(saved: false, error: VideoCompositionManagerError.missingInput)
                return
        }
        
        // 1. Load assets
        loadAssets()
        
        // 2. Add mutable tracks
        addMutableVideoTracks()
        
        // 3. Mix background and first video only
        createVideoWithBackgroundAndFirstVideo()
        
    }
    
    private func loadAssets() {
        for url in assetURLs {
            videoAssets.append(AVURLAsset(url: url))
        }
    }
    
    private func addMutableVideoTracks() {
        
        for videoAsset in videoAssets {
            
            let mutableTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            
            let timeRange = CMTimeRange(start: CMTime.zero, duration: videoAsset.duration)
            timeRanges.append(timeRange)
            let videoTrack = videoAsset.tracks(withMediaType: .video).first!
            videoAssetTracks.append(videoTrack)
            
            do {
                try mutableTrack?.insertTimeRange(timeRange, of: videoTrack, at: CMTime.zero)
            } catch {
                print("Error inserting time range into first compostion track! :\(error)")
                delegate?.exportCompleted(saved: false, error: error)
            }
            
            mutableCompositeVideoTracks.append(mutableTrack)
            
        }
    }
    
    private func createVideoWithBackgroundAndFirstVideo(){
        
        videoCompostionInstruction.timeRange = timeRanges[0]
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoAssetTracks[0])
        
        let moveTransform = getMoveTransform(forIndex: 0)
        
        layerInstruction.setTransform(rotationTransforms[0].concatenating(moveTransform), at: CMTime.zero)
        
        videoCompostionInstruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [videoCompostionInstruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = VAConstants.screenSize
        
        if let backgroundImage = backgroundImage {
            videoComposition.animationTool = VAConstants.createAnimationTool(withBackgoundImage: backgroundImage, withSize: VAConstants.screenSize)
        }
        
        // Export newly created video and report
        exportNewlyComposedVideo(composition: mutableComposition, videoComposition: videoComposition)
        
    }
    
    private func getMoveTransform(forIndex index: Int) -> CGAffineTransform {
        
        let xMovement = videoCenterPositions[index].x - videoFrames[index].size.width
        let yMovement = videoCenterPositions[index].y - videoFrames[index].size.height
        
        return CGAffineTransform(translationX: xMovement, y: yMovement)
        
    }
    
    func exportNewlyComposedVideo(composition mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition) {
        
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
        
        print("VideoCompositionManager: Starting export asynchronously...")
        // Perform export asynchronously
        exporter.exportAsynchronously() {
            print("VideoCompositionManager: Finished export.. moving file to photo library...")
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
                
                DispatchQueue.main.async {
                    self.delegate?.exportCompleted(saved: saved, error: error)
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
