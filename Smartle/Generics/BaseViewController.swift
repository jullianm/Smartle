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

        let index = LanguageManager.shared.favoriteLanguageIndex()
        
        bubbleView.languagesPicker.selectRow(index, inComponent: 0, animated: false)
        selectedRow = index
    }
    
    override func viewDidLayoutSubviews() {
        bubbleView.collectionViewBubble.frame = CGRect(x: bubbleView.bubbleImageView.frame.origin.x,
                                         y: bubbleView.bubbleImageView.frame.origin.y,
                                         width: bubbleView.bubbleImageView.frame.width,
                                         height: bubbleView.bubbleImageView.frame.height)
        
        collectionView.frame = CGRect(x: bubbleView.collectionViewBubble.bounds.midX,
                                      y: bubbleView.collectionViewBubble.bounds.midY,
                                      width: bubbleView.collectionViewBubble.bounds.width/1.5,
                                      height: bubbleView.collectionViewBubble.bounds.height/2)
        
        collectionView.center = CGPoint(x: bubbleView.collectionViewBubble.bounds.midX,
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
    
    private func setupPickerView() {
        bubbleView.onPickerItemSelected = { [weak self] row in
            guard let self = self else { return }
            
            if row == LanguageManager.shared.favoritesItems.count-1 {
                !LanguageManager.shared.items.isEmpty ? self.displayLanguagesMenu(): self.displayEmptyText()
            } else {
                self.selectedRow = row
                
                LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row]
                TranslationManager.shared.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
            }
        }
    }
        
    private func setupCollectionView() {
        LanguageManager.shared.collectionViewDataSource
            .bind(to: collectionView.rx.items(cellIdentifier: "flagCell", cellType: FlagCell.self)) { index, model, cell in
                cell.flag.image = LanguageManager.shared.items[index]
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
                
                TranslationManager.shared.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
                
            }).disposed(by: disposeBag)
    }
    
    private func setupDeleteItem() {
        bubbleView.deleteItem.rx.tap
            .bind(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                if self.bubbleView.languagesPicker.selectedRow(inComponent: 0) !=
                    LanguageManager.shared.favoritesItems.count-1 &&
                    self.bubbleView.languagesPicker.numberOfRows(inComponent: 0) > 2 {
                    
                    let row = self.bubbleView.languagesPicker.selectedRow(inComponent: 0)
                    LanguageManager.shared.deleteFavoriteLanguage()
                    
                    if row >= 1 {
                        self.bubbleView.languagesPicker.selectRow(row-1, inComponent: 0, animated: false)
                        LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[row-1]
                    } else {
                        LanguageManager.shared.chosenLanguage = LanguageManager.shared.favoritesLanguages[0]
                    }
                    
                    TranslationManager.shared.translate(word: self.wordToTranslate.value, to: LanguageManager.shared.chosenLanguage)
                    
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
            .bind(to: MLManager.shared.input)
            .disposed(by: disposeBag)
    }
    
    private func setupMLOutput() {
        MLManager.shared.output
            .distinctUntilChanged()
            .do(onNext: { [weak self] in self?.wordToTranslate.accept($0) })
            .bind(onNext: { str in
                TranslationManager.shared.translate(word: str, to: LanguageManager.shared.chosenLanguage)
            }).disposed(by: disposeBag)
    }
    
    func setupTranslation() {
        TranslationManager.shared.translation
            .do(onNext: { [weak self] _ in
                self?.onTranslationDisplayed?()
            })
            .drive((bubbleView.translatedText.rx.text))
            .disposed(by: disposeBag)
    }
}
