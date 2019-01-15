//
//  Size and Position Manipulation.swift
//  PictureInPicture
//
//  Created by Pankaj Kulkarni on 15/01/19.
//  Copyright © 2019 Pankaj Kulkarni. All rights reserved.
//

import Foundation
import UIKit

struct VAConstants {
    public static let screenSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    public static let videoSize = CGSize(width: 1920, height: 1080)
    
    static func scale(of frame: CGSize, with screen: CGSize) -> CGAffineTransform {
        
        precondition(screen.width != 0 && screen.height != 0, "Wrond screen size provided")
        
        let xScale = frame.width / screen.width
        let yScale = frame.height / screen.height
        
        return CGAffineTransform(scaleX: xScale, y: yScale)
    }
    
    
    static func move(position: CGPoint, inFrame frame: CGRect,toVideoSize videoSize: CGSize) -> CGAffineTransform {
        precondition(videoSize.width != 0 && videoSize.height != 0, "Invalid video size")
        
        let xMovement = position.x * (videoSize.width / screenSize.width) - (frame.width/2.0)
        let yMovement = position.y * (videoSize.height / screenSize.height) - (frame.height/2.0)
        
        return CGAffineTransform(translationX: xMovement, y: yMovement)
    }
}
