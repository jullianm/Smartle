//
//  RevisionCell.swift
//  Smartle
//
//  Created by jullianm on 04/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

class FavoriteCell: UITableViewCell {
    @IBOutlet weak var photo: UIImageView! {
        didSet {
            photo.contentMode = .scaleAspectFill
            photo.layer.cornerRadius = 30.0
            photo.layer.masksToBounds = true
            photo.layer.borderWidth = 2.0
            photo.layer.borderColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        }
    }
    @IBOutlet weak var associatedWord: UITextField! {
        didSet {
            associatedWord.inputAccessoryView = toolBar
        }
    }
    @IBOutlet weak var languagePicker: UIPickerView! {
        didSet {
            languagePicker.layer.cornerRadius = 30.0
            languagePicker.transform = .init(rotationAngle: -90 * (.pi/180))
            selectedRow = languagePicker.selectedRow(inComponent: 0)
        }
    }
    @IBOutlet weak var container: UIView! {
        didSet {
            container.alpha = 0
            container.isUserInteractionEnabled = false
        }
    }
    @IBOutlet weak var containerBubble: UIImageView!
    @IBOutlet weak var languagesList: UICollectionView! {
        didSet {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.itemSize = .init(width: languagesList.bounds.height/2.5, height: languagesList.bounds.height/2.5)
            flowLayout.minimumLineSpacing = 10.0
            flowLayout.minimumInteritemSpacing = 10.0
            languagesList.collectionViewLayout = flowLayout
            
            let cellNib = UINib(nibName: String(describing: FlagCell.self), bundle: .main)
            languagesList.register(cellNib, forCellWithReuseIdentifier: "flagCell")
        }
    }
    @IBOutlet weak var deleteItem: UIButton!
    
    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done,
                                     target: self,
                                     action: #selector(doneClicked))
        
        return button
    }()
    
    lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        toolBar.setItems([doneButton], animated: false)
        
        return toolBar
    }()
    
    var disposeBag = DisposeBag()
    
    var selectedRow: Int!
    var lastCellPosition: IndexPath!
    var list: FavoritesList!
        
    override func awakeFromNib() {
        super.awakeFromNib()
        languagesList.reloadData()
        languagePicker.reloadAllComponents()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        handleTouches()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
    
    @objc
    private func doneClicked() {
        associatedWord.resignFirstResponder()
    }
}

// MARK: - UI Update
extension FavoriteCell {
    func setupModel(_ model: FavoritesList) {
        list = model
    }
    
    func updateModel(at indexPath: IndexPath) {
        list.addItem(at: indexPath.item)
    }
    
    func updatePickerView() {
        languagePicker.reloadAllComponents()
        languagePicker.isUserInteractionEnabled = true
        languagePicker.selectRow(list.favoritesLanguages.count-1, inComponent: 0, animated: false)
    }
    
    func updateContainer() {
        container.alpha = 0
        container.isUserInteractionEnabled = false
    }
    
    func updateOnEditingDidBegin() {
        languagePicker.isUserInteractionEnabled = false
        languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
        deleteItem.isUserInteractionEnabled = false
    }
    
    func updateOnEditingDidEnd() {
        container.alpha = 0
        associatedWord.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = true
        deleteItem.isUserInteractionEnabled = true
    }
    
    func updateCellPosition(_ indexPath: IndexPath) {
        lastCellPosition = indexPath
    }
    
    func displayLanguagesMenu() {
        container.animateWithAlpha()
        deleteItem.isHidden = true
        container.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = false
        associatedWord.isUserInteractionEnabled = false
    }
}

// MARK: - Touches Event
extension FavoriteCell {
    private func handleTouches() {
        if self.container.isUserInteractionEnabled {
            self.languagePicker.selectRow(self.selectedRow, inComponent: 0, animated: false)
            self.deleteItem.isHidden = false
            self.container.alpha = 0
            self.container.isUserInteractionEnabled = false
            self.languagePicker.isUserInteractionEnabled = true
            self.associatedWord.isUserInteractionEnabled = true
        }
    }
}

// MARK: - Reinit
extension FavoriteCell {
    private func reset() {
        deleteItem.isHidden = false
        associatedWord.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = true
        
        container.alpha = 0
        container.isUserInteractionEnabled = false
        
        languagePicker.dataSource = nil
        languagePicker.delegate = nil
        
        languagesList.dataSource = nil
        languagesList.delegate = nil
        
        disposeBag = .init()
    }
}
