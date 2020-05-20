//
//  GeneralPreferenceViewController.swift
//  MicMonitor
//
//  Created by phucld on 2/28/20.
//  Copyright © 2020 Dwarvesf. All rights reserved.
//

import Cocoa
import Preferences

final class GeneralPreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.general
    let preferencePaneTitle = "General"
    let toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!
    
    override var nibName: NSNib.Name? { "GeneralPreferenceViewController" }
    
    @IBOutlet weak var checkboxStartAtLogin: NSButton!
    @IBOutlet weak var checkboxShowPreferencesOnLaunch: NSButton!
    @IBOutlet weak var btnInstallHelper: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPreferenes()
        checkInstallHelperStatus()
        observeEvents()
    }
    
    private func observeEvents() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateInstallHelperButton), name: .installedHelper, object: nil)
    }
    
    @objc
    private func updateInstallHelperButton() {
        DispatchQueue.main.async {
            self.btnInstallHelper.title = "Helper installed ✓"
            self.btnInstallHelper.isEnabled = false
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func checkInstallHelperStatus() {
        AppDelegate.shared.callingChecker.connectToHelper { isSuccess in
            let btnTitle = isSuccess ? "Helper installed ✓" : "Install Helper"
            
            DispatchQueue.main.async {
                self.btnInstallHelper.title = btnTitle
                self.btnInstallHelper.isEnabled = !isSuccess
            }
        }
    }
    
    private func fetchPreferenes() {
        checkboxStartAtLogin.state = Preference.startAtLogin ? .on : .off
        checkboxShowPreferencesOnLaunch.state = Preference.showPreferencesOnlaunch ? .on : .off
    }
    
    @IBAction func toggleStartAtLogin(_ sender: NSButton) {
        switch sender.state {
        case .on:
            Preference.startAtLogin = true
        case .off:
            Preference.startAtLogin = false
        default:
            break
        }
    }
    
    @IBAction func toggleShowPreferencesOnLaunch(_ sender: NSButton) {
        switch sender.state {
        case .on:
            Preference.showPreferencesOnlaunch = true
        case .off:
            Preference.showPreferencesOnlaunch = false
        default:
            break
        }
    }
    
    @IBAction func installHelper(_ sender: Any) {
        AppDelegate.shared.callingChecker.installIfNeeded()
    }
}
