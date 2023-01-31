//
//  CloudKitUserBootcamp.swift
//  CloudKitBootcamp
//
//  Created by Дмитрий Спичаков on 01.02.2023.
//

import SwiftUI

class CloudKitUserBootcampViewModel: ObservableObject {
    
    init() {
        getiCloudStatus()
    }
    
    private func getiCloudStatus() {
        
    }
    
}

struct CloudKitUserBootcamp: View {
    
    @StateObject var vm = CloudKitUserBootcampViewModel()
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CloudKitUserBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitUserBootcamp()
    }
}
