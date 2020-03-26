//
//  FavoritesViewController.swift
//  Smartle
//
//  Created by jullianm on 20/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import CoreData

class FavoritesViewController: UIViewController {
    @IBOutlet weak var favoritesList: UITableView! {
        didSet {
            favoritesList.rowHeight = 93.0
            favoritesList.tableFooterView = UIView()
        }
    }
    @IBOutlet weak var dataLoading: UIActivityIndicatorView!
    @IBOutlet weak var titleView: UIView! {
        didSet {
            titleView.layer.addSublayer(titleBottomLine)
        }
    }
    @IBOutlet weak var separatorLineConstraint: NSLayoutConstraint! {
        didSet {
            separatorLineConstraint.constant = 0.2
        }
    }
    private lazy var titleBottomLine: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        layer.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        
        return layer
    }()
    
    private let disposeBag = DisposeBag()
    private lazy var favoritesRelay = BehaviorRelay<[FavoritesList]>(value: coreDataManager.fetchFavorites())
    private var coreDataManager = CoreDataManager.shared
    
    private var cached: (cell: FavoriteCell?, indexPath: IndexPath?)

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
        setupTableView()
        setupTranslation()
    }
    
    override func viewDidLayoutSubviews() {
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        favoritesRelay.accept(coreDataManager.fetchFavorites())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cached.cell = nil
        cached.indexPath = nil
    }
}

// MARK: - UITableView Binding
extension FavoritesViewController {
    private func setupTableView() {
        favoritesRelay
            .delay(.milliseconds(200), scheduler: MainScheduler.instance)
            .skip(1)
            .do(onNext: { [weak self] favorites in
                favorites.isEmpty ? self?.presentAlertController(): ()
                self?.view.isUserInteractionEnabled = true
                self?.dataLoading.stopAnimating()
            })
            .bind(to: favoritesList.rx.items(cellIdentifier: "favoriteCell", cellType: FavoriteCell.self)) { [weak self] index, model, cell in
                self?.setupModel(model, on: cell)
                self?.setupCollectionView(on: cell)
                self?.setupTextField(on: cell)
                self?.setupPickerView(on: cell)
                self?.deleteLanguage(on: cell)
            }.disposed(by: disposeBag)
        
        setupDeleteFavorite()
    }
}

// MARK: - UITableViewCell Bindings
extension FavoritesViewController {
    private func setupModel(_ model: FavoritesList, on cell: FavoriteCell) {
        cell.list = model
        cell.photo.image = model.photo
        cell.associatedWord.text = model.currentTranslation
    }
    
    private func deleteLanguage(on cell: FavoriteCell) {
        cell.deleteItem.rx.tap.subscribe(onNext: { [weak self] _ in
            guard
                cell.languagePicker.selectedRow(inComponent: 0) !=
                    cell.list.favoritesItems.count-1 &&
                        cell.languagePicker.numberOfRows(inComponent: 0) > 2 else { return }
            
            let row = cell.languagePicker.selectedRow(inComponent: 0)
            cell.list.deleteItem(at: cell.list.selectedLanguageIndex)
            
            if row >= 1 {
                cell.languagePicker.selectRow(row-1, inComponent: 0, animated: false)
                cell.list.selectedLanguage = cell.list.favoritesLanguages[row-1]
            } else {
                cell.list.selectedLanguage = cell.list.favoritesLanguages[0]
            }
            cell.languagePicker.reloadAllComponents()
            cell.languagesList.reloadData()
            cell.selectedRow = cell.languagePicker.selectedRow(inComponent: 0)
            
            self?.cached = (cell, self?.favoritesList.indexPath(for: cell))
            TranslationManager.shared.translate(word: cell.associatedWord.text!,
                                                to: cell.list.selectedLanguage)
            
        }).disposed(by: disposeBag)
    }
    
    private func setupCollectionView(on cell: FavoriteCell) {
        cell.list.itemsRelay
            .bind(to: cell.languagesList.rx.items(cellIdentifier: "flagCell", cellType: FlagCell.self)) { index, model, cell in
                cell.flag.image = model
            }.disposed(by: disposeBag)
        
        cell.languagesList.rx.itemSelected
            .bind(onNext: { [weak self] indexPath in
                
                cell.updateModel(at: indexPath)
                cell.updateContainer()
                cell.updatePickerView()
                
                cell.deleteItem.isHidden = false
                cell.languagesList.reloadData()
                cell.associatedWord.isUserInteractionEnabled = true
                cell.list.selectedLanguage = cell.list.favoritesLanguages.last ?? "FR"
                cell.selectedRow = cell.languagePicker.selectedRow(inComponent: 0)

                self?.cached = (cell, self?.favoritesList.indexPath(for: cell))
                TranslationManager.shared.translate(word: cell.associatedWord.text ?? .init(),
                                                    to: cell.list.selectedLanguage)
                
            }).disposed(by: cell.disposeBag)
    }
    
