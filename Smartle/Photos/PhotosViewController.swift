//
//  PhotosViewController.swift
//  Smartle
//
//  Created by jullianm on 20/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//
import UIKit
import Photos
import Vision
import CoreData
import RxSwift

class PhotosViewController: UIViewController, UIApplicationDelegate {
    // MARK: Outlets
    @IBOutlet weak var photoGallery: UICollectionView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var translatedText: UILabel!
    @IBOutlet weak var containerBubble: UIImageView!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var deleteItem: UIButton!
    @IBOutlet weak var favorites: UIImageView!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var titleView: UIView!
    
    // MARK: Properties
    private lazy var cachingImageManager = PHCachingImageManager()
    private lazy var galleryAssets = [PHAsset]()
    private lazy var thumbnailsAssets = [PHAsset]()
    private lazy var options = PHImageRequestOptions()
    private lazy var bubble = UIImageView()
    private lazy var titleBottomLine = CALayer()
    private lazy var previewBottomLine = CALayer()
    private var photo: UIImage!
    private var languagesList: UICollectionView!
    private var wordToTranslate: String!
    private var lastSelectedRow: Int!
    private var userConfidence: Float = 0.0
    private var itemIndexPath = 0
    private var startPrediction = false {
        didSet {
            if startPrediction {
                predict(from: photo)
            }
        }
    }
    private var didSelectAFirstITem = false
    var disposeBag = DisposeBag()
    var coreDataManager = CoreDataManager()
    
//     MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        photoGallery.delegate = self
        photoGallery.dataSource = self
        languagePicker.delegate = self
        languagePicker.dataSource = self
        PHPhotoLibrary.shared().register(self)
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
        let rotationAngle: CGFloat = -90 * (.pi/180)
        let x = languagePicker.frame.origin.x
        let y = languagePicker.frame.origin.y
        let width = languagePicker.frame.size.width
        let height = languagePicker.frame.size.height
        languagePicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        languagePicker.frame = CGRect(x: x, y: y, width: width, height: height)
        let tapGestureFavorites = UITapGestureRecognizer(target: self, action: #selector(addToFavorites))
        favorites.addGestureRecognizer(tapGestureFavorites)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        titleBottomLine.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        titleView.layer.addSublayer(titleBottomLine)
        previewBottomLine.frame = CGRect(x: 0.0, y: previewImage.frame.height-0.2, width: previewImage.frame.width, height: 0.2)
        previewBottomLine.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        previewImage.layer.addSublayer(previewBottomLine)
        grabPhotos()
        createLanguagesList()
        setupTranslatedText()
    }
    
