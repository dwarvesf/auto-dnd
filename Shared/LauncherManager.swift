//
//  LauncherManager.swift
//  dnd
//
//  Created by phucld on 5/21/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa
import ServiceManagement

/// This class will help launch main app at login
class LauncherManager {
    static let shared = LauncherManager()
    
    private let mainAppID = "foundation.dwarves.dnd"
    private let launcherAppID = "foundation.dwarves.DNDLauncher"
    
    private let appName = "Auto DND"
    private let killLaunchNtfName = Notification.Name("killLauncher")
    
    private init() {}
    
    func setupMainApp(isAutoStart: Bool) {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppID }.isEmpty
        
        SMLoginItemSetEnabled(launcherAppID as CFString, isAutoStart)
        
        if isRunning {
            DistributedNotificationCenter.default().post(name: killLaunchNtfName,
                                                         object: Bundle.main.bundleIdentifier!)
        }
    }
    
    func setupLauncher() {
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppID }.isEmpty
        
        guard !isRunning else {
            self.terminate()
            return
        }
        
        DistributedNotificationCenter.default().addObserver(self,
                                                            selector: #selector(self.terminate),
                                                            name: killLaunchNtfName,
                                                            object: mainAppID)
        
        // Getting path to main app
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        components.removeLast(3)
        components.append("MacOS")
        components.append(appName)
        let newPath = NSString.path(withComponents: components)
        NSWorkspace.shared.launchApplication(newPath)
        
        
    }
    
    @objc private func terminate() {
        NSApp.terminate(nil)
    }
}
