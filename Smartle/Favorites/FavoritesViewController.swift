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

    // MARK: - Outlets
    @IBOutlet weak var revisionList: UITableView!
    @IBOutlet weak var dataLoading: UIActivityIndicatorView!
    @IBOutlet weak var titleView: UIView!
    
    var disposeBag = DisposeBag()
    // MARK: - Properties
    private lazy var revisions = [RevisionsList]()
    private lazy var titleBottomLine = CALayer()
    private let fetchRequest = Revision.createFetchRequest()
    var coreDataManager = CoreDataManager()
    
    // MARK: View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        revisionList.dataSource = self
        revisionList.delegate = self
        revisionList.tableFooterView = UIView()
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
        revisions = [RevisionsList]()
    }
    // MARK: - Methods
    private func fetchRevision() {
        do {
            let fetchResults = try coreDataManager.managedObjectContext.fetch(fetchRequest)
            if fetchResults.count < 1 {
                self.presentAlertVC()
            } else {
                for revision in fetchResults {
                    guard let photo = UIImage(data: revision.photo) else { return }
                    revisions.append(RevisionsList(currentTranslation: revision.currentTranslation, favoritesItems: revision.favoritesItems.uiImages(), favoritesLanguages: revision.favoritesLanguages, items: revision.items.uiImages(), languages: revision.languages, originalTranslation: revision.originalTranslation, photo: photo, selectedLanguage: revision.selectedLanguage))
                }
                self.revisionList.reloadData()
            }
            self.dataLoading.stopAnimating()
        } catch {
            print(error.localizedDescription)
        }
    }
    private func presentAlertVC() {
        let alertVC = UIAlertController(title: "Nothing to learn !", message: "Add favorites by tapping the heart at the bottom right", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
}
// MARK: - TableView
extension FavoritesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return revisions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "revisionCell", for: indexPath) as! RevisionCell
        cell.favoritesItems = revisions[indexPath.item].favoritesItems
        cell.items = revisions[indexPath.item].items
        cell.favoritesLanguages = revisions[indexPath.item].favoritesLanguages
        cell.languages = revisions[indexPath.item].languages
        cell.chosenLanguage = revisions[indexPath.item].selectedLanguage
        cell.languagePicker.reloadAllComponents()
        cell.languagesList.reloadData()
        cell.wordReplacemenDelegate = self
        cell.translationDelegate = self
        cell.photo.image = revisions[indexPath.item].photo
        cell.associatedWord.text = revisions[indexPath.item].currentTranslation
        for (index, language) in cell.favoritesLanguages.enumerated() where language == revisions[indexPath.item].selectedLanguage {
            cell.languagePicker.selectRow(index, inComponent: 0, animated: false)
        }
        return cell
    }
}
extension FavoritesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 93.0
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let cell = tableView.cellForRow(at: indexPath) as? RevisionCell {
            if cell.isBeingEdited || !cell.isUserInteractionEnabled {
                return false
            }
        }
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                let fetchResults = try coreDataManager.managedObjectContext.fetch(fetchRequest)
                if fetchResults.count > 0 {
                    fetchResults.enumerated().forEach({ index, _ in
                        if index == indexPath.row {
                            revisions.remove(at: indexPath.row)
                            coreDataManager.managedObjectContext.delete(fetchResults[indexPath.row])
                            tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    })
                    coreDataManager.saveContext()
                }
            } catch {
                fatalError(error.localizedDescription)
            }
            if revisions.count == 0 {
                self.presentAlertVC()
            }
        }
    }
}
// MARK: User Word Replacement
extension FavoritesViewController: UserWordReplacementDelegate {
    func replace(userWord: String, to chosenLanguage: String, at indexPath: IndexPath) {
//        TranslationProvider.shared.translate(word: userWord, to: chosenLanguage)
//            .drive(onNext: { translation in
//                guard let cell = self.revisionList.cellForRow(at: indexPath) as? RevisionCell else { return }
//                cell.associatedWord.text = translation
//                self.revisions[indexPath.item].currentTranslation = translation
//                self.revisions[indexPath.item].originalTranslation = translation
//                do {
//                    let fetchResults = try self.coreDataManager.managedObjectContext.fetch(self.fetchRequest)
//                    fetchResults[indexPath.item].currentTranslation = translation
//                    fetchResults[indexPath.item].originalTranslation = translation
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }).disposed(by: disposeBag)
    }
}
// MARK: Request Translation
extension FavoritesViewController: RequestTranslationDelegate {
    func requestTranslation(to chosenLanguage: String, at indexPath: IndexPath) {
//        TranslationProvider.shared.translate(word: revisions[indexPath.item].originalTranslation, to: chosenLanguage)
//            .drive(onNext: { translation in
//                guard let cell = self.revisionList.cellForRow(at: indexPath) as? RevisionCell else { return }
//                cell.associatedWord.text = translation
//                self.revisions[indexPath.item].currentTranslation = translation
//                self.revisions[indexPath.item].favoritesLanguages = cell.favoritesLanguages
//                self.revisions[indexPath.item].selectedLanguage = chosenLanguage
//                self.revisions[indexPath.item].favoritesItems = cell.favoritesItems
//                self.revisions[indexPath.item].items = cell.items
//                self.revisions[indexPath.item].languages = cell.languages
//                do {
//                    let fetchResults = try self.coreDataManager.managedObjectContext.fetch(self.fetchRequest)
//                    fetchResults[indexPath.item].currentTranslation = translation
//                    fetchResults[indexPath.item].favoritesLanguages = cell.favoritesLanguages
//                    fetchResults[indexPath.item].selectedLanguage = chosenLanguage
//                    fetchResults[indexPath.item].favoritesItems = convertToData(items: cell.favoritesItems)
//                    fetchResults[indexPath.item].items = convertToData(items: cell.items)
//                    fetchResults[indexPath.item].languages = cell.languages
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }).disposed(by: disposeBag)
    }
}
