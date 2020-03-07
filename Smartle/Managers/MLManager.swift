//
//  ModelManager.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import CoreVideo
import CoreMedia
import RxCocoa
import RxSwift
import Vision

class MLManager {
    static let shared = MLManager()
    typealias UserConfidence = Float
    typealias Input = (UserConfidence, CMSampleBuffer)
    
    let input = PublishRelay<Input>()
    let output = PublishRelay<String>()
    
    private var disposeBag = DisposeBag()
    
    private init() {
        bindPrediction()
    }
    
    private func bindPrediction() {
        input.bind(onNext: { [weak self] (confidence, sampleBuffer) in
                guard
                    let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                    let model = try? VNCoreMLModel(for: Resnet50().model) else {
                        print("called")
                        self?.output.accept(.init())
                        return
                }
                
                let request = VNCoreMLRequest(model: model) { success, error in
                    guard
                        let results = success.results as? [VNClassificationObservation],
                        let firstObservation = results.first else { return }
                    
                    if firstObservation.confidence > confidence {
                        let prediction = firstObservation.identifier.components(separatedBy: ",")[0].capitalizingFirstLetter()
                        self?.output.accept(prediction)
                    }
                }
                try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        })
        .disposed(by: disposeBag)
    }
}
