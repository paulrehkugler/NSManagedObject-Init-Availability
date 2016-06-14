//
//  CoreDataObjectCreator.swift
//  NSManagedObject Init Availability
//
//  Created by Paul Rehkugler on 6/14/16.
//  Copyright © 2016 Tumblr. All rights reserved.
//

import CoreData
import UIKit

class CoreDataObjectCreator: NSObject {
    let persistentStoreCoordinator: NSPersistentStoreCoordinator
    let mainQueueContext: NSManagedObjectContext

    override init() {
        guard let managedObjectModelURL = Bundle.main().urlForResource("Model", withExtension: "momd") else {
            fatalError("Couldn't construct a URL for Model.momd in the resource bundle.")
        }

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelURL) else {
            fatalError("Couldn't inflate a NSManagedObjectModel from the contents of the URL \(managedObjectModelURL).")
        }

        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        mainQueueContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainQueueContext.persistentStoreCoordinator = persistentStoreCoordinator
    }

    func makeManagedObject() -> NSManagedObject {
        var entity: Entity?

        performInBackgroundAndWait { context in
            /*
                NSManagedObject(context:) is not new to iOS 10!!!
             */
            if #available(iOS 10.0, *) {
                entity = Entity(context: context)
            }
            else {
                fatalError("HELP! This code worked properly on iOS 9, too.")
            }
        }

        guard let initializedEntity = entity else {
            fatalError("Expected to have an entity here.")
        }

        return initializedEntity
    }

    // MARK: - Private

    func performInBackgroundAndWait(backgroundBlock: ((NSManagedObjectContext) -> ())) {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = mainQueueContext

        func performAndWait() {
            backgroundBlock(context)

            var contextToSave: NSManagedObjectContext? = context
            while (contextToSave?.hasChanges ?? false) {
                do {
                    try contextToSave?.save()
                    contextToSave = contextToSave?.parent
                }
                catch let error as NSError {
                    NSLog("\(error)")
                }
            }
        }

        context.performAndWait(performAndWait)
    }
}
