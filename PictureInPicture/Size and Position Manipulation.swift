//
//  Size and Position Manipulation.swift
//  PictureInPicture
//
//  Created by Pankaj Kulkarni on 15/01/19.
//  Copyright © 2019 Pankaj Kulkarni. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

struct VAConstants {
    public static let screenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    public static let videoSize = CGSize(width: 1920, height: 1080)
    
    static func scale(of frame: CGSize) -> CGAffineTransform {
        
        
        let xScale = frame.width / screenSize.width
        let yScale = frame.height / screenSize.height
        
        return CGAffineTransform(scaleX: xScale, y: yScale)
    }
    
    
    static func move(position: CGPoint, inFrame frame: CGRect,toVideoSize videoSize: CGSize) -> CGAffineTransform {
        precondition(videoSize.width != 0 && videoSize.height != 0, "Invalid video size")
        
        let xScale = videoSize.width / screenSize.width
        let yScale = videoSize.height / screenSize.height
        
        // In is center postion and out is movement of top-left position
        let xMovement = (position.x - (frame.width/2.0)) * xScale
        let yMovement = (position.y - (frame.height/2.0)) * yScale
        
        return CGAffineTransform(translationX: xMovement, y: yMovement)
    }
    
    
    
    static func createAnimationTool(withBackgoundImage image: CGImage, withSize videoSize: CGSize) -> AVVideoCompositionCoreAnimationTool? {
        // Get screen shot using the main view controller functionality
        let backgroundLayer = CALayer()
        backgroundLayer.contents = image
        backgroundLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        backgroundLayer.masksToBounds = true
        
        let videoLayer = CALayer()
//        videoLayer.frame = CGRect(x: 100.0, y: 100.0, width: videoSize.width/2, height: videoSize.height/2)
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        parentLayer.addSublayer(backgroundLayer)
        parentLayer.addSublayer(videoLayer)
        
        return AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
//        return AVVideoCompositionCoreAnimationTool(additionalLayer: parentLayer, asTrackID: kCMPersistentTrackID_Invalid)
        
    }
    
}
