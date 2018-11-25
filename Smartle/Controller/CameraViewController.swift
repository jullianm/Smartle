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

class CameraViewController: UIViewController, UIApplicationDelegate {
    // MARK: Outlets
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var containerBubble: UIImageView!
    @IBOutlet weak var translatedText: UILabel!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var deleteItem: UIButton!
    @IBOutlet weak var favorites: UIImageView!
    @IBOutlet weak var titleView: UIView!
    
    // MARK: Properties
    var managedObjectContext: NSManagedObjectContext!
    var revisionEntity: NSEntityDescription!
    var mainEntity: NSEntityDescription!
    private var languagesList: UICollectionView!
    private var wordToTranslate: String!
    private var selectedRow: Int!
    private var input: AVCaptureDeviceInput?
    private lazy var captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer()
    private lazy var photoOutput = AVCapturePhotoOutput()
    private lazy var photoOutputSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])
    private lazy var bubble = UIImageView()
    private lazy var titleBottomLine = CALayer()
    private var userConfidence: Float = 0.0
    private let minimumZoom: CGFloat = 1.0
    private let maximumZoom: CGFloat = 3.0
    private var lastZoomFactor: CGFloat = 1.0


    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchMain()
        languagePicker.delegate = self
        languagePicker.dataSource = self
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
        let rotationAngle: CGFloat = -90 * (.pi/180)
        let x = languagePicker.frame.origin.x
        let y = languagePicker.frame.origin.y
        let width = languagePicker.frame.size.width
        let height = languagePicker.frame.size.height
        languagePicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        languagePicker.frame = CGRect(x: x, y: y, width: width, height: height)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        titleBottomLine.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        titleView.layer.addSublayer(titleBottomLine)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addToFavorites))
        favorites.addGestureRecognizer(tapGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        if let viewControllers = tabBarController?.viewControllers {
            let _ = viewControllers[1].view
        }
        setupSession()
        createLanguagesList()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captureSession.startRunning()
        container.isHidden = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
        bubble.frame = CGRect(x: containerBubble.frame.origin.x, y: containerBubble.frame.origin.y, width: containerBubble.bounds.size.width, height: containerBubble.bounds.size.height)
        languagesList.frame = CGRect(x:bubble.bounds.midX, y: bubble.bounds.midY, width: bubble.bounds.width/1.5, height: bubble.bounds.height/2)
        languagesList.center = CGPoint(x: bubble.bounds.midX, y: bubble.bounds.midY)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
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
            for (index, favoriteLanguage) in Countries.shared.favoritesLanguages.enumerated() where favoriteLanguage == Countries.shared.chosenLanguage {
                languagePicker.selectRow(index, inComponent: 0, animated: false)
                selectedRow = index
            }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        wordToTranslate = String()
        translatedText.text = ""
        favorites.image = UIImage(named: "smartle_favoritesEmpty")
    }
    @objc private func appMovedToBackground() {
        let fetchRequest = Main.createFetchRequest()
        do {
            let fetchResults = try managedObjectContext.fetch(fetchRequest)
            if fetchResults.count == 0 {
                saveMain()
            } else {
                for result in fetchResults {
                    result.favoritesItems = convertToData(items: Countries.shared.favoritesItems)
                    result.items = convertToData(items: Countries.shared.items)
                    result.favoritesLanguages = Countries.shared.favoritesLanguages
                    result.languages = Countries.shared.languages
                    result.chosenLanguage = Countries.shared.chosenLanguage
                }
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    // MARK: Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bubble.isUserInteractionEnabled == true {
            languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
            bubble.alpha = 0
            bubble.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
        }
    }
    private func createLanguagesList() {
        bubble.image = UIImage(named: "smartle_bubble")
        bubble.frame = CGRect(x: containerBubble.frame.origin.x, y: containerBubble.frame.origin.y, width: containerBubble.frame.width, height: containerBubble.frame.height)
        let layout = UICollectionViewFlowLayout()
        languagesList = UICollectionView(frame: CGRect(x:bubble.bounds.midX, y: bubble.bounds.midY, width: bubble.bounds.width/1.5, height: bubble.bounds.height/2), collectionViewLayout: layout)
        languagesList.backgroundColor = nil
        languagesList.showsVerticalScrollIndicator = false
        let cellNib = UINib(nibName: "CameraVCFlagCell", bundle: nil)
        languagesList.register(cellNib, forCellWithReuseIdentifier: "cameraFlagCell")
        languagesList.delegate = self
        languagesList.dataSource = self
        bubble.addSubview(languagesList)
        container.addSubview(bubble)
    }
    @objc private func addToFavorites() {
        if favorites.image == UIImage(named: "smartle_favoritesEmpty") && translatedText.text != "" {
        favorites.image = UIImage(named: "smartle_favorites")?.withRenderingMode(.alwaysTemplate)
        favorites.tintColor = UIColor.white
        let freshPhotoOutputSettings = AVCapturePhotoSettings(from: photoOutputSettings)
        photoOutput.capturePhoto(with: freshPhotoOutputSettings, delegate: self)
        }
    }
    @IBAction func changedConfidenceRate(_ sender: UISlider) {
        userConfidence = sender.value
    }
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        guard let device = input?.device else { return }
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
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
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        switch pinch.state {
        case .began: fallthrough
        case .changed: update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }
    private func fetchMain() {
        let fetchRequest = Main.createFetchRequest()
        do {
            let fetchResults = try managedObjectContext.fetch(fetchRequest)
            if fetchResults.count == 0 {
                Countries.shared.favoritesItems = [UIImage(named: "france")!, UIImage(named: "add_language")!]
                Countries.shared.items = [UIImage(named: "spain")!, UIImage(named: "germany")!, UIImage(named: "italy")!, UIImage(named: "china")!, UIImage(named: "arabic")!, UIImage(named: "great_britain")!, UIImage(named: "israel")!, UIImage(named: "japan")!, UIImage(named: "portugal")!, UIImage(named: "romania")!, UIImage(named: "russia")!, UIImage(named: "netherlands")!, UIImage(named: "korea")!, UIImage(named: "poland")!, UIImage(named: "greece")!]
                Countries.shared.favoritesLanguages = ["FR"]
                Countries.shared.languages = ["ES", "DE", "IT", "ZH", "AR", "EN", "HE", "JA", "PT", "RO", "RU", "NL", "KO", "PL", "EL"]
                Countries.shared.chosenLanguage = "FR"
            } else {
                for result in fetchResults {
                    Countries.shared.favoritesItems = convertToUIImages(items: result.favoritesItems)
                    Countries.shared.items = convertToUIImages(items: result.items)
                    Countries.shared.favoritesLanguages = result.favoritesLanguages
                    Countries.shared.languages = result.languages
                    Countries.shared.chosenLanguage = result.chosenLanguage
                }
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    private func saveMain() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        privateContext.perform {
            let main = Main(entity: self.mainEntity, insertInto: self.managedObjectContext)
            main.favoritesItems = convertToData(items: Countries.shared.favoritesItems)
            main.items = convertToData(items: Countries.shared.items)
            main.favoritesLanguages = Countries.shared.favoritesLanguages
            main.languages = Countries.shared.languages
            main.chosenLanguage = Countries.shared.chosenLanguage
            do {
                try main.managedObjectContext?.save()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    private func setupSession() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        input = try? AVCaptureDeviceInput(device: captureDevice)
        guard let input = input else { return }
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        guard captureSession.canAddInput(input) else { return }
        guard captureSession.canAddOutput(videoOutput) else { return }
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        captureSession.addInput(input)
        captureSession.addOutput(videoOutput)
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        cameraView.layer.addSublayer(previewLayer)
    }
    @IBAction func deleteFromFavorites(_ sender: Any) {
        if languagePicker.selectedRow(inComponent: 0) != Countries.shared.favoritesItems.count-1 && languagePicker.numberOfRows(inComponent: 0) > 2 {
            let row = languagePicker.selectedRow(inComponent: 0)
            for (index, language) in Countries.shared.favoritesLanguages.enumerated() where language == Countries.shared.chosenLanguage {
                Countries.shared.items.append(Countries.shared.favoritesItems[index])
                Countries.shared.favoritesItems.remove(at: index)
                Countries.shared.languages.append(Countries.shared.favoritesLanguages[index])
                Countries.shared.favoritesLanguages.remove(at: index)
            }
            if row >= 1 {
                languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                Countries.shared.chosenLanguage = Countries.shared.favoritesLanguages[row-1]
            } else {
                Countries.shared.chosenLanguage = Countries.shared.favoritesLanguages[0]
            }
            Translation.fetch(word: wordToTranslate, to: Countries.shared.chosenLanguage) { translation in
                self.translatedText.text = translation
            }
            languagePicker.reloadAllComponents()
            languagesList.reloadData()
            selectedRow = languagePicker.selectedRow(inComponent: 0)
        }
    }
    private func displayLanguagesMenu() {
        bubble.isUserInteractionEnabled = true
        bubble.animateWithAlpha()
        languagePicker.isUserInteractionEnabled = false
    }
}
// MARK: Capture Video
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !Countries.shared.languages.isEmpty {
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
            let request = VNCoreMLRequest(model: model) { success, error in
                guard let results = success.results as? [VNClassificationObservation] else { return }
                guard let firstObservation = results.first else { return }
                let modelConfidence = firstObservation.confidence
                let identifier = firstObservation.identifier
                let prediction: String
                if modelConfidence > self.userConfidence {
                    if identifier.contains(",") {
                        let array = identifier.components(separatedBy: ",")
                        prediction = array[0].capitalizingFirstLetter()
                    } else {
                        prediction = identifier.capitalizingFirstLetter()
                    }
                    if prediction != self.wordToTranslate {
                        self.wordToTranslate = prediction
                        Translation.fetch(word: self.wordToTranslate, to: Countries.shared.chosenLanguage, completion: { translation in
                            self.translatedText.text = translation
                            self.favorites.image = UIImage(named:"smartle_favoritesEmpty")
                            self.container.animateWithDamping()
                        })
                    }
                }
            }
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
}
// MARK: Capture Photo
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else { return }
        guard let translation = translatedText.text else { return }
        let revision = Revision(entity: revisionEntity, insertInto: managedObjectContext)
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        privateContext.perform {
            revision.photo = data
            revision.currentTranslation = translation
            revision.originalTranslation = translation
            revision.selectedLanguage = Countries.shared.chosenLanguage
            revision.date = NSDate()
            revision.favoritesItems = convertToData(items: Countries.shared.favoritesItems)
            revision.items = convertToData(items: Countries.shared.items)
            revision.languages = Countries.shared.languages
            revision.favoritesLanguages = Countries.shared.favoritesLanguages
            do {
                try revision.managedObjectContext?.save()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}
// MARK: CollectionView
extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Countries.shared.items.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraFlagCell", for: indexPath) as! CameraVCFlagCell
        cell.cameraVCFlag.image = Countries.shared.items[indexPath.item]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Countries.shared.favoritesItems.insert(Countries.shared.items[indexPath.item], at: Countries.shared.favoritesItems.count-1)
        Countries.shared.items.remove(at: indexPath.item)
        Countries.shared.favoritesLanguages.append(Countries.shared.languages[indexPath.item])
        Countries.shared.languages.remove(at: indexPath.item)
        languagePicker.reloadAllComponents()
        deleteItem.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = true
        Countries.shared.chosenLanguage = Countries.shared.favoritesLanguages.last!
        Translation.fetch(word: wordToTranslate, to: Countries.shared.chosenLanguage) { translation in
            self.translatedText.text = translation
        }
        selectedRow = languagePicker.selectedRow(inComponent: 0)
        bubble.alpha = 0
        bubble.isUserInteractionEnabled = false
        collectionView.reloadData()
    }
}
extension CameraViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height/2.5
        return CGSize(width: height, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
}
// MARK: PickerView
extension CameraViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach ({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Countries.shared.favoritesItems.count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let myView = UIView(frame: CGRect(x: pickerView.frame.origin.x, y: pickerView.frame.origin.y, width: pickerView.frame.size.width, height: pickerView.frame.size.height))
        let imageView = UIImageView(frame: CGRect(x: myView.bounds.midX, y: myView.bounds.midY, width: 20.0, height: 20.0))
        imageView.center = CGPoint(x: myView.bounds.midX, y: myView.bounds.midY)
        imageView.image = Countries.shared.favoritesItems[row]
        myView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        myView.addSubview(imageView)
        return myView
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.height
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == Countries.shared.favoritesItems.count-1 {
            if !Countries.shared.items.isEmpty {
                displayLanguagesMenu()
            } else {
                translatedText.text = "No available flags"
            }
        } else {
            selectedRow = row
            Countries.shared.chosenLanguage = Countries.shared.favoritesLanguages[row]
                Translation.fetch(word: wordToTranslate, to: Countries.shared.chosenLanguage) { translation in
                    self.translatedText.text = translation
            }
        }
    }
}

