//
//  AppDelegate.swift
//  DNDLauncher
//
//  Created by phucld on 5/21/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LauncherManager.shared.setupLauncher()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

