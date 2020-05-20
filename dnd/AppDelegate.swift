//
//  AppDelegate.swift
//  dnd
//
//  Created by phucld on 4/15/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa
import ServiceManagement
import AVFoundation
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes
import Preferences
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    lazy private var preferencesWindowController = PreferencesWindowController(
        preferencePanes: [
            GeneralPreferenceViewController(),
            AboutPreferenceViewController()
        ],
        style: .segmentedControl
    )
    
    lazy var callingChecker: CallingChecker = {
        let callChecker = CallingChecker()
        callChecker.statusDidChanged = { status in
            switch status {
            case "IDLE": DNDManager.shared.turnDNDOff()
            case "CALLING": DNDManager.shared.turnDNDOn()
            default: break
            }
            
        }
        return callChecker
    }()
    
    lazy var menuStatusItem: NSStatusItem = {
        let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = #imageLiteral(resourceName: "ico_menubar")
        }
        statusItem.menu = self.createMenu()
        return statusItem
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        registerDefaultValues()
        
        setupAutoStart()
        
        initShellScript()
        
        _ = menuStatusItem

        showPreferencesScreenIfNeeded()
        
        showWelcomeScreenIfNeeded()
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func setupMSAppCenter() {
        MSAppCenter.start("7863b81e-6e22-496a-b5a8-9924dd04502f", withServices:[
            MSAnalytics.self,
            MSCrashes.self
        ])
    }
    
    func setupAutoStart() {
        LauncherManager.shared.setupMainApp(isAutoStart: Preference.startAtLogin)

    }
    
    func showPreferencesScreenIfNeeded() {
        if Preference.showPreferencesOnlaunch {
            preferencesWindowController.show()
        }
    }
    
    func registerDefaultValues() {
        UserDefaults.standard.register(defaults: [
            UserDefaults.Key.startAtLogin: true,
            UserDefaults.Key.showPreferencesOnLaunch: true,
        ])
    }
    
    func showWelcomeScreenIfNeeded() {
        guard App.isFirstLaunch else {
            callingChecker.installIfNeeded()
            return
        }
        
        WelcomeWindowController.shared.showWindow(self)
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: "DND is running", action: nil, keyEquivalent: "")
        
        menu.addItem(.separator())
        
        menu.addItem(withTitle: "Check for Updates...", action: #selector(SUUpdater.checkForUpdates(_:)), keyEquivalent: "u").target = SUUpdater.shared()
        
        menu.addItem(withTitle: "Preferences", action: #selector(showPreferences), keyEquivalent: "p").target = self
        menu.addItem(withTitle: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        return menu
    }
    
    @objc func showPreferences() {
        preferencesWindowController.show()
    }
    
    func initShellScript() {
        let shell = """
           #!/bin/bash
           mkdir -p ~/dnd

           ports=(22466 22467)
           portRanges=(3478-3481 8801-8810 19302-19309)

           flag="IDLE"
           for p in "${ports[@]}"; do
               sudo tcpdump -G 2 -s 0 -tttt -nn port ${p} and udp -W 1 -w ~/dnd/${p}.pcap > /dev/null 2>&1
               size=$(du ~/dnd/${p}.pcap | awk '{print $1}')
               if [ ! ${size} = 0 ]; then
                   flag="CALLING"
                   break
               fi
           done;
           for p in "${portRanges[@]}"; do
               if [ ${flag} = "CALLING" ] ; then
                   break
               fi
               sudo tcpdump -G 2 -s 0 -tttt -nn portrange ${p} and udp -W 1 -w ~/dnd/${p}.pcap > /dev/null 2>&1
               size=$(du ~/dnd/${p}.pcap | awk '{print $1}')
               if [ ! ${size} = 0 ]; then
                   flag="CALLING"
                   break
               fi
           done;
           echo ${flag}

           """
        
        guard let directoryURL = URL(string: "file:///usr/local/bin") else {
            NSLog("directory format is wrong")
            return
        }
        
        let fileURL = directoryURL.appendingPathComponent("dnd", isDirectory: false)
        do {
            try shell.data(using: .utf8)?.write(to: fileURL)
        } catch {
            NSLog("Cannot create new file")
        }
        
        print("Init file success")
    }
    
}

