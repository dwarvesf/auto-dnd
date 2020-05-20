//
//  WelcomeViewController.swift
//  Readify
//
//  Created by phucld on 4/7/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Cocoa
import SafariServices

class WelcomeViewController: NSViewController, PageViewControllerDelegate {
    
    fileprivate weak var pageViewController: PageViewController?
    
    @IBOutlet weak var btnInstallHelper: NSButton! {
        didSet {
            btnInstallHelper.isHidden = true
        }
    }
    
    @IBOutlet weak var btnClose: NSButton! {
        didSet {
            btnClose.isHidden = true
        }
    }
    
    // MARK: - NSViewController
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let pageViewController = segue.destinationController as? PageViewController else { return }
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        pageViewController.loadViewControllers(["1", "2", "3"], from: storyboard)
        pageViewController.delegate = self
        pageViewController.tintColor = NSColor.textColor
        self.pageViewController = pageViewController
    }
    
    
    @IBAction func installHelper(_ sender: Any) {
        AppDelegate.shared.callingChecker.install {
            self.pageViewController?.navigateForward()
            NSApp.activate(ignoringOtherApps: true)
            AppDelegate.shared.callingChecker.startChecking()
        }
    }
    
    @IBAction func closeWindow(_ sender: Any) {
        self.view.window?.close()
    }
    
    func pageViewController(_ pageViewController: PageViewController, didSelectPage pageIndex: Int) {
        btnInstallHelper.isHidden = pageIndex == 0 || pageIndex == 2
        btnClose.isHidden = pageIndex == 0 || pageIndex == 1
        
        pageViewController.showArrowControls = pageIndex == 0
        pageViewController.showPageControl = pageIndex == 0
    }
}

