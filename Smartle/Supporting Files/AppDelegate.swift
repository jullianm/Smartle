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
//    let animator = Animator()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        tabBarController = self.window!.rootViewController as? UITabBarController
        tabBarController.delegate = self
//        animator.tbc = tabBarController
//        let sep = UIScreenEdgePanGestureRecognizer(target:self, action:#selector(pan))
//        sep.edges = UIRectEdge.right
//        tabBarController.view.addGestureRecognizer(sep)
//        sep.delegate = self
//        let sep2 = UIScreenEdgePanGestureRecognizer(target:self, action:#selector(pan))
//        sep2.edges = UIRectEdge.left
//        tabBarController.view.addGestureRecognizer(sep2)
//        sep2.delegate = self
        
        let cameraVC = tabBarController.viewControllers![0] as! CameraViewController
        let photosVC = tabBarController.viewControllers![1] as! PhotosViewController
        let favoritesVC = tabBarController.viewControllers![2] as! FavoritesViewController
        cameraVC.managedObjectContext = persistentContainer.viewContext
        cameraVC.mainEntity = NSEntityDescription.entity(forEntityName: "Main", in: persistentContainer.viewContext)
        cameraVC.revisionEntity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        photosVC.managedObjectContext = persistentContainer.viewContext
        photosVC.entity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        favoritesVC.managedObjectContext = persistentContainer.viewContext
        favoritesVC.entity = NSEntityDescription.entity(forEntityName: "Revision", in: persistentContainer.viewContext)
        
        return true

    }
//    @objc func pan(_ g:UIScreenEdgePanGestureRecognizer) {
//        switch g.state {
//        case .began:
//            animator.interacting = true
//            let tbc = self.window!.rootViewController as! UITabBarController
//            if g.edges == .right {
//                tbc.selectedIndex = tbc.selectedIndex + 1
//            } else {
//                tbc.selectedIndex = tbc.selectedIndex - 1
//            }
//        case .changed:
//            let v = g.view!
//            let delta = g.translation(in:v)
//            let percent = abs(delta.x/v.bounds.size.width)
//            animator.anim?.fractionComplete = percent
//            animator.context?.updateInteractiveTransition(percent)
//        case .ended:
//            let anim = animator.anim as! UIViewPropertyAnimator
//            anim.pauseAnimation()
//            if anim.fractionComplete < 0.5 {
//                anim.isReversed = true
//            }
//            anim.continueAnimation(
//                withTimingParameters:
//                UICubicTimingParameters(animationCurve: .linear),
//                durationFactor: 0.2)
//            anim.addCompletion { finish in
//                if finish == .end {
//                    self.animator.context?.finishInteractiveTransition()
//                    self.animator.context?.completeTransition(true)
//                } else {
//                    self.animator.context?.cancelInteractiveTransition()
//                    self.animator.context?.completeTransition(false)
//                }
//            }
//        default:
//            break
//        }
//    }
//    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return animator
//    }
//    func tabBarController(_ tabBarController: UITabBarController,
//                          interactionControllerFor ac: UIViewControllerAnimatedTransitioning)
//        -> UIViewControllerInteractiveTransitioning? {
//            return animator.interacting ? animator : nil
//    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
extension AppDelegate : UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
        let tbc = self.window!.rootViewController as! UITabBarController
        var result = false
        if (g as! UIScreenEdgePanGestureRecognizer).edges == .right {
            result = (tbc.selectedIndex < tbc.viewControllers!.count - 1)
        }
        else {
            result = (tbc.selectedIndex > 0)
        }
        return result
    }
}
