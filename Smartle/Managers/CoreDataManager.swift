//
//  CoreDataManager.swift
//  Smartle
//
//  Created by Jullianm on 06/03/2020.
//  Copyright © 2020 jullianm. All rights reserved.
//

import CoreData
import UIKit

class CoreDataManager {
    var managedObjectContext: NSManagedObjectContext!
    var revisionEntity: NSEntityDescription!
    var mainEntity: NSEntityDescription!
    
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
    
    func fetchMain() {
        let fetchRequest = Main.createFetchRequest()
        do {
            let fetchResults = try managedObjectContext.fetch(fetchRequest)
            if fetchResults.isEmpty {
                LanguageManager.shared.favoritesItems = [UIImage(named: "france")!, UIImage(named: "add_language")!]
                LanguageManager.shared.items = [
                    "spain", "germany", "italy", "china", "arabic", "great_britain", "israel", "japan",
                    "portugal", "romania", "russia", "netherlands", "korea", "poland", "greece"
                    ].compactMap(UIImage.init(named:))
                LanguageManager.shared.favoritesLanguages = ["FR"]
                LanguageManager.shared.languages = ["ES", "DE", "IT", "ZH", "AR", "EN", "HE", "JA", "PT", "RO", "RU", "NL", "KO", "PL", "EL"]
                LanguageManager.shared.chosenLanguage = "FR"
            } else {
                for result in fetchResults {
                    LanguageManager.shared.favoritesItems = result.favoritesItems.uiImages()
                    LanguageManager.shared.items = result.items.uiImages()
                    LanguageManager.shared.favoritesLanguages = result.favoritesLanguages
                    LanguageManager.shared.languages = result.languages
                    LanguageManager.shared.chosenLanguage = result.chosenLanguage
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func saveContext() {
        do {
            try managedObjectContext.save()
        } catch {
            print(error.localizedDescription)
        }
    }
}
