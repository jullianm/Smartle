//
//  RevisionCell.swift
//  Smartle
//
//  Created by jullianm on 04/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxDataSources
import RxCocoa
import RxSwift
import UIKit

protocol TranslationDelegate: AnyObject {
    func translate(to chosenLanguage: String, at indexPath: IndexPath)
    func replace(userWord: String, to chosenLanguage: String, at indexPath: IndexPath)
}
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
            associatedWord.delegate = self
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
    
    private var currentCellPosition: IndexPath? {
        return (superview as? UITableView)?.indexPath(for: self)
        
    }
    lazy var tableView: UITableView? = {
        return superview as? UITableView
        
    }()
    
    lazy var toolBar: UIToolbar = {
        let toolBar = UIToolbar()
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done,
                                         target: self,
                                         action: #selector(doneClicked))
        toolBar.setItems([doneButton], animated: false)
        
        return toolBar
    }()
    
    // delegate
    weak var delegate: TranslationDelegate?
    
    // rx
    var disposeBag = DisposeBag()
    
    // tableview
    var selectedRow: Int!
    var lastCellPosition: IndexPath!
    var uppestCellPosition: IndexPath!
    var isBeingEdited = false
    
    // models
    lazy var favoritesItems = [UIImage]()
    lazy var items = [UIImage]()
    lazy var favoritesLanguages = [String]()
    lazy var languages = [String]()
    lazy var chosenLanguage = String()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        guard container.alpha == 1 else {
            return
        }
        
        deleteItem.isHidden = false
        container.alpha = 0
        container.isUserInteractionEnabled = false
        languagePicker.isUserInteractionEnabled = true
        associatedWord.isUserInteractionEnabled = true
        disposeBag = .init()
    }
    
    func setupModel(_ model: FavoritesList) {
        setupModel(model: model)
    }
    
    func setupBindings() {
        setupPickerView()
        setupCollectionView()
        setupDeleteItem()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if container.isUserInteractionEnabled {
            languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
            deleteItem.isHidden = false
            container.alpha = 0
            container.isUserInteractionEnabled = false
            languagePicker.isUserInteractionEnabled = true
            associatedWord.isUserInteractionEnabled = true
        }
    }
    @objc private func doneClicked() {
        associatedWord.resignFirstResponder()
    }
    private func displayLanguagesMenu() {
        container.animateWithAlpha()
        deleteItem.isHidden = true
        container.isUserInteractionEnabled = true
        languagePicker.isUserInteractionEnabled = false
        associatedWord.isUserInteractionEnabled = false
    }
}

// MARK: - Models
extension FavoriteCell {
    private func setupModel(model: FavoritesList) {
        favoritesItems = model.favoritesItems
        items = model.items
        favoritesLanguages = model.favoritesLanguages
        languages = model.languages
        chosenLanguage = model.selectedLanguage
        languagePicker.reloadAllComponents()
        languagesList.reloadData()
        photo.image = model.photo
        associatedWord.text = model.currentTranslation
        
        let index = favoritesLanguages.enumerated().first(where: { $0.element == model.selectedLanguage })?.offset ?? 0
        languagePicker.selectRow(index, inComponent: 0, animated: false)
    }
}
// MARK: - CollectionView
extension FavoriteCell {
    private func setupCollectionView() {
        Observable.just(items)
            .bind(to: languagesList.rx.items(cellIdentifier: "flagCell", cellType: FlagCell.self)) { [weak self] index, model, cell in
                guard let self = self else { return }
                
                cell.flag.image = self.items[index]
                
            }.disposed(by: disposeBag)
        
        languagesList.rx.itemSelected
            .bind(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                self.favoritesItems.insert(self.items[indexPath.item], at: self.favoritesItems.count-1)
                self.items.remove(at: indexPath.item)
                self.favoritesLanguages.append(self.languages[indexPath.item])
                self.languages.remove(at: indexPath.item)
                guard let lastLanguage = self.favoritesLanguages.last else { return }
                guard let myIndex = self.currentCellPosition else { return }
                self.deleteItem.isHidden = false
                self.container.alpha = 0
                self.container.isUserInteractionEnabled = false
                self.languagesList.reloadData()
                self.languagePicker.reloadAllComponents()
                self.languagePicker.isUserInteractionEnabled = true
                self.associatedWord.isUserInteractionEnabled = true
                self.chosenLanguage = lastLanguage
                self.selectedRow = self.languagePicker.selectedRow(inComponent: 0)
                self.delegate?.translate(to: lastLanguage, at: myIndex)
                self.languagePicker.selectRow(self.favoritesLanguages.count-1, inComponent: 0, animated: false)
            }).disposed(by: disposeBag)
    }

}

