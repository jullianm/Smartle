//
//  Main+CoreDataProperties.swift
//  Smartle
//
//  Created by jullianm on 27/03/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//
//

import Foundation
import CoreData

extension Main {
    @nonobjc public class func createFetchRequest() -> NSFetchRequest<Main> {
        return NSFetchRequest<Main>(entityName: "Main")
    }

    @NSManaged public var chosenLanguage: String
    @NSManaged public var favoritesItems: [Data]
    @NSManaged public var favoritesLanguages: [String]
    @NSManaged public var items: [Data]
    @NSManaged public var languages: [String]
}

