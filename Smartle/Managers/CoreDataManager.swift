//
//  CoreDataManager.swift
//  Smartle
//
//  Created by Jullianm on 06/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import CoreData
import RxCocoa
import RxSwift
import UIKit

class CoreDataManager {
    var managedObjectContext: NSManagedObjectContext!
    var revisionEntity: NSEntityDescription!
    var mainEntity: NSEntityDescription!
    
    // MARK: - Main storage
    func saveMain() {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        privateContext.perform {
            let main = Main(entity: self.mainEntity, insertInto: self.managedObjectContext)
            main.favoritesItems = LanguageManager.shared.favoritesItems.data()
            main.items = LanguageManager.shared.items.data()
            main.favoritesLanguages = LanguageManager.shared.favoritesLanguages
            main.languages = LanguageManager.shared.languages
            main.chosenLanguage = LanguageManager.shared.chosenLanguage
            self.saveContext()
        }
    }
    
    func fetchMain() {
        let storage = (try? managedObjectContext.fetch(Main.createFetchRequest())) ?? []
        let manager = LanguageManager.shared
        
        storage.isEmpty ? manager.install(): manager.install(fromStorage: storage)
    }
    
    func updateMain() {
        let results = try? managedObjectContext.fetch(Main.createFetchRequest())
        if results?.count == 0 {
            saveMain()
        } else {
            results?.forEach { result in
                result.favoritesItems = LanguageManager.shared.favoritesItems.data()
                result.items = LanguageManager.shared.items.data()
                result.favoritesLanguages = LanguageManager.shared.favoritesLanguages
                result.languages = LanguageManager.shared.languages
                result.chosenLanguage = LanguageManager.shared.chosenLanguage
            }
        }
    }
    
    // MARK: - Revision storage
    func fetchRevisions() -> [FavoritesList] {
        let results = try? managedObjectContext.fetch(Revision.createFetchRequest()) 
        
        return results?
            .map { result -> FavoritesList in
                return FavoritesList(currentTranslation: result.currentTranslation,
                                     favoritesItems: result.favoritesItems.uiImages(),
                                     favoritesLanguages: result.favoritesLanguages,
                                     items: result.items.uiImages(),
                                     languages: result.languages,
                                     originalTranslation: result.originalTranslation,
                                     photo: UIImage(data: result.photo) ?? .init(),
                                     selectedLanguage: result.selectedLanguage)
            } ?? []
    }
    
    func deleteRevision(atIndex index: Int) {
        guard let results = try? managedObjectContext.fetch(Revision.createFetchRequest()), let index = results.enumerated().first(where: { $0.offset == index })?.offset else {
            return
        }
        
        managedObjectContext.delete(results[index])
        saveContext()
    }
    
    func saveRevision(data: Data, translation: String) {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        privateContext.perform {
            let revision = Revision(entity: self.revisionEntity, insertInto: self.managedObjectContext)
            revision.photo = data
            revision.currentTranslation = translation
            revision.originalTranslation = translation
            revision.selectedLanguage = LanguageManager.shared.chosenLanguage
            revision.date = NSDate()
            revision.favoritesItems = LanguageManager.shared.favoritesItems.data()
            revision.items = LanguageManager.shared.items.data()
            revision.languages = LanguageManager.shared.languages
            revision.favoritesLanguages = LanguageManager.shared.favoritesLanguages
            self.saveContext()
        }
    }

    private func saveContext() {
        try? managedObjectContext.save()
    }
}
