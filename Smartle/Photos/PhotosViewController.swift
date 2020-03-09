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
import RxCocoa
import RxDataSources
import RxSwift

class PhotosViewController: BaseViewController, UIApplicationDelegate {
    // MARK: - Outlets
    @IBOutlet weak var photoGallery: UICollectionView!
    @IBOutlet weak var container: UIView! {
        didSet {
            container.addSubview(bubbleView)
            bubbleView.frame = container.bounds
        }
    }
    @IBOutlet weak var favorites: UIImageView!
    @IBOutlet weak var previewImage: UIImageView! 
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet var separatorLineConstraints: [NSLayoutConstraint]! {
        didSet {
            separatorLineConstraints.forEach { $0.constant = 0.2 }
        }
    }
    
    // MARK: - Photo Gallery Properties
    private lazy var cachingImageManager = PHCachingImageManager()
    private lazy var galleryAssets = BehaviorRelay<[PHAsset]>(value: [])
    private lazy var thumbnailsAssets = [PHAsset]()
    private lazy var options: PHImageRequestOptions = {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .exact
        
        return requestOptions
    }()
    
    var lastSelectedPhotoIndex: Int = 0
    var coreDataManager = CoreDataManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        grabPhotos()
        setupFavorites()
        setupGalleryCollectionView()
        setupTranslatedText()
        setupSlider()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loader.isHidden = true
        container.isHidden = true
        
        predictOnAppeared()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        container.isHidden = false
        container.transform = .init(scaleX: 0.0, y: 0.0)
    }
        
    private func setupGalleryCollectionView() {
        PHPhotoLibrary.shared().register(self)
        
        galleryAssets
            .bind(to: photoGallery.rx.items(cellIdentifier: "photosCell", cellType: PhotosCell.self)) { [weak self] index, model, cell in
                guard let self = self else { return }
                
                self.cachingImageManager.requestImage(for: self.thumbnailsAssets[index], targetSize: .init(width: 300, height: 300), contentMode: .aspectFill, options: self.options) { photo, info in
                    cell.photo.image = photo ?? .init()
                }
                
                cell.alphaView.alpha = (index == self.lastSelectedPhotoIndex) ? 0.5: 0.0
        }.disposed(by: disposeBag)
        
        photoGallery.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self, indexPath.item != self.lastSelectedPhotoIndex else { return }
                
                let cell = self.photoGallery.cellForItem(at: indexPath) as? PhotosCell
                let firstCell = self.photoGallery.cellForItem(at: [0, 0]) as? PhotosCell
                firstCell?.alphaView.alpha = 0.0
                cell?.alphaView.alpha = 0.5
                
                self.updateLoaderStatus(shouldStop: false)
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .none
                
                PHImageManager.default().requestImage(for: self.galleryAssets.value[indexPath.item], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, info in
                    guard
                        let result = result,
                        let processableImage = result.cgImage,
                        let pixelBuffer = ImageManager.shared.pixelBuffer(forImage: processableImage) else { return }
                    
                    self.previewImage.image = result.resized(frame: self.previewImage.frame)
                    self.container.transform = CGAffineTransform(scaleX: 0, y: 0)
                    self.favorites.image = UIImage(named: "smartle_favoritesEmpty")
                    self.lastSelectedPhotoIndex = indexPath.item
                    self.updateLoaderStatus(shouldStop: true)
                    self.didCaptureOutput.accept(pixelBuffer)
                }
            }).disposed(by: disposeBag)
        
        photoGallery.rx.itemDeselected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                let cell = self.photoGallery.cellForItem(at: indexPath) as? PhotosCell
                cell?.alphaView.alpha = 0.0
                
            }).disposed(by: disposeBag)
    }

    private func setupTranslatedText() {
        onTranslationDisplayed = { [weak self] in
            self?.favorites.image = UIImage(named:"smartle_favoritesEmpty")
            self?.container.animateWithDamping()
        }
    }
    
    private func grabPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary
        
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos = [PHAsset]()
        
        assets.enumerateObjects { asset, _, _ in
            photos.append(asset)
            self.thumbnailsAssets.append(asset)
        }
        
        galleryAssets.accept(photos)
        cachingImageManager.startCachingImages(for: thumbnailsAssets,
                                               targetSize: CGSize(width: 300, height: 300),
                                               contentMode: .aspectFill, options: options)

        PHImageManager.default().requestImage(for: galleryAssets.value[IndexPath(item: lastSelectedPhotoIndex, section: 0).item], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, _ in

            guard let result = result else { return }
            self.previewImage.image = result.resized(frame: self.previewImage.frame)
        }
    }
    
    func setupFavorites() {
        favorites.rx.tapGesture()
            .subscribe(onNext: { _ in
                self.addToFavorites()
            }).disposed(by: disposeBag)
    }
    
    func setupSlider() {
        confidenceSlider.rx.value
            .bind(to: userConfidence)
            .disposed(by: disposeBag)
    }
    
    private func addToFavorites() {
        if favorites.image == UIImage(named: "smartle_favoritesEmpty") {
            favorites.image = UIImage(named: "smartle_favorites")?.withRenderingMode(.alwaysTemplate)
            favorites.tintColor = .white
            
            cachingImageManager.requestImage(for: self.thumbnailsAssets[lastSelectedPhotoIndex], targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { [weak self] result, info in
                guard
                    let result = result,
                    let data = UIImagePNGRepresentation(result),
                    let translation = self?.bubbleView.translatedText.text  else {
                        return
                }
                self?.coreDataManager.saveRevision(data: data, translation: translation)
            }
        }
    }
    
    private func predictOnAppeared() {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            return
        }
        
        MLManager.shared.setEmpty()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        
        PHImageManager.default().requestImage(for: galleryAssets.value[IndexPath(item: lastSelectedPhotoIndex, section: 0).item], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { result, info in
            
            guard
                let result = result,
                let processableImage = result.cgImage,
                let pixelBuffer = ImageManager.shared.pixelBuffer(forImage: processableImage) else {
                    return
            }
            
            self.previewImage.image = result.resized(frame: self.previewImage.frame)
            self.didCaptureOutput.accept(pixelBuffer)
        }
    }
    
    private func updateLoaderStatus(shouldStop: Bool) {
        shouldStop ? loader.stopAnimating(): loader.startAnimating()
        loader.isHidden = shouldStop
    }
}

extension PhotosViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard thumbnailsAssets.isEmpty else {
            return
        }
        
        DispatchQueue.main.async {
            self.grabPhotos()
            self.photoGallery.reloadData()
        }
    }
}
