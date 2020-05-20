//
//  AboutPreferenceViewController.swift
//  MicMonitor
//
//  Created by phucld on 2/28/20.
//  Copyright © 2020 Dwarvesf. All rights reserved.
//

import Cocoa
import Preferences

final class AboutPreferenceViewController: NSViewController, PreferencePane {
    let preferencePaneIdentifier = PreferencePane.Identifier.about
    let preferencePaneTitle = "About"
    let toolbarItemIcon = NSImage(named: NSImage.infoName)!
    
    override var nibName: NSNib.Name? { "AboutPreferenceViewController" }
    
    @IBOutlet weak var lblVersion: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()        
    }
    
    private func setupUI() {
        lblVersion.stringValue += " \(App.versionWithBuild)"
    }
}
