//
//  BaseViewController.swift
//  Smartle
//
//  Created by Jullianm on 07/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import AVFoundation
import RxCocoa
import RxDataSources
import RxSwift
import UIKit

class BaseViewController: UIViewController {
    lazy var bubbleView: Bubble = {
        let bubble = Bundle.main.loadNibNamed(String(describing: Bubble.self),
                                              owner: self,
                                              options: nil)?.first! as! Bubble
        
        bubble.collectionViewBubble.addSubview(collectionView)
        
        return bubble
    }()
    
    let collectionView: UICollectionView = {
        let layout = BaseCollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .init(), collectionViewLayout: layout)
        collectionView.backgroundColor = nil
        collectionView.showsVerticalScrollIndicator = false
        
        let cellNib = UINib(nibName: String(describing: FlagCell.self), bundle: .main)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "flagCell")
        
        return collectionView
    }()
    
    var didCaptureOutput = PublishRelay<CVPixelBuffer>()
    var userConfidence = BehaviorRelay<Float>(value: 0.0)
    var selectedRow: Int!
    var disposeBag = DisposeBag()
    var wordToTranslate = BehaviorRelay<String>(value: .init())
    var onTranslationDisplayed: (() -> Void)?
    
    // Managers
    var coreDataManager = CoreDataManager.shared
    var translationManager = TranslationManager.shared
    var languageManager = LanguageManager.shared
    var machineLearningManager = MLManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
        
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bubbleView.collectionViewBubble.alpha = 0
        bubbleView.bubbleImageView.isUserInteractionEnabled = false
        bubbleView.updatePicker(isUserInteractionEnabled: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()

        let index = languageManager.favoriteLanguageIndex()
        
        bubbleView.languagesPicker.selectRow(index, inComponent: 0, animated: false)
        selectedRow = index
    }
    
    override func viewDidLayoutSubviews() {
        bubbleView.collectionViewBubble.frame = .init(x: bubbleView.bubbleImageView.frame.origin.x,
                                                      y: bubbleView.bubbleImageView.frame.origin.y,
                                                      width: bubbleView.bubbleImageView.frame.width,
                                                      height: bubbleView.bubbleImageView.frame.height)
        
        collectionView.frame = .init(x: bubbleView.collectionViewBubble.bounds.midX,
                                     y: bubbleView.collectionViewBubble.bounds.midY,
                                     width: bubbleView.collectionViewBubble.bounds.width/1.5,
                                     height: bubbleView.collectionViewBubble.bounds.height/2)
        
        collectionView.center = .init(x: bubbleView.collectionViewBubble.bounds.midX,
                                      y: bubbleView.collectionViewBubble.bounds.midY)
    }
    
    private func setupBindings() {
        setupCollectionView()
        setupPickerView()
        setupMLInput()
        setupMLOutput()
        setupTranslation()
        setupDeleteItem()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bubbleView.collectionViewBubble.isUserInteractionEnabled == true {
            bubbleView.languagesPicker.selectRow(selectedRow, inComponent: 0, animated: false)
            bubbleView.collectionViewBubble.alpha = 0
            bubbleView.collectionViewBubble.isUserInteractionEnabled = false
            bubbleView.languagesPicker.isUserInteractionEnabled = true
        }
    }
}

extension BaseViewController {
    private func setupPickerView() {
        bubbleView.onPickerItemSelected = { [weak self] row in
            guard let self = self else { return }
            
            if row == self.languageManager.favoritesItems.count-1 {
                !self.languageManager.items.isEmpty ? self.displayLanguagesMenu(): self.displayEmptyText()
            } else {
                self.selectedRow = row
                
                self.languageManager.chosenLanguage = self.languageManager.favoritesLanguages[row]
                self.translationManager.translate(word: self.wordToTranslate.value,
                                                  to: self.languageManager.chosenLanguage)
            }
        }
    }
        
    private func setupCollectionView() {
        languageManager.collectionViewDataSource
            .bind(to: collectionView.rx.items(cellIdentifier: "flagCell", cellType: FlagCell.self)) { [weak self] index, model, cell in
                guard let self = self else { return }
                
                cell.flag.image = self.languageManager.items[index]
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                LanguageManager.shared.updateFavoriteLanguage(atIndex: indexPath.item)
                
                self.bubbleView.updatePicker(isUserInteractionEnabled: true)
                self.bubbleView.updateCollectionViewBubble(isUserInteractionEnabled: false)
                self.bubbleView.deleteItem.isUserInteractionEnabled = true
                self.selectedRow = self.bubbleView.languagesPicker.selectedRow(inComponent: 0)
                self.collectionView.reloadData()
                
                self.translationManager.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
                
            }).disposed(by: disposeBag)
    }
    
    private func setupDeleteItem() {
        bubbleView.deleteItem.rx.tap
            .bind(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                if self.bubbleView.languagesPicker.selectedRow(inComponent: 0) !=
                    self.languageManager.favoritesItems.count-1 &&
                    self.bubbleView.languagesPicker.numberOfRows(inComponent: 0) > 2 {
                    
                    let row = self.bubbleView.languagesPicker.selectedRow(inComponent: 0)
                    LanguageManager.shared.deleteFavoriteLanguage()
                    
                    if row >= 1 {
                        self.bubbleView.languagesPicker.selectRow(row-1, inComponent: 0, animated: false)
                        LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row-1]
                    } else {
                        LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[0]
                    }
                    
                    self.translationManager.translate(word: self.wordToTranslate.value, to: self.languageManager.chosenLanguage)
                    
                    self.bubbleView.languagesPicker.reloadAllComponents()
                    self.collectionView.reloadData()
                    self.selectedRow = self.bubbleView.languagesPicker.selectedRow(inComponent: 0)
                }
            }).disposed(by: disposeBag)
    }

    private func displayLanguagesMenu() {
        bubbleView.collectionViewBubble.isUserInteractionEnabled = true
        bubbleView.collectionViewBubble.animateWithAlpha()
        bubbleView.languagesPicker.isUserInteractionEnabled = false
    }
    
    private func displayEmptyText() {
        bubbleView.translatedText.rx.text.onNext(.init())
    }
}

// MARK: - ML Bindings
extension BaseViewController {
    private func setupMLInput() {
        didCaptureOutput
            .map { (self.userConfidence.value, $0) }
            .bind(to: machineLearningManager.input)
            .disposed(by: disposeBag)
    }
    
    private func setupMLOutput() {
        machineLearningManager.output
            .do(onNext: { [weak self] in self?.wordToTranslate.accept($0) })
            .bind(onNext: { [weak self] str in
                guard let self = self else { return }
                self.translationManager.translate(word: str, to: self.languageManager.chosenLanguage)
            }).disposed(by: disposeBag)
    }
    
    func setupTranslation() {
        translationManager.translation
            .do(onNext: { [weak self] _ in
                self?.onTranslationDisplayed?()
            })
            .drive((bubbleView.translatedText.rx.text))
            .disposed(by: disposeBag)
    }
}
