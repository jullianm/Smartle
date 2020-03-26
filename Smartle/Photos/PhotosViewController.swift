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
    @IBOutlet weak var photoGallery: UICollectionView! {
        didSet {
            photoGallery.dataSource = self
            photoGallery.delegate = self
        }
    }
    @IBOutlet weak var container: UIView! {
        didSet {
            container.addSubview(bubbleView)
            bubbleView.frame = container.bounds
            container.isHidden = true
        }
    }
    @IBOutlet weak var favorites: UIImageView!
    @IBOutlet weak var previewImage: UIImageView! 
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var mainLoader: UIActivityIndicatorView!
    @IBOutlet weak var waitingLoaderView: UIView!
    @IBOutlet weak var temporaryLoader: UIActivityIndicatorView!
    @IBOutlet weak var confidenceSlider: UISlider!
    @IBOutlet var separatorLineConstraints: [NSLayoutConstraint]! {
        didSet {
            separatorLineConstraints.forEach { $0.constant = 0.2 }
        }
    }
    
    // MARK: - Photos Properties
    private lazy var imageManager = PHCachingImageManager()
    private lazy var options: PHImageRequestOptions = {
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .none
        
        return requestOptions
    }()
    
    private var lastSelectedPhotoIndex: Int = 0
    private var didRetrieveRequestedImage = PublishRelay<UIImage>()
    private var thumbnailSize: CGSize = .init(width: 300, height: 300)
    private var previousPreheatRect = CGRect.zero
    private var fetchResult: PHFetchResult<PHAsset>? {
        didSet {
            photoGallery.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetCachedAssets()
        handleAuthorization()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }

    private func handleAuthorization() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        Observable.just(status)
            .subscribe(onNext: { status in
                DispatchQueue.main.async {
                    switch status {
                    case .notDetermined:
                        self.requestAuthorization()
                    case .authorized:
                        self.setupBindings()
                    default:
                        break
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.setupBindings()
                default:
                    break
                }
            }
        }
    }
    
    private func setupBindings() {
        setupRequestedImage()
        setupPhotos()
        setupFavorites()
        setupGalleryCollectionView()
        setupTranslatedText()
        setupSlider()
        setupViewAppearance()
    }
        
    private func setupPhotos() {
        PHPhotoLibrary.shared().register(self)
        
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotosOptions.includeAssetSourceTypes = .typeUserLibrary
        
        fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        requestImage(asset: fetchResult!.object(at: 0))
    }
    
    private func requestImage(asset: PHAsset) {
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options) { image, _ in
            self.container.isHidden = false
            self.container.transform = .init(scaleX: 0.0, y: 0.0)
            self.didRetrieveRequestedImage.accept(image ?? .init())
        }
    }
    
    private func setupRequestedImage() {
        didRetrieveRequestedImage
            .do(onNext: { _ in
                self.waitingLoaderView.animateWithAlpha(duration: 0.2, alpha: 0.0)
            })
            .bind(onNext: { image in
                guard
                    let processableImage = image.cgImage,
                    let pixelBuffer = ImageManager.shared.toPixelBuffer(forImage: processableImage)
                    else { return }
                
                self.updateMainLoader(animated: false)
                self.updateTemporaryLoader(animated: false)
                self.previewImage.image = image.resized(frame: self.previewImage.frame)
                self.didCaptureOutput.accept(pixelBuffer)
            }).disposed(by: disposeBag)
    }
        
    private func setupGalleryCollectionView() {
        photoGallery.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self, indexPath.item != self.lastSelectedPhotoIndex else { return }
                
                let cell = self.photoGallery.cellForItem(at: indexPath) as? PhotosCell
                let firstCell = self.photoGallery.cellForItem(at: [0, 0]) as? PhotosCell
                let asset = self.fetchResult?.object(at: indexPath.item) ?? .init()
                
                firstCell?.alphaView.alpha = 0.0
                cell?.alphaView.alpha = 0.5
                
                self.updateMainLoader(animated: true)
                self.lastSelectedPhotoIndex = indexPath.item
                
                self.imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: self.options, resultHandler: { image, _ in
                    self.didRetrieveRequestedImage.accept(image ?? .init())
                })
                
            }).disposed(by: disposeBag)
        
        photoGallery.rx.itemDeselected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                let cell = self.photoGallery.cellForItem(at: indexPath) as? PhotosCell
                cell?.alphaView.alpha = 0.0
                
            }).disposed(by: disposeBag)
    }
    
    private func setupViewAppearance() {
        rx.sentMessage(#selector(viewWillDisappear))
            .bind(onNext:  { [weak self] _ in
                self?.container.isHidden = true
                self?.machineLearningManager.reset()
            }).disposed(by: disposeBag)
        
        rx.sentMessage(#selector(viewWillAppear))
            .map { _ in () }
            .subscribe(onNext:  { [weak self] _ in
                guard let self = self, let asset = self.fetchResult?.object(at: self.lastSelectedPhotoIndex) else {
                    return
                }
                
                self.requestImage(asset: asset)
            }).disposed(by: disposeBag)
    }

    private func setupTranslatedText() {
        onTranslationDisplayed = { [weak self] in
            self?.favorites.image = UIImage(named:"smartle_favoritesEmpty")
            self?.container.animateWithDamping()
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
            
            let asset = fetchResult!.object(at: lastSelectedPhotoIndex)
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFill, options: options) { [weak self] result, info in
                guard
                    let result = result,
                    let data = UIImagePNGRepresentation(result),
                    let translation = self?.bubbleView.translatedText.text  else {
                        return
                }
                self?.coreDataManager.saveFavorite(data: data, translation: translation)
            }
        }
    }
    
    private func updateTemporaryLoader(animated: Bool) {
        animated ? temporaryLoader.startAnimating(): temporaryLoader.stopAnimating()
        temporaryLoader.isHidden = !animated
    }
    
    private func updateMainLoader(animated: Bool) {
        animated ? mainLoader.startAnimating(): mainLoader.stopAnimating()
        mainLoader.isHidden = !animated
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
}

extension PhotosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fetchResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let asset = fetchResult?.object(at: indexPath.item),
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell",
                                                          for: indexPath) as? PhotosCell
            else { fatalError("Unexpected cell in collection view") }
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImage(for: asset, targetSize: .init(width: 300, height: 300), contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image?.resized(frame: cell.frame)
            }
            
            cell.alphaView.alpha = (indexPath.item == self.lastSelectedPhotoIndex) ? 0.5: 0.0
        })
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
}

