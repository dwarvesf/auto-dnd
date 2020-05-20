//
//  Preference.swift
//  Auto DND
//
//  Created by phucld on 5/21/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Key {
        static let startAtLogin = "startAtLogin"
        static let showPreferencesOnLaunch = "showPreferencesOnLaunch"
    }
}

enum Preference {
    
    static var startAtLogin: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.Key.startAtLogin)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.startAtLogin)
            LauncherManager.shared.setupMainApp(isAutoStart: newValue)
        }
    }
    
    static var showPreferencesOnlaunch: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.Key.showPreferencesOnLaunch)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.Key.showPreferencesOnLaunch)
        }
    }
}
