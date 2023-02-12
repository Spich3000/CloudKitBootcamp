//
//  CloudKitCrudBootcamp.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 01.02.2023.
//

import SwiftUI
import CloudKit
import Combine

protocol CloudKitableProtocol {
    init?(record: CKRecord)
    var record: CKRecord { get }
}

// MARK: DATA MODEL
struct FruitModel: Hashable, CloudKitableProtocol {
    let name: String
    let imageURL: URL?
    let count: Int
    let record: CKRecord
    
    init?(record: CKRecord) {
        guard let name = record["name"] as? String else { return nil }
        self.name = name
        let imageAsset = record["image"] as? CKAsset
        self.imageURL = imageAsset?.fileURL
        let count = record["count"] as? Int
        self.count = count ?? 0
        self.record = record
    }
    
    init?(name: String, imageURL: URL?, count: Int?) {

        let record = CKRecord(recordType: "Fruits")
        record["name"] = name
        if let url = imageURL {
            let asset = CKAsset(fileURL: url) // convert to CKAsset
            record["image"] = asset
        }
        if let count = count {
            record["count"] = count
        }
        self.init(record: record)
    }
    
    func update(newName: String) -> FruitModel? {
        let record = record
        record["name"] = newName
        return FruitModel(record: record)
    }
    
}

// MARK: CLOUDKIT VIEW MODEL
class CloudKitCrudBootcampViewModel: ObservableObject {
    
    @Published var text: String = ""
    @Published var fruits: [FruitModel] = []
    var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchItems()
    }
    
    func addButtonPressed() {
        guard !text.isEmpty else { return }
        addItem(name: text)
    }
    
    // MARK: ADD ITEM
    private func addItem(name: String) {
//        let newFruit = CKRecord(recordType: "Fruits")
//        newFruit["name"] = name
        
        // save image from app to Cloudkit
        guard
            let image = UIImage(named: "comrad"),
            // to prepare image we shoould save it for filemanager
            let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appending(component: "comrad.png"),
            let data = image.pngData()
        else { return }
        
        do {
            try data.write(to: url)
            guard let newFruit = FruitModel(name: name, imageURL: url, count: 5) else { return }
            
            CloudKitUtility.add(item: newFruit) { result in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.fetchItems()
                }
            }
            
//            let asset = CKAsset(fileURL: url) // convert to CKAsset
//            newFruit["image"] = asset
//            saveItem(record: newFruit)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // MARK: SAVE ITEM
//    private func saveItem(record: CKRecord) {
//        CKContainer.default().publicCloudDatabase.save(record) { [weak self] returnedRecord, returnedError in
//            //            print("Record: \(returnedRecord)")
//            //            print("Error: \(returnedError)")
//
//            DispatchQueue.main.async {
//                self?.text = ""
//                self?.fetchItems() // Update UI after saving
//            }
//        }
//    }
    
    // MARK: FETCH ITEMS FROM DATA BASE
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let recordType = "Fruits"
        
        CloudKitUtility.fetch(predicate: predicate, recordType: recordType)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] returnedItems in
                self?.fruits = returnedItems
            }
            .store(in: &cancellables)
        
        // Search in category btw
        //        let predicate = NSPredicate(format: "name = %@", argumentArray: ["Apple"])
        //        let query = CKQuery(recordType: "Fruits", predicate: predicate)
        // Sort the query
        //        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)] // Sort type insert here
        //        let queryOperation = CKQueryOperation(query: query)
        
        
        // there were part2
//        CloudKitUtility.fetch(predicate: predicate, recordType: "Fruits", sortDescriptions: nil, resultsLimit: nil) { [weak self] (returnedItems: [FruitModel]) in
//            DispatchQueue.main.async {
//                self?.fruits = returnedItems
//            }
//        }
        
        
        // Operation limit has max of 100 items in query
        // queryOperation.resultsLimit = 2
        