extension PhotosViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let result = fetchResult, let changes = changeInstance.changeDetails(for: result)
            else { return }
        
        // Change notifications may originate from a background queue.
        // As such, re-dispatch execution to the main queue before acting
        // on the change, so you can update the UI.
        DispatchQueue.main.sync {
            // Hang on to the new fetch result.
            fetchResult = changes.fetchResultAfterChanges
            // If we have incremental changes, animate them in the collection view.
            if changes.hasIncrementalChanges {
                guard let collectionView = self.photoGallery else { fatalError() }
                // Handle removals, insertions, and moves in a batch update.
                collectionView.performBatchUpdates({
                    if let removed = changes.removedIndexes, !removed.isEmpty {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, !inserted.isEmpty {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    }
                })
                // We are reloading items after the batch update since `PHFetchResultChangeDetails.changedIndexes` refers to
                // items in the *after* state and not the *before* state as expected by `performBatchUpdates(_:completion:)`.
                if let changed = changes.changedIndexes, !changed.isEmpty {
                    collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                }
            } else {
                // Reload the collection view if incremental changes are not available.
                collectionView.reloadData()
            }
            resetCachedAssets()
        }
    }
}

// MARK: - Asset Caching
extension PhotosViewController {
    private func resetCachedAssets() {
        imageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    /// - Tag: UpdateAssets
    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The window you prepare ahead of time is twice the height of the visible rect.
        let visibleRect = CGRect(origin: photoGallery.contentOffset, size: photoGallery.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start and stop caching.
        let (addedRects, removedRects) = previousPreheatRect.differencesWithNewRect(preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in photoGallery.indexPathsForElements(in: rect) }
            .compactMap { indexPath in fetchResult?.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in photoGallery.indexPathsForElements(in: rect) }
            .compactMap { indexPath in fetchResult?.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets,
                                        targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        imageManager.stopCachingImages(for: removedAssets,
                                       targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        // Store the computed rectangle for future comparison.
        previousPreheatRect = preheatRect
    }
}
