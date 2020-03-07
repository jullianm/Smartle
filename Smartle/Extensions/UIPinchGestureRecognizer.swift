//
//  UIPinchGestureRecognizer.swift
//  Smartle
//
//  Created by Jullianm on 06/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import AVFoundation
import UIKit

extension UIPinchGestureRecognizer {
    func zoom(device: AVCaptureDevice, lastZoomFactor: inout CGFloat) {
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, 1.0), 3.0), device.activeFormat.videoMaxZoomFactor)
        }
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                device.videoZoomFactor = factor
            } catch {
                print(error.localizedDescription)
            }
        }
        let newScaleFactor = minMaxZoom(scale * lastZoomFactor)
        switch state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
}