// MARK: - Item deletion
extension FavoriteCell {
    private func setupDeleteItem() {
        deleteItem.rx.tap
            .bind(onNext: { [weak self] _ in
                guard let self = self,
                    self.languagePicker.selectedRow(inComponent: 0) != self.favoritesItems.count-1
                    && self.languagePicker.numberOfRows(inComponent: 0) > 2 else { return }
                
                let row = self.languagePicker.selectedRow(inComponent: 0)
                
                for (index, language) in self.favoritesLanguages.enumerated() where language == self.chosenLanguage {
                    self.items.append(self.favoritesItems[index])
                    self.favoritesItems.remove(at: index)
                    self.languages.append(self.favoritesLanguages[index])
                    self.favoritesLanguages.remove(at: index)
                }
                
                if row >= 1 {
                    self.languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                    self.chosenLanguage = self.favoritesLanguages[row-1]
                } else {
                    self.chosenLanguage = self.favoritesLanguages[0]
                }
                
                self.languagePicker.reloadAllComponents()
                self.languagesList.reloadData()
                self.selectedRow = self.languagePicker.selectedRow(inComponent: 0)
                
                guard let indexPath = self.currentCellPosition else { return }
                self.delegate?.translate(to: self.chosenLanguage, at: indexPath)
                
            }).disposed(by: disposeBag)
    }
}

// MARK: - PickerView
extension FavoriteCell {
    private func setupPickerView() {
        Observable.just(favoritesItems)
            .bind(to: languagePicker.rx.items) { [weak self] (row, element, view) in
                guard let self = self else { return .init() }
                
                self.languagePicker.subviews.forEach { $0.isHidden = $0.frame.height < 1.0 }
                
                let flagView = UIView(frame: CGRect(x: self.languagePicker.frame.origin.x,
                                                    y: self.languagePicker.frame.origin.y,
                                                    width: self.languagePicker.frame.size.width,
                                                    height: self.languagePicker.frame.size.height))
                
                let imageView = UIImageView(frame: CGRect(x: flagView.bounds.midX, y: flagView.bounds.midY, width: 20.0, height: 20.0))
                imageView.center = CGPoint(x: flagView.bounds.midX, y: flagView.bounds.midY)
                imageView.image = self.favoritesItems[row]
                
                flagView.transform = .init(rotationAngle: 90 * (.pi/180))
                flagView.addSubview(imageView)
                
                return flagView
            }.disposed(by: disposeBag)
        
        languagePicker.rx.itemSelected
            .bind(onNext: { [weak self] row, _ in
                guard let self = self else { return }
                
                if row == self.favoritesItems.count-1 {
                    if !self.items.isEmpty {
                        self.displayLanguagesMenu()
                    }
                } else {
                    self.selectedRow = row
                    self.chosenLanguage = self.favoritesLanguages[row]
                    guard let indexPath = self.currentCellPosition else {
                        return
                    }
                    self.delegate?.translate(to: self.favoritesLanguages[row], at: indexPath)
                }
            }).disposed(by: disposeBag)
    }
}
extension FavoriteCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        languagePicker.isUserInteractionEnabled = false
        languagePicker.selectRow(selectedRow, inComponent: 0, animated: false)
        deleteItem.isUserInteractionEnabled = false
        isBeingEdited = true
        lastCellPosition = currentCellIndexPath ?? lastCellPosition
        
        guard
            let firstCell = tableView?.visibleCells.first,
            let firstCellIndexPath = tableView?.indexPath(for: firstCell) else { return }
        
        uppestCellPosition = firstCellIndexPath
        
        tableView?.moveRow(at: currentCellIndexPath, to: uppestCellPosition)
        tableView?.scrollToRow(at: uppestCellPosition, at: .none, animated: false)
        
        tableView?.visibleCells.forEach { cell in
            let visibleCellIndexPath = tableView?.indexPath(for: cell)
            if visibleCellIndexPath != uppestCellPosition {
                cell.alpha = 0.3
                cell.isUserInteractionEnabled = false
            }
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        isBeingEdited = false
        tableView?.moveRow(at: uppestCellPosition, to: lastCellPosition)
        tableView?.scrollToRow(at: lastCellPosition, at: .none, animated: false)
        tableView?.visibleCells.forEach { cell in
            cell.isUserInteractionEnabled = true
            cell.alpha = 1
        }
        
        if languagePicker.selectedRow(inComponent: 0) != favoritesItems.count-1 {
            container.alpha = 0
            associatedWord.isUserInteractionEnabled = true
            languagePicker.isUserInteractionEnabled = true
            deleteItem.isUserInteractionEnabled = true
            if let word = associatedWord.text {
                delegate?.replace(userWord: word,
                                  to: favoritesLanguages[languagePicker.selectedRow(inComponent: 0)],
                                  at: lastCellPosition)
            }
        }
    }
}
