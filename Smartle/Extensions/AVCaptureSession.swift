//
//  AVCaptureSession.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import AVFoundation

extension AVCaptureSession {
    func configure(photoOutput: AVCapturePhotoOutput,
                   videoOutput: AVCaptureVideoDataOutput,
                   deviceInput: AVCaptureDeviceInput?) {
        
        guard
            let deviceInput = deviceInput,
            canAddInput(deviceInput),
            canAddOutput(videoOutput),
            canAddOutput(photoOutput) else { return }
        
        beginConfiguration()
        sessionPreset = .photo
        
        addInput(deviceInput)
        addOutput(videoOutput)
        addOutput(photoOutput)
        commitConfiguration()
    }
}