//        var returnedItems: [FruitModel] = []
//
//        if #available(iOS 15.0, *) {
//            queryOperation.recordMatchedBlock = { returbedRecordID, returnedResult in
//                switch returnedResult {
//                case .success(let record):
//                    guard let name = record["name"] as? String else { return }
//                    let imageAsset = record["image"] as? CKAsset
//                    let imageURL = imageAsset?.fileURL
//                    returnedItems.append(FruitModel(name: name, imageURL: imageURL, record: record))
//
//                    /*
//
//                     Sort by:
//
//                     record.creationDate
//                     record.lastModifiedUserRecordID
//
//                     etc
//
//                     */
//
//                case .failure(let error):
//                    print("Error recordMatchedBlock: \(error)")
//                }
//            }
//        } else {
//            queryOperation.recordFetchedBlock = { returnedRecord in
//                guard let name = returnedRecord["name"] as? String else { return }
//                let imageAsset = returnedRecord["image"] as? CKAsset
//                let imageURL = imageAsset?.fileURL
//                returnedItems.append(FruitModel(name: name, imageURL: imageURL, record: returnedRecord))
//            }
//        }
//
//        if #available(iOS 15.0, *) {
//            queryOperation.queryResultBlock = { [weak self] returnedResult in
//                print("RETURNED queryResultBlock: \(returnedResult)")
//                DispatchQueue.main.async {
//                    self?.fruits = returnedItems
//                }
//            }
//        } else {
//            queryOperation.queryCompletionBlock = { [weak self] (returnedCursor, returnedError) in
//                print("RETURNED queryCompletionBlock")
//                DispatchQueue.main.async {
//                    self?.fruits = returnedItems
//                }
//            }
//        }
//
//        addOperation(operation: queryOperation)
    }
    
    // MARK: OPERATION
//    func addOperation(operation: CKQueryOperation) {
//        CKContainer.default().publicCloudDatabase.add(operation)
//    }
    
    // MARK: UPDATE ITEM
    func updateItem(fruit: FruitModel) {
        
        guard let newFruit = fruit.update(newName: "NEW NAME") else { return }
        CloudKitUtility.update(item: newFruit) { [weak self] result in
            print("Update completed")
            self?.fetchItems()
        }
        
//        let record = fruit.record
//        record["name"] = "New Name"
//        saveItem(record: record)
    }
    
    // MARK: DELETE ITEM
    func deleteItem(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let fruit = fruits[index]
//        let record = fruit.record
        
        CloudKitUtility.delete(item: fruit)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] success in
                print("Delete is \(success)")
                self?.fruits.remove(at: index)
            }
            .store(in: &cancellables)

        
//        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { [weak self] returnedRecordID, returnedError in
//            DispatchQueue.main.async {
//                self?.fruits.remove(at: index)
//            }
//        }
    }
}

// MARK: VIEW
struct CloudKitCrudBootcamp: View {
    
    @StateObject private var vm = CloudKitCrudBootcampViewModel()
    
    // MARK: BODY
    var body: some View {
        NavigationView {
            VStack {
                header
                textField
                addButton
                
                List {
                    ForEach(vm.fruits, id:  \.self) { fruit in
                        HStack {
                            Text(fruit.name)
                            if let url = fruit.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .onTapGesture {
                            vm.updateItem(fruit: fruit)
                        }
                    }
                    .onDelete(perform: vm.deleteItem)
                }
                .listStyle(PlainListStyle())
                
                NavigationLink {
                    CloudKitPushNotificationBootcamp()
                } label: {
                    Text("Push")
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

// MARK: PREVIEW
struct CloudKitCrudBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitCrudBootcamp()
    }
}

// MARK: EXTENSION
extension CloudKitCrudBootcamp{
    
    private var header: some View {
        Text("CloudKit CRUD")
            .font(.headline)
    }
    
    private var textField: some View {
        TextField("Add something here...", text: $vm.text)
            .frame(height: 55)
            .padding(.leading)
            .background(.gray.opacity(0.4))
            .cornerRadius(10)
    }
    
    private var addButton: some View {
        Button {
            vm.addButtonPressed()
        } label: {
            Text("Add")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(.pink)
                .cornerRadius(10)
        }
    }
}
