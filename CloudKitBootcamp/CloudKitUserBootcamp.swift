//
//  CloudKitUserBootcamp.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 01.02.2023.
//

import SwiftUI
import CloudKit

class CloudKitUserBootcampViewModel: ObservableObject {
    
    @Published var isSignInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var user: [String] = []
    @Published var permissionStatus: Bool = false

    
    init() {
        getiCloudStatus()
        requestPermission()
        fetchiCloudUserRecordID()
    }
    
    private func getiCloudStatus() {
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
    }
    
    enum CloudKirError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountUnknown
    }
    
    func fetchiCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
            if let id = returnedID {
                self?.discoveriCloudUser(id: id)
            }
        }
    }
    
    func requestPermission() {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                if returnedStatus == .granted {
                    self?.permissionStatus = true
                }
            }
        }
    }
    
    func discoveriCloudUser(id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError in
            DispatchQueue.main.async {
                if let name = returnedIdentity?.nameComponents?.givenName {
                    self?.user.append(name)
                }
                if let secondName = returnedIdentity?.nameComponents?.familyName {
                    self?.user.append(secondName)
                }
                
                /*
                 we cant get it cause we search user with (withUserRecordID: id)
                 
                if let mail = returnedIdentity?.lookupInfo?.emailAddress {
                    self?.user.append(mail)
                }
                if let phone = returnedIdentity?.lookupInfo?.phoneNumber {
                    self?.user.append(phone)
                }
                 */
            }
        }
    }
    
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
