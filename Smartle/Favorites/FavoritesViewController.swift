//
//  FavoritesViewController.swift
//  Smartle
//
//  Created by jullianm on 20/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//

import RxSwift
import UIKit
import CoreData

class FavoritesViewController: UIViewController {
    @IBOutlet weak var favoritesList: UITableView! {
        didSet {
            favoritesList.rowHeight = 93.0
        }
    }
    @IBOutlet weak var dataLoading: UIActivityIndicatorView!
    @IBOutlet weak var titleView: UIView!
    
    @IBOutlet weak var separatorLineConstraint: NSLayoutConstraint! {
        didSet {
            separatorLineConstraint.constant = 0.2
        }
    }
    
    private let disposeBag = DisposeBag()
    private var favorites = [FavoritesList]()
    private let titleBottomLine = CALayer()
    private let fetchRequest = Revision.createFetchRequest()
    var coreDataManager = CoreDataManager()
    
    // MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        favoritesList.dataSource = self
        favoritesList.delegate = self
        favoritesList.tableFooterView = UIView()
        tabBarItem.selectedImage = tabBarItem.selectedImage?.withRenderingMode(.automatic)
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
        titleBottomLine.backgroundColor = #colorLiteral(red: 0.9766208529, green: 0.9123852253, blue: 0.7817487121, alpha: 1)
        titleView.layer.addSublayer(titleBottomLine)
    }
    
    override func viewDidLayoutSubviews() {
        titleBottomLine.frame = CGRect(x: 0.0, y: titleView.frame.height-0.2, width: titleView.frame.width, height: 0.2)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchRevision()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        favorites = .init()
    }

    private func fetchRevision() {
        favorites = coreDataManager.fetchRevisions()
        favoritesList.reloadData()
        dataLoading.stopAnimating()
    }
    
}
// MARK: - TableView
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteCell", for: indexPath) as? FavoriteCell
        cell?.setupModel(favorites[indexPath.item])
        cell?.setupBindings()
        cell?.delegate = self
        
        return cell ?? .init()
    }
}
extension FavoritesViewController: UITableViewDelegate {
    private func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let cell = tableView.cellForRow(at: indexPath) as? FavoriteCell ?? .init()
        return cell.isBeingEdited || !cell.isUserInteractionEnabled
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let results = (try? coreDataManager.managedObjectContext.fetch(Revision.createFetchRequest())) ?? []
        if results.count > 0 {
            results.enumerated().forEach({ index, _ in
                if index == indexPath.row {
                    favorites.remove(at: indexPath.row)
                    coreDataManager.managedObjectContext.delete(results[indexPath.row])
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
            
            try? coreDataManager.managedObjectContext.save()
            
        }
        
        if favorites.count == 0 {
            self.presentAlertController()
        }
        
    }
}
// MARK: User Word Replacement
extension FavoritesViewController: TranslationDelegate {
    func replace(userWord: String, to chosenLanguage: String, at indexPath: IndexPath) {
        TranslationManager.shared.translation
            .drive(onNext: { [weak self] translation in
                self?.handleReplacement(translation: translation, at: indexPath)
            }).disposed(by: disposeBag)
        
        TranslationManager.shared.translate(word: userWord,
                                            to: chosenLanguage)
    }
    func translate(to chosenLanguage: String, at indexPath: IndexPath) {
        TranslationManager.shared.translation
            .drive(onNext: { [weak self] translation in
                self?.handleTranslation(chosenLanguage: chosenLanguage, translation: translation, at: indexPath)
            }).disposed(by: disposeBag)
        
        TranslationManager.shared.translate(word: favorites[indexPath.item].originalTranslation,
                                            to: chosenLanguage)
    }
}

extension FavoritesViewController {
    private func handleReplacement(translation: String, at indexPath: IndexPath) {
        guard let cell = self.favoritesList.cellForRow(at: indexPath) as? FavoriteCell else { return }
        cell.associatedWord.text = translation
        favorites[indexPath.item].currentTranslation = translation
        favorites[indexPath.item].originalTranslation = translation
        
        let fetchResults = try? self.coreDataManager.managedObjectContext.fetch(self.fetchRequest)
        fetchResults?[indexPath.item].currentTranslation = translation
        fetchResults?[indexPath.item].originalTranslation = translation
    }
    
    private func handleTranslation(chosenLanguage: String, translation: String, at indexPath: IndexPath) {
        guard let cell = self.favoritesList.cellForRow(at: indexPath) as? FavoriteCell else { return }
        cell.associatedWord.text = translation
        favorites[indexPath.item].currentTranslation = translation
        favorites[indexPath.item].favoritesLanguages = cell.favoritesLanguages
        favorites[indexPath.item].selectedLanguage = chosenLanguage
        favorites[indexPath.item].favoritesItems = cell.favoritesItems
        favorites[indexPath.item].items = cell.items
        favorites[indexPath.item].languages = cell.languages
        
        let results = try? self.coreDataManager.managedObjectContext.fetch(self.fetchRequest)
        results?[indexPath.item].currentTranslation = translation
        results?[indexPath.item].favoritesLanguages = cell.favoritesLanguages
        results?[indexPath.item].selectedLanguage = chosenLanguage
        results?[indexPath.item].favoritesItems = cell.favoritesItems.data()
        results?[indexPath.item].items = cell.items.data()
        results?[indexPath.item].languages = cell.languages
    }
}
