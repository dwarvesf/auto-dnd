//
//  WelcomeWindowController.swift
//  Readify
//
//  Created by phucld on 4/7/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa

class WelcomeWindowController: NSWindowController {
    
    static var shared: WelcomeWindowController = {
        let windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "welcome")
        return windowController as! WelcomeWindowController
    }()

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
