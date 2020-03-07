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

class CameraViewController: UIViewController, UIApplicationDelegate {
    // MARK: Outlets
    @IBOutlet private weak var cameraView: UIImageView!
    @IBOutlet private weak var container: UIView! {
        didSet {
            container.addSubview(bubble)
        }
    }
    @IBOutlet private weak var containerBubble: UIImageView! {
        didSet {
            bubble.frame = CGRect(x: containerBubble.frame.origin.x,
                                  y: containerBubble.frame.origin.y,
                                  width: containerBubble.frame.width,
                                  height: containerBubble.frame.height)
        }
    }
    @IBOutlet private weak var translatedText: UILabel!
    @IBOutlet private weak var languagePicker: UIPickerView! {
        didSet {
            languagePicker.transform = CGAffineTransform(rotationAngle: -90 * (.pi/180))
            languagePicker.frame = CGRect(x: languagePicker.frame.origin.x, y: languagePicker.frame.origin.y,
                                          width: languagePicker.frame.size.width, height: languagePicker.frame.size.height)
        }
    }
    @IBOutlet private weak var deleteItem: UIButton!
    @IBOutlet private weak var favorites: UIImageView!
    @IBOutlet private weak var titleView: UIView! {
        didSet {
            titleView.layer.addSublayer(titleBottomLine)
        }
    }
    @IBOutlet private weak var confidenceSlider: UISlider!
    
    // MARK: UI Properties
    private lazy var languagesList: UICollectionView = {
        let languagesList = UICollectionView(frame: .init() , collectionViewLayout: .init())
        languagesList.backgroundColor = nil
        languagesList.showsVerticalScrollIndicator = false
        let cellNib = UINib(nibName: "CameraVCFlagCell", bundle: nil)
        languagesList.register(cellNib, forCellWithReuseIdentifier: "cameraFlagCell")
        
        return languagesList
    }()
    
    private lazy var bubble: UIImageView = {
        let bubble = UIImageView()
        bubble.image = UIImage(named: "smartle_bubble")
        bubble.addSubview(languagesList)
        
        return bubble
    }()
    
    // MARK: Camera Session Properties
    private var input: AVCaptureDeviceInput?
    private lazy var captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer()
    private lazy var photoOutput = AVCapturePhotoOutput()
    private lazy var photoOutputSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    
    private var wordToTranslate = BehaviorRelay<String>(value: .init())

    private lazy var titleBottomLine: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        layer.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        
        return layer
    }()
    
    private var selectedRow: Int!
    private var lastZoomFactor: CGFloat = 1.0
    
    private var disposeBag = DisposeBag()
    var coreDataManager = CoreDataManager()
    private var didCaptureOutput = PublishRelay<CMSampleBuffer>()
    private var userConfidence = BehaviorRelay<Float>(value: 0.0)

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        coreDataManager.fetchMain()
        setupBindings()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
        container.isHidden = true
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        container.isHidden = false
        container.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        bubble.alpha = 0
        languagePicker.reloadAllComponents()
        languagesList.reloadData()
        bubble.isUserInteractionEnabled = false
        languagePicker.isUserInteractionEnabled = true
        let index = LanguageManager.shared.favoritesLanguages.enumerated().first(where: { $0.element == LanguageManager.shared.chosenLanguage })?.offset ?? 0
        languagePicker.selectRow(index, inComponent: 0, animated: false)
        selectedRow = index
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        translatedText.text = ""
        favorites.image = UIImage(named: "smartle_favoritesEmpty")
    }
    
    private func setupBindings() {
        setupGestures()
        
        setupCollectionView()
        setupPickerView()
        setupSlider()
        
        setupSession()
        setupNotification()
        
        setupMLInput()
        setupMLOutput()
        setupTranslation()
    }
    
    private func displayLanguagesMenu() {
        bubble.isUserInteractionEnabled = true
        bubble.animateWithAlpha()
        languagePicker.isUserInteractionEnabled = false
    }
    
    private func displayEmptyText() {
        translatedText.text = "No available flags"
    }
    
    private func updateLayout() {
        previewLayer.frame = cameraView.bounds
        bubble.frame = CGRect(x: containerBubble.frame.origin.x, y: containerBubble.frame.origin.y, width: containerBubble.bounds.size.width, height: containerBubble.bounds.size.height)
        languagesList.frame = CGRect(x:bubble.bounds.midX, y: bubble.bounds.midY, width: bubble.bounds.width/1.5, height: bubble.bounds.height/2)
        languagesList.center = CGPoint(x: bubble.bounds.midX, y: bubble.bounds.midY)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
    }
    
    private func willMoveToBackground() {
        let fetchResults = try? coreDataManager.managedObjectContext.fetch(Main.createFetchRequest())
        if fetchResults?.count == 0 {
            coreDataManager.saveMain()
        } else {
            fetchResults?.forEach { result in
                result.favoritesItems = LanguageManager.shared.favoritesItems.data()
                result.items = LanguageManager.shared.items.data()
                result.favoritesLanguages = LanguageManager.shared.favoritesLanguages
                result.languages = LanguageManager.shared.languages
                result.chosenLanguage = LanguageManager.shared.chosenLanguage
            }
        }
    }
}

// MARK: Photo & Video
extension CameraViewController: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        didCaptureOutput.accept(sampleBuffer)
    }
    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//        guard let data = photo.fileDataRepresentation(), let translation = translatedText.text else { return }
//        coreDataManager.saveRevision(data: data, translation: translation)
//    }
    
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