    func setupTranslatedText() {
        TranslationManager.shared.translation
            .do(onNext: { [weak self] _ in
                self?.favorites.image = UIImage(named:"smartle_favoritesEmpty")
                self?.container.animateWithDamping()
            })
            .drive(translatedText.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bubble.alpha = 0
        languagePicker.reloadAllComponents()
        languagesList.reloadData()
        languagePicker.isUserInteractionEnabled = true
        bubble.isUserInteractionEnabled = false
        for (index, language) in LanguageManager.shared.favoritesLanguages.enumerated() where language == LanguageManager.shared.chosenLanguage {
            if languagePicker.selectedRow(inComponent: 0) != index {

                TranslationManager.shared.translate(word: wordToTranslate, to: LanguageManager.shared.chosenLanguage)

                languagePicker.selectRow(index, inComponent: 0, animated: false)
                lastSelectedRow = index
            }
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bubble.frame = CGRect(x: containerBubble.frame.origin.x, y: containerBubble.frame.origin.y, width: containerBubble.bounds.size.width, height: containerBubble.bounds.size.height)
        languagesList.frame = CGRect(x:bubble.bounds.midX, y: bubble.bounds.midY, width: bubble.bounds.width/1.5, height: bubble.bounds.height/2)
        languagesList.center = CGPoint(x: bubble.bounds.midX, y: bubble.bounds.midY)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        previewBottomLine.frame = CGRect(x: 0.0, y: previewImage.frame.height-0.2, width: previewImage.frame.width, height: 0.2)
    }
     // MARK: Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bubble.isUserInteractionEnabled == true {
            languagePicker.selectRow(lastSelectedRow, inComponent: 0, animated: false)
            bubble.alpha = 0
            bubble.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
        }
    }
    private func createLanguagesList() {
        bubble.image = UIImage(named: "smartle_bubble")
        bubble.frame = CGRect(x: containerBubble.frame.origin.x, y: containerBubble.frame.origin.y, width: containerBubble.bounds.size.width, height: containerBubble.bounds.size.height)
        let layout = UICollectionViewFlowLayout()
        languagesList = UICollectionView(frame: CGRect(x:bubble.frame.midX, y: bubble.frame.midY, width: bubble.bounds.width/1.5, height: bubble.bounds.height/2), collectionViewLayout: layout)
        languagesList.backgroundColor = nil
        languagesList.showsVerticalScrollIndicator = false
        let cellNib = UINib(nibName: "PhotosVCFlagCell", bundle: nil)
        languagesList.register(cellNib, forCellWithReuseIdentifier: "photosFlagCell")
        languagesList.delegate = self
        languagesList.dataSource = self
        bubble.addSubview(languagesList)
        container.addSubview(bubble)
    }
    private func grabPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        assets.enumerateObjects { asset, _, _ in
            self.galleryAssets.append(asset)
            self.thumbnailsAssets.append(asset)
        }
        cachingImageManager.startCachingImages(for: thumbnailsAssets, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options)
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .none
            PHImageManager.default().requestImage(for: galleryAssets[IndexPath(item: 0, section: 0).item], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, info in
                
                guard let result = result else { return }
                self.previewImage.image = result.resized(frame: self.previewImage.frame)
                self.photo = result
                self.startPrediction = true
                for (index, language) in LanguageManager.shared.favoritesLanguages.enumerated() where language == LanguageManager.shared.chosenLanguage {
                    self.languagePicker.selectRow(index, inComponent: 0, animated: false)
                    self.lastSelectedRow = index
                }
            }
        }
    }
    
    @objc private func addToFavorites() {
        if favorites.image == UIImage(named: "smartle_favoritesEmpty") {
            favorites.image = UIImage(named: "smartle_favorites")?.withRenderingMode(.alwaysTemplate)
            favorites.tintColor = UIColor.white
            var myData: Data?
            cachingImageManager.requestImage(for: self.thumbnailsAssets[itemIndexPath], targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { result, info in
                    guard let result = result else { return }
                    myData = UIImagePNGRepresentation(result)
                }
            guard let data = myData else { return }
            guard let translation = translatedText.text else { return }
            let revision = Revision(entity: coreDataManager.revisionEntity, insertInto: coreDataManager.managedObjectContext)
            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            privateContext.persistentStoreCoordinator = coreDataManager.managedObjectContext.persistentStoreCoordinator
            privateContext.perform {
                revision.photo = data
                if self.wordToTranslate == "" {
                    revision.currentTranslation = "..."
                    revision.originalTranslation = "..."
                } else {
                    revision.currentTranslation = translation
                    revision.originalTranslation = translation
                }
                revision.selectedLanguage = LanguageManager.shared.chosenLanguage
                revision.date = NSDate()
                revision.favoritesItems = LanguageManager.shared.favoritesItems.data()
                revision.items = LanguageManager.shared.items.data()
                revision.languages = LanguageManager.shared.languages
                revision.favoritesLanguages = LanguageManager.shared.favoritesLanguages
                self.coreDataManager.saveContext()
            }
        }
    }
    @IBAction func deleteFromFavorites(_ sender: Any) {
        if languagePicker.selectedRow(inComponent: 0) != LanguageManager.shared.favoritesItems.count-1 && languagePicker.numberOfRows(inComponent: 0) > 2 {
            let row = languagePicker.selectedRow(inComponent: 0)
            for (index, language) in LanguageManager.shared.favoritesLanguages.enumerated() where language == LanguageManager.shared.chosenLanguage {
                LanguageManager.shared.items.append(LanguageManager.shared.favoritesItems[index])
                LanguageManager.shared.favoritesItems.remove(at: index)
                LanguageManager.shared.languages.append(LanguageManager.shared.favoritesLanguages[index])
                LanguageManager.shared.favoritesLanguages.remove(at: index)
            }
            if row >= 1 {
                languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row-1]
            } else {
                LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[0]
            }
            
            TranslationManager.shared.translate(word: wordToTranslate, to: LanguageManager.shared.chosenLanguage)
            
            languagePicker.reloadAllComponents()
            languagesList.reloadData()
            lastSelectedRow = languagePicker.selectedRow(inComponent: 0)
        }
    }
    @IBAction func changedConfidenceRate(_ sender: UISlider) {
        userConfidence = sender.value
    }
    private func predict(from photo: UIImage) {
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
                    
                    TranslationManager.shared.translate(word: self.wordToTranslate, to: LanguageManager.shared.chosenLanguage)
                    
                }
            } else {
                self.container.transform = CGAffineTransform(scaleX: 0, y: 0)
                self.wordToTranslate = String()
                self.translatedText.text = ""
            }
        }
        if let photoImage = photo.cgImage, let pixelBuffer = ImageManager.shared.pixelBuffer(forImage: photoImage) {
            try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        }
    }
    private func displayLanguagesMenu() {
        bubble.isUserInteractionEnabled = true
        bubble.animateWithAlpha()
        languagePicker.isUserInteractionEnabled = false
    }
}
// MARK: CollectionViews
extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == photoGallery {
        return galleryAssets.count
        } else {
            return LanguageManager.shared.items.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == photoGallery {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell", for: indexPath) as! PhotosCell
                if !didSelectAFirstITem && indexPath.item == 0 {
                    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    cell.alpha = 0.3
                }
            cachingImageManager.requestImage(for: thumbnailsAssets[indexPath.item], targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { photo, info in
                guard let photo = photo else { return }
                cell.photo.image = photo
        }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosFlagCell", for: indexPath) as! PhotosVCFlagCell
            cell.photosVCFlag.image = LanguageManager.shared.items[indexPath.item]
            return cell
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == photoGallery {
            if itemIndexPath != indexPath.item {
                didSelectAFirstITem = true
                let cell = collectionView.cellForItem(at: indexPath) as! PhotosCell
                cell.alpha = 0.3
                itemIndexPath = indexPath.item
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.resizeMode = .none
                
                PHImageManager.default().requestImage(for: galleryAssets[indexPath.item], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, info in
                    guard let result = result else { return }
                    self.previewImage.image = result.resized(frame: self.previewImage.frame)
                    self.photo = result
                    self.startPrediction = true
                    self.container.transform = CGAffineTransform(scaleX: 0, y: 0)
                    self.favorites.image = UIImage(named: "smartle_favoritesEmpty")
                }
            }
        } else {
            LanguageManager.shared.favoritesItems.insert(LanguageManager.shared.items[indexPath.item], at: LanguageManager.shared.favoritesItems.count-1)
            LanguageManager.shared.items.remove(at: indexPath.item)
            LanguageManager.shared.favoritesLanguages.append(LanguageManager.shared.languages[indexPath.item])
            LanguageManager.shared.languages.remove(at: indexPath.item)
            languagePicker.reloadAllComponents()
            deleteItem.isUserInteractionEnabled = true
            languagePicker.isUserInteractionEnabled = true
            guard let lastLanguage = LanguageManager.shared.favoritesLanguages.last else { return }
            LanguageManager.shared.chosenLanguage = lastLanguage
            
            TranslationManager.shared.translate(word: wordToTranslate, to: LanguageManager.shared.chosenLanguage)
            
            lastSelectedRow = languagePicker.selectedRow(inComponent: 0)
            bubble.alpha = 0
            bubble.isUserInteractionEnabled = false
            collectionView.reloadData()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.alpha = 1
        if bubble.isUserInteractionEnabled == true {
            languagePicker.selectRow(lastSelectedRow, inComponent: 0, animated: false)
            container.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
            bubble.alpha = 0
            bubble.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
        }
    }
}
extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == photoGallery {
            let height = collectionView.bounds.size.height/3 - 1
            return CGSize(width: height, height: height)
        } else {
            let height = collectionView.bounds.height/2.5
            return CGSize(width: height, height: height)
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == photoGallery {
            return 1.0
        }
        return 10.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == photoGallery {
            return 1.0
        }
        return 10.0
    }
}
// MARK: PickerView
extension PhotosViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach ({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return LanguageManager.shared.favoritesItems.count
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let myView = UIView(frame: CGRect(x: pickerView.frame.origin.x, y: pickerView.frame.origin.y, width: pickerView.frame.size.width, height: pickerView.frame.size.height))
        let imageView = UIImageView(frame: CGRect(x: myView.bounds.midX - 10, y: myView.bounds.midY - 10, width: 20.0, height: 20.0))
        imageView.image = LanguageManager.shared.favoritesItems[row]
        myView.transform = CGAffineTransform(rotationAngle: 90 * (.pi/180))
        myView.addSubview(imageView)
        return myView
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.height
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == LanguageManager.shared.favoritesItems.count-1 {
            if !LanguageManager.shared.items.isEmpty {
                displayLanguagesMenu()
            } else {
                translatedText.text = "No available flags"
            }
        } else {
            lastSelectedRow = row
            LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row]
            TranslationManager.shared.translate(word: wordToTranslate, to: LanguageManager.shared.chosenLanguage)
        }
    }
}
extension PhotosViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if thumbnailsAssets.isEmpty {
            DispatchQueue.main.async {
                self.grabPhotos()
                self.photoGallery.reloadData()
            }
        }
    }
}
