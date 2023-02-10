//
//  CloudKitUserBootcamp.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 01.02.2023.
//

import SwiftUI
//import CloudKit
import Combine

class CloudKitUserBootcampViewModel: ObservableObject {
    
    @Published var isSignInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var user: [String] = []
    @Published var permissionStatus: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    
    init() {
        getiCloudStatus()
        requestPermission()
//        fetchiCloudUserRecordID()
        getCurrentUserName()
    }
    
    private func getiCloudStatus() {
        
        CloudKitUtility.getiCloudStatus()
            .receive(on: DispatchQueue.main) // receive on the main thread
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure (let error):
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                self?.isSignInToiCloud = success
            }
            .store(in: &cancellables)
        
        /* Goes to CloudKitUtility
         CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
         DispatchQueue.main.async {
         switch returnedStatus {
         case .available:
         self?.isSignInToiCloud = true
         case .noAccount:
         self?.error = CloudKirError.iCloudAccountNotFound.rawValue
         case .couldNotDetermine:
         self?.error = CloudKirError.iCloudAccountNotDetermined.rawValue
         case .restricted:
         self?.error = CloudKirError.iCloudAccountRestricted.rawValue
         default:
         self?.error = CloudKirError.iCloudAccountUnknown.rawValue
         }
         }
         }
         */
        
    }
    
    /* Goes to CloudKitUtility
     enum CloudKirError: String, LocalizedError {
     case iCloudAccountNotFound
     case iCloudAccountNotDetermined
     case iCloudAccountRestricted
     case iCloudAccountUnknown
     }
     */
    
    func requestPermission() {
        
        CloudKitUtility.requestApplicationPermission()
            .receive(on: DispatchQueue.main) // receive on the main thread
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure (let error):
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                self?.permissionStatus = success
            }
            .store(in: &cancellables)
        
        
//        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
//            DispatchQueue.main.async {
//                if returnedStatus == .granted {
//                    self?.permissionStatus = true
//                }
//            }
//        }
    }
    
    func getCurrentUserName() {
        CloudKitUtility.discoverUserIdentity()
            .receive(on: DispatchQueue.main) // receive on the main thread
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure (let error):
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] returnedName in
                self?.user.append(returnedName)
            }
            .store(in: &cancellables)
    }
    
//    func fetchiCloudUserRecordID() {
//        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
//            if let id = returnedID {
//                self?.discoveriCloudUser(id: id)
//            }
//        }
//    }
//
//    func discoveriCloudUser(id: CKRecord.ID) {
//        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError in
//            DispatchQueue.main.async {
//                if let name = returnedIdentity?.nameComponents?.givenName {
//                    self?.user.append(name)
//                }
//                if let secondName = returnedIdentity?.nameComponents?.familyName {
//                    self?.user.append(secondName)
//                }
//
//                /*
//                 we cant get it cause we search user with (withUserRecordID: id)
//
//                 if let mail = returnedIdentity?.lookupInfo?.emailAddress {
//                 self?.user.append(mail)
//                 }
//                 if let phone = returnedIdentity?.lookupInfo?.phoneNumber {
//                 self?.user.append(phone)
//                 }
//                 */
//            }
//        }
//    }
    
}

struct CloudKitUserBootcamp: View {
    
    @StateObject var vm = CloudKitUserBootcampViewModel()
    
    var body: some View {
        VStack {
            Text("IS SIGNED IN: \(vm.isSignInToiCloud.description.uppercased())")
            Text(vm.error)
            Text("PERMISSION: \(vm.permissionStatus.description.uppercased())")
            ForEach(vm.user, id: \.self) { info in
                Text(info)
            }
            
        }
    }
}

struct CloudKitUserBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitUserBootcamp()
    }
}
