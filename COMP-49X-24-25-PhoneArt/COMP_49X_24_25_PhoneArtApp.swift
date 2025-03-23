//
//  COMP_49X_24_25_PhoneArtApp.swift
//  COMP-49X-24-25-PhoneArt
//
//  Created by Aditya Prakash on 11/21/24.
//

import SwiftUI
import FirebaseCore

@main
struct COMP_49X_24_25_PhoneArtApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// AppDelegate class to initialize Firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
