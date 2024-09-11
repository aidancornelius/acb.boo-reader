//
//  SettingsView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 11/9/2024.
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @Published var apiKey: String {
        didSet {
            UserDefaults.standard.set(apiKey, forKey: "apiKey")
        }
    }
    
    init() {
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
    }
}

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings
    
    var body: some View {
        Form {
            Section(header: Text("API Settings")) {
                SecureField("API Key", text: $appSettings.apiKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section {
                Button("Clear API Key") {
                    appSettings.apiKey = ""
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Settings")
    }
}
