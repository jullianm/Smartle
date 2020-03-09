//
//  CameraViewController.swift
//  Smartle
//
//  Created by jullianm on 20/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import CoreData
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources

class CameraViewController: BaseViewController, UIApplicationDelegate {
    // MARK: - UI
    @IBOutlet private weak var cameraView: UIImageView!
    @IBOutlet private weak var container: UIView! {
        didSet {
            container.addSubview(bubbleView)
            bubbleView.frame = container.bounds
        }
    }
    @IBOutlet private weak var favorites: UIImageView!
    @IBOutlet private weak var titleView: UIView!
    @IBOutlet private weak var confidenceSlider: UISlider!
    
    @IBOutlet var separatorLineConstraints: [NSLayoutConstraint]! {
        didSet {
            separatorLineConstraints.forEach { $0.constant = 0.2 }
        }
    }
    
    // MARK: - Photo & Camera Properties
    private var input: AVCaptureDeviceInput?
    private lazy var captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer()
    private lazy var photoOutput = AVCapturePhotoOutput()
    private lazy var photoOutputSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    private var lastZoomFactor: CGFloat = 1.0
    
    // MARK: - Storage
    var coreDataManager = CoreDataManager()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        coreDataManager.fetchMain()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
        container.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        container.isHidden = false
        container.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        favorites.image = UIImage(named: "smartle_favoritesEmpty")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
    }
    
    private func setupBindings() {
        setupGestures()
        setupSlider()
        setupSession()
        setupNotification()
        setupTranslatedText()
    }
}

// MARK: Photo & Video
extension CameraViewController: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        didCaptureOutput.accept(pixelBuffer)
    }
        

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard
            let data = photo.fileDataRepresentation(),
            let translation = bubbleView.translatedText.text else { return }
        
        coreDataManager.saveRevision(data: data, translation: translation)
    }
    
    
    private func setupSession() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        input = try? AVCaptureDeviceInput(device: captureDevice)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.configure(photoOutput: photoOutput,
                                 videoOutput: videoOutput,
                                 deviceInput: input)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        cameraView.layer.addSublayer(previewLayer)
    }
}

extension CameraViewController {
    private func addToFavorites() {
        if favorites.image == UIImage(named: "smartle_favoritesEmpty") && bubbleView.translatedText.text != "" {
            favorites.image = UIImage(named: "smartle_favorites")?.withRenderingMode(.alwaysTemplate)
            favorites.tintColor = UIColor.white
            
            photoOutput.capturePhoto(with: .init(from: photoOutputSettings), delegate: self)
        }
    }
}

extension CameraViewController {
    func setupGestures() {
        cameraView.rx.anyGesture(.tap(), .pinch())
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                
                switch gesture {
                case is UITapGestureRecognizer:
                    if self.bubbleView.bubbleImageView.isUserInteractionEnabled == true  {
                        self.bubbleView.languagesPicker.selectRow(self.selectedRow, inComponent: 0, animated: false)
                        self.bubbleView.bubbleImageView.alpha = 0
                        self.bubbleView.bubbleImageView.isUserInteractionEnabled = false
                        self.bubbleView.languagesPicker.isUserInteractionEnabled = true
                    }
                case let pinchGesture as UIPinchGestureRecognizer:
                    guard let device = self.input?.device else { return }
                    pinchGesture.zoom(device: device, lastZoomFactor: &self.lastZoomFactor)
                case _:
                    break
                }
            }).disposed(by: disposeBag)
        
        favorites.rx.tapGesture()
            .subscribe(onNext: { _ in
                self.addToFavorites()
            }).disposed(by: disposeBag)
    }
    
    
    func setupNotification() {
        NotificationCenter.default.rx
            .notification(.UIApplicationWillResignActive)
            .subscribe(onNext: { [weak self] _ in
                self?.coreDataManager.updateMain()
            }).disposed(by: disposeBag)
    }
    
    private func setupTranslatedText() {
        onTranslationDisplayed = { [weak self] in
            self?.favorites.image = UIImage(named:"smartle_favoritesEmpty")
            self?.container.animateWithDamping()
        }
    }
    
    func setupSlider() {
        confidenceSlider.rx.value
            .bind(to: userConfidence)
            .disposed(by: disposeBag)
    }
}