// MARK: Favorites
extension CameraViewController {
    private func addToFavorites() {
        if favorites.image == UIImage(named: "smartle_favoritesEmpty") && translatedText.text != "" {
            favorites.image = UIImage(named: "smartle_favorites")?.withRenderingMode(.alwaysTemplate)
            favorites.tintColor = UIColor.white
            
            photoOutput.capturePhoto(with: .init(from: photoOutputSettings), delegate: self)
        }
    }

    @IBAction func deleteFromFavorites(_ sender: Any) {
        if languagePicker.selectedRow(inComponent: 0) != LanguageManager.shared.favoritesItems.count-1 && languagePicker.numberOfRows(inComponent: 0) > 2 {
            let row = languagePicker.selectedRow(inComponent: 0)
            LanguageManager.shared.deleteFavoriteLanguage()
            
            if row >= 1 {
                languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row-1]
            } else {
                LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[0]
            }
            
            TranslationManager.shared.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
            
            languagePicker.reloadAllComponents()
            languagesList.reloadData()
            selectedRow = languagePicker.selectedRow(inComponent: 0)
        }
    }
}

// MARK: UI Bindings
extension CameraViewController {
    func setupGestures() {
        view.rx.anyGesture(.tap(), .pinch())
            .subscribe(onNext: { [weak self] gesture in
                guard let self = self else { return }
                
                switch gesture {
                case is UITapGestureRecognizer:
                    if self.bubble.isUserInteractionEnabled == true {
                        self.languagePicker.selectRow(self.selectedRow, inComponent: 0, animated: false)
                        self.bubble.alpha = 0
                        self.bubble.isUserInteractionEnabled = false
                        self.languagePicker.isUserInteractionEnabled = true
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
    
    func setupCollectionView() {
        Observable.of(LanguageManager.shared.items)
            .bind(to: languagesList.rx.items(cellIdentifier: "cameraFlagCell", cellType: CameraVCFlagCell.self)) { index, model, cell in
                cell.cameraVCFlag.image = LanguageManager.shared.items[index]
        }.disposed(by: disposeBag)
        
        languagesList.rx.itemSelected
            .bind(onNext: { indexPath in
                LanguageManager.shared.updateFavoriteLanguage(atIndex: indexPath.item)
                
                self.languagePicker.reloadAllComponents()
                self.languagePicker.isUserInteractionEnabled = true
                self.bubble.alpha = 0
                self.bubble.isUserInteractionEnabled = false
                self.deleteItem.isUserInteractionEnabled = true
                self.selectedRow = self.languagePicker.selectedRow(inComponent: 0)
                self.languagesList.reloadData()
                
                TranslationManager.shared.translate(word: self.wordToTranslate.value,
                                                 to: LanguageManager.shared.chosenLanguage)
            }).disposed(by: disposeBag)
    }
    
    private func setupPickerView() {
        Observable.of(LanguageManager.shared.favoritesItems)
            .bind(to: languagePicker.rx.items) { [weak self] (row, element, view) in
                guard let self = self else { return .init() }
                
                let flagView = UIView(frame: CGRect(x: self.languagePicker.frame.origin.x,
                                                    y: self.languagePicker.frame.origin.y,
                                                    width: self.languagePicker.frame.size.width,
                                                    height: self.languagePicker.frame.size.height))
                
                let imageView = UIImageView(frame: CGRect(x: flagView.bounds.midX, y: flagView.bounds.midY, width: 20.0, height: 20.0))
                imageView.center = CGPoint(x: flagView.bounds.midX, y: flagView.bounds.midY)
                imageView.image = LanguageManager.shared.favoritesItems[row]
                
                flagView.transform = .init(rotationAngle: 90 * (.pi/180))
                flagView.addSubview(imageView)
                
                return flagView
            }.disposed(by: disposeBag)
        
        languagePicker.rx.itemSelected
            .bind(onNext: { [weak self] row, component in
                guard let self = self else { return }
                                
                if row == LanguageManager.shared.favoritesItems.count-1 {
                    !LanguageManager.shared.items.isEmpty ? self.displayLanguagesMenu(): self.displayEmptyText()
                } else {
                    self.selectedRow = row
                    LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row]
                    TranslationManager.shared.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
                }
            }).disposed(by: disposeBag)
    }
    
    func setupNotification() {
        NotificationCenter.default.rx
            .notification(.UIApplicationWillResignActive)
            .subscribe(onNext: { _ in
                self.willMoveToBackground()
            }).disposed(by: disposeBag)
    }
}

// MARK: - ML bindings
extension CameraViewController {
    private func setupMLInput() {
        didCaptureOutput
            .map { (self.userConfidence.value, $0) }
            .bind(to: MLManager.shared.input)
            .disposed(by: disposeBag)
    }
    
    private func setupMLOutput() {
        MLManager.shared.output
            .distinctUntilChanged()
            .bind(onNext: { str in
                TranslationManager.shared.translate(word: str, to: LanguageManager.shared.chosenLanguage)
            }).disposed(by: disposeBag)
    }
    
    func setupTranslation() {
        TranslationManager.shared.translation
            .do(onNext: { [weak self] _ in
                self?.favorites.image = UIImage(named:"smartle_favoritesEmpty")
                self?.container.animateWithDamping()
            })
            .drive(translatedText.rx.text)
            .disposed(by: disposeBag)
    }
    
    func setupSlider() {
        confidenceSlider.rx.value
            .bind(to: userConfidence)
            .disposed(by: disposeBag)
    }
}
