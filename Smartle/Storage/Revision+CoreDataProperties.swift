//
//  Revision+CoreDataProperties.swift
//  Smartle
//
//  Created by jullianm on 27/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//
//

import Foundation
import CoreData


extension Revision {

    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Revision> {
        let fetchRequest = NSFetchRequest<Revision>(entityName: "Revision")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        return fetchRequest
    }

    @NSManaged public var currentTranslation: String
    @NSManaged public var date: NSDate
    @NSManaged public var favoritesItems: [Data]
    @NSManaged public var favoritesLanguages: [String]
    @NSManaged public var items: [Data]
    @NSManaged public var languages: [String]
    @NSManaged public var originalTranslation: String
    @NSManaged public var photo: Data
    @NSManaged public var selectedLanguage: String

}