    private func setupTranslation() {
        TranslationManager.shared.translation
            .drive(onNext: { [weak self] translation in
                guard let self = self, let cell = self.cached.cell, let indexPath = self.cached.indexPath else {
                    return
                }
                
                self.cached.cell?.associatedWord.rx.text.onNext(translation)
                self.coreDataManager.updateFavorites(with: translation, and: cell.list, for: indexPath.item)
                self.favoritesRelay.accept(self.coreDataManager.fetchFavorites())
                self.view.isUserInteractionEnabled = false
                
            }).disposed(by: disposeBag)
    }
    private func setupTextField(on cell: FavoriteCell) {
        cell.associatedWord.rx.controlEvent(.editingDidBegin)
            .bind(onNext: { [weak self] _ in
                guard
                    let self = self,
                    let currentCellIndexPath = self.favoritesList.indexPath(for: cell),
                    let firstCell = self.favoritesList.visibleCells.first,
                    let firstCellIndexPath = self.favoritesList.indexPath(for: firstCell) else {
                        return
                }
                
                cell.updateOnEditingDidBegin()
                cell.updateCellPosition(currentCellIndexPath)
                
                self.favoritesList.moveRow(at: currentCellIndexPath, to: firstCellIndexPath)
                self.favoritesList.scrollToRow(at: firstCellIndexPath, at: .none, animated: false)
                self.favoritesList.visibleCells
                    .compactMap { $0 as? FavoriteCell }
                    .filter { !$0.associatedWord.isEditing }
                    .forEach { $0.alpha = 0.3; $0.isUserInteractionEnabled = false }
                
            }).disposed(by: cell.disposeBag)
        
        cell.associatedWord.rx.controlEvent(.editingDidEnd)
            .bind(onNext: { [weak self] _ in
                guard
                    let self = self,
                    let currentCellIndexPath = self.favoritesList.indexPath(for: cell) else { return }
                
                self.favoritesList.moveRow(at: currentCellIndexPath, to: cell.lastCellPosition)
                self.favoritesList.scrollToRow(at: cell.lastCellPosition, at: .none, animated: false)
                self.favoritesList.visibleCells.forEach { $0.alpha = 1.0; $0.isUserInteractionEnabled = true }
                
                let canUpdate = cell.languagePicker.selectedRow(inComponent: 0) != cell.list.favoritesItems.count-1
                canUpdate ? cell.updateOnEditingDidEnd(): ()
                
                self.cached = (cell, self.favoritesList.indexPath(for: cell))
                TranslationManager.shared.translate(word: cell.associatedWord.text ?? .init(),
                                                    to: cell.list.selectedLanguage)
                
            }).disposed(by: cell.disposeBag)
    }
    
    private func setupPickerView(on cell: FavoriteCell) {
        cell.list.favoritesItemsRelay
            .bind(to: cell.languagePicker.rx.items) { row, image, component in
                cell.languagePicker.subviews.forEach { $0.isHidden = $0.frame.height < 1.0 }
                
                let flagView = UIView(frame: .init(x: cell.languagePicker.frame.origin.x,
                                                   y: cell.languagePicker.frame.origin.y,
                                                   width: cell.languagePicker.frame.size.width,
                                                   height: cell.languagePicker.frame.size.height))
                
                let frame = CGRect(x: flagView.bounds.midX, y: flagView.bounds.midY, width: 20.0, height: 20.0)
                let imageView = UIImageView(frame: frame)
                imageView.center = CGPoint(x: flagView.bounds.midX, y: flagView.bounds.midY)
                imageView.image = image
                
                flagView.transform = .init(rotationAngle: 90 * (.pi/180))
                flagView.addSubview(imageView)
                
                return flagView
            }.disposed(by: disposeBag)
        
        cell.languagePicker.rx.itemSelected
            .bind(onNext: { [weak self] row, component in
                if row == cell.list.favoritesItems.count-1 && !cell.list.items.isEmpty {
                    cell.displayLanguagesMenu()
                } else {
                    cell.selectedRow = row
                    cell.list.selectedLanguage = cell.list.favoritesLanguages[row]
                    
                    self?.cached = (cell, self?.favoritesList.indexPath(for: cell))
                    TranslationManager.shared.translate(word: cell.associatedWord.text ?? .init(),
                                                        to: cell.list.selectedLanguage)
                }
            }).disposed(by: cell.disposeBag)
        
        cell.languagePicker.selectRow(cell.list.selectedLanguageIndex, inComponent: 0, animated: false)
    }
    
    private func setupDeleteFavorite() {
        favoritesList.rx.itemDeleted
            .bind(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                
                var favorites = self.favoritesRelay.value
                favorites.remove(at: indexPath.row)
                self.favoritesRelay.accept(favorites)
                
                self.coreDataManager.deleteFavorite(at: indexPath.item)
                
                if self.favoritesRelay.value.isEmpty {
                    self.presentAlertController()
                }
            }).disposed(by: disposeBag)
    }
}
