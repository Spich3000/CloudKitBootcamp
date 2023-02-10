//
//  CloudKitUtility.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 09.02.2023.
//

import Foundation
import CloudKit
import Combine

class CloudKitUtility {
    
    enum CloudKirError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountUnknown
        case iCloudApplicationPermissionNotGranted
        case iCloudCouldNotFetchUserID
        case iCloudCouldNotDiscoverUser
    }
 
}

// MARK: USER FUNCTIONS
extension CloudKitUtility {
    static private func getiCloudStatus(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            switch returnedStatus {
            case .available:
                completion(.success(true))
            case .noAccount:
                completion(.failure(CloudKirError.iCloudAccountNotFound))
            case .couldNotDetermine:
                completion(.failure(CloudKirError.iCloudAccountNotDetermined))
            case .restricted:
                completion(.failure(CloudKirError.iCloudAccountRestricted))
            default:
                completion(.failure(CloudKirError.iCloudAccountUnknown))
            }
        }
    }
    
    static func getiCloudStatus() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.getiCloudStatus { result in
                promise(result)
            }
        }
    }

    
    static private func requestApplicationPermission(completion: @escaping (Result<Bool, Error>) -> ()) {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) {  returnedStatus, returnedError in
            if returnedStatus == .granted {
                completion(.success(true))
            } else {
                completion(.failure(CloudKirError.iCloudApplicationPermissionNotGranted))
            }
        }
    }
    
    static func requestApplicationPermission() -> Future<Bool, Error> {
        Future { promise in
            CloudKitUtility.requestApplicationPermission { result in
                promise(result)
            }
        }
    }
    
    static private func fetchUserRecordID(completion: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        CKContainer.default().fetchUserRecordID { returnedID, returnedError in
            if let id = returnedID {
                completion(.success(id))
            } else {
                completion(.failure(CloudKirError.iCloudCouldNotFetchUserID))
            }
        }
    }
    
    static private func discoverUserIdentity(id: CKRecord.ID, completion: @escaping (Result<String, Error>) -> ()) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) {  returnedIdentity, returnedError in
            if let name = returnedIdentity?.nameComponents?.givenName {
                completion(.success(name))
            } else {
                completion(.failure(CloudKirError.iCloudCouldNotDiscoverUser))
            }
            
            if let secondName = returnedIdentity?.nameComponents?.familyName {
                completion(.success(secondName))
            } else {
                completion(.failure(CloudKirError.iCloudCouldNotDiscoverUser))
            }
        }
    }
    
    static private func discoverUserIdentity(completion: @escaping (Result<String, Error>) -> ()) {
        fetchUserRecordID { fetchCompletion in
            switch fetchCompletion {
            case .success(let recordID):
                CloudKitUtility.discoverUserIdentity(id: recordID, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    static func discoverUserIdentity() -> Future<String, Error> {
        Future { promise in
            CloudKitUtility.discoverUserIdentity { result in
                promise(result)
            }
        }
    }
}


// MARK: CRUD FUNCTIONS
extension CloudKitUtility {
    
    static func fetch( predicate: NSPredicate,
                       recordType: CKRecord.RecordType,
                       sortDescriptions: [NSSortDescriptor]? = nil,
                       resultsLimit: Int? = nil,
                       completion: @escaping (_ items: [FruitModel]) -> ()) {
        // create operation
        let operation = createOperation(predicate: predicate, recordType: recordType, sortDescriptions: sortDescriptions, resultsLimit: resultsLimit)
        
        // get items in query
        var returnedItems: [FruitModel] = []
        addRecordMatchedBlock(operation: operation) { item in
            returnedItems.append(item)
        }
        
        // Query completion
        addQueryResultBlock(operation: operation) { finished in
            completion(returnedItems)
        }
        
        // execute operation
        add(operation: operation)
    }
    
    static private func createOperation(
        predicate: NSPredicate,
        recordType: CKRecord.RecordType,
        sortDescriptions: [NSSortDescriptor]? = nil,
        resultsLimit: Int? = nil) -> CKQueryOperation {
            let query = CKQuery(recordType: recordType, predicate: predicate)
            query.sortDescriptors = sortDescriptions
            let queryOperation = CKQueryOperation(query: query)
            if let limit = resultsLimit {
                queryOperation.resultsLimit = limit
            }
            return queryOperation
        }
    
    static private func addRecordMatchedBlock(operation: CKQueryOperation, completion: @escaping (_ item: FruitModel) -> ()) {
        if #available(iOS 15.0, *) {
            operation.recordMatchedBlock = { returbedRecordID, returnedResult in
                switch returnedResult {
                case .success(let record):
                    guard let name = record["name"] as? String else { return }
                    let imageAsset = record["image"] as? CKAsset
                    let imageURL = imageAsset?.fileURL
                    let item = FruitModel(name: name, imageURL: imageURL, record: record)
                        completion(item)
                case .failure:
                    break
                }
            }
        } else {
            operation.recordFetchedBlock = { returnedRecord in
                guard let name = returnedRecord["name"] as? String else { return }
                let imageAsset = returnedRecord["image"] as? CKAsset
                let imageURL = imageAsset?.fileURL
                let item = FruitModel(name: name, imageURL: imageURL, record: returnedRecord)
                completion(item)
            }
        }
    }
    
    static private func addQueryResultBlock(operation: CKQueryOperation, completion: @escaping (_ finished: Bool) -> ()) {
        if #available(iOS 15.0, *) {
            operation.queryResultBlock = { returnedResult in
                completion(true)
            }
        } else {
            operation.queryCompletionBlock = { (returnedCursor, returnedError) in
                completion(true)
            }
        }
    }
    
    static private func add(operation: CKQueryOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
}
