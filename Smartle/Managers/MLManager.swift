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
    typealias UserConfidence = Float
    typealias Input = (UserConfidence, CVPixelBuffer)
    
    let input = PublishRelay<Input>()
    private let _output = PublishRelay<String>()
    var output: Observable<String> {
        return _output.asObservable()
            .distinctUntilChanged()
            .filter { !$0.isEmpty }
    }
    
    private var disposeBag = DisposeBag()
    
    init() {
        bindPrediction()
    }
    
    private func bindPrediction() {
        input
            .throttle(.milliseconds(350), scheduler: MainScheduler.instance)
            .bind(onNext: { [weak self] (confidence, pixelBuffer) in
                guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
                    self?._output.accept(.init())
                    return
                }
                
                let request = VNCoreMLRequest(model: model) { success, error in
                    guard
                        let results = success.results as? [VNClassificationObservation],
                        let firstObservation = results.first else { return }
                    
                    if firstObservation.confidence > confidence {
                        let prediction = firstObservation.identifier.components(separatedBy: ",")[0].capitalizingFirstLetter()
                        self?._output.accept(prediction)
                    }
                }
                try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
            })
            .disposed(by: disposeBag)
    }
    
    func reset() {
        _output.accept(.init())
    }
}
