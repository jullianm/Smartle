//
//  AppDelegate.swift
//  Smartle
//
//  Created by jullianm on 15/02/2018.
//  Copyright © 2018 jullianm. All rights reserved.
//
import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    var tabBarController: UITabBarController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        tabBarController = self.window!.rootViewController as? UITabBarController
        
        let cameraVC = tabBarController.viewControllers![0] as! CameraViewController
        
        cameraVC.coreDataManager.managedObjectContext = persistentContainer.viewContext
        cameraVC.coreDataManager.mainEntity = NSEntityDescription.entity(forEntityName: "Main", in: persistentContainer.viewContext)
        cameraVC.coreDataManager.revisionEntity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        
        let photosVC = tabBarController.viewControllers![1] as! PhotosViewController
        photosVC.coreDataManager.managedObjectContext = persistentContainer.viewContext
        photosVC.coreDataManager.revisionEntity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        
        let favoritesVC = tabBarController.viewControllers![2] as! FavoritesViewController
        favoritesVC.coreDataManager.managedObjectContext = persistentContainer.viewContext
        favoritesVC.coreDataManager.revisionEntity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        
        return true

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Smartle")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
