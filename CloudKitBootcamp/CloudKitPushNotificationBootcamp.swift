//
//  CloudKitPushNotificationBootcamp.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 08.02.2023.
//

import SwiftUI
import CloudKit

class CloudKitPushNotificationBootcampViewModel: ObservableObject {
    
    func requestNotoficationPermissions() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { success, error in
            if let error = error {
                print(error.localizedDescription)
            } else if  success {
                print("Notifications permissions success!")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permissions failure")
            }
        }
    }
    
    func subscribeToNotifications() {
        
        let predicate = NSPredicate(value: true)

        let subscription = CKQuerySubscription(recordType: "Fruits", predicate: predicate, subscriptionID: "fruit_added_to_database", options: .firesOnRecordCreation)
        // prepare notification look
        let notification = CKSubscription.NotificationInfo()
        notification.title = "There's a new fruit!"
        notification.alertBody = "Open the app to check your fruits"
        notification.soundName = "default"
        
        subscription.notificationInfo = notification
        
        CKContainer.default().publicCloudDatabase.save(subscription) { returnedSubscription, returnedError in
            if let error = returnedError {
                print(error.localizedDescription)
            } else {
                print("Successfuly subscribe to notifications")
            }
        }
    }
    
    func unsubscribeToNotifications() {
//        CKContainer.default().publicCloudDatabase.fetchAllSubscriptions
        
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: "fruit_added_to_database") { returnedID, returnedError in
            if let error = returnedError {
                print(error)
            } else {
                print("Successfuly unsubscribe")
            }
        }
    }
    
}

struct CloudKitPushNotificationBootcamp: View {
    
    @StateObject private var vm = CloudKitPushNotificationBootcampViewModel()
    
    var body: some View {
        VStack(spacing: 40.0) {
            Button("Requst notification permission") {
                vm.requestNotoficationPermissions()
            }
            
            Button("Subscribe to notification") {
                vm.subscribeToNotifications()
            }
            
            Button("Unsubscribe to notification") {
                vm.unsubscribeToNotifications()
            }
            
            

        }
    }
}

struct CloudKitPushNotificationBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitPushNotificationBootcamp()
    }
}
