//
//  CallingChecker.swift
//  dnd
//
//  Created by phucld on 4/21/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import ServiceManagement

extension NSNotification.Name {
    static let installedHelper = NSNotification.Name("installedHelper")
}

class CallingChecker {
    
    var statusDidChanged: ((String) -> Void)?

    private var status = ""
    private let helperVersion = "1.0.3"
    
    func installIfNeeded() {
        connectToHelper { [weak self] isSuccess in
            if isSuccess {
                self?.startChecking()
                return
            }
            
            self?.install(then: nil)
            
            self?.connectToHelper { isSuccess in
                if isSuccess {
                    self?.sendEventInstallSuccess()
                    NSLog("Installed")
                    self?.startChecking()
                } else {
                    NSLog("Could not install helper")
                }
            }
            
        }
    }
    
    private func sendEventInstallSuccess() {
        NotificationCenter.default.post(name: .installedHelper, object: nil)
    }
    
    func connectToHelper(callback: @escaping (Bool) -> Void) {
        let connection = NSXPCConnection(machServiceName: kServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: dndHelperProtocol.self)
        
        connection.invalidationHandler = { NSLog("Connection did invalidate") }
        connection.interruptionHandler = { NSLog("Connection did interrupt") }
        
        connection.resume()
        
        let helper = connection.remoteObjectProxyWithErrorHandler { error in
            NSLog(error.localizedDescription)
            callback(false)
            } as? dndHelperProtocol
        
        helper?.getVersion { [weak self] version in
            NSLog(version)
            callback(version == self?.helperVersion)
        }
    }
    
    func install(then: (() -> Void)?) {
        var authref: AuthorizationRef? = nil
        
        var item = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var rights = AuthorizationRights(count: 1, items: &item)
        let flags = AuthorizationFlags([.interactionAllowed, .extendRights, .preAuthorize])
        
        let status = AuthorizationCreate(&rights, nil, flags, &authref)
        var error = NSError(domain: NSOSStatusErrorDomain, code: 0, userInfo: nil)
        
        if status != errAuthorizationSuccess {
            error = NSError(domain:NSOSStatusErrorDomain, code:Int(status), userInfo:nil)
            NSLog("Authorization error: \(error)")
            return
        }
        
        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(kSMDomainSystemLaunchd, kServiceName as CFString, authref, &cfError)
        if success {
            NSLog("SMJobBless suceeded")
            then?()
        } else {
            NSLog("SMJobBless failed: \(cfError!)")
        }
    }
    
    @objc
    private func check() {
        // Setup for outgoing connection
        let connection = NSXPCConnection(machServiceName: kServiceName, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: dndHelperProtocol.self)
        
        connection.invalidationHandler = { NSLog("Connection did invalidate") }
        connection.interruptionHandler = { NSLog("Connection did interrupt") }
        
        connection.resume()
        
        let helper = connection.remoteObjectProxyWithErrorHandler({ (error) in
            NSLog("Error: description: \(error as NSError)")
        }) as? dndHelperProtocol
        
        helper?.getDecision(scriptPath: "/usr/local/bin/dnd") { status in
            self.receive(status: status)
        }
    }
    
    func startChecking() {
        check()
        
        // Check every 30s
        let ncTimer = Timer(timeInterval: 30.0, target: self, selector: #selector(self.check), userInfo: nil, repeats: true)
        RunLoop.main.add(ncTimer, forMode: RunLoop.Mode.common)
    }
    
    private func receive(status: String) {
        
        let newStatus = status.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard newStatus != self.status else {return}
        
        self.status = newStatus
        
        self.statusDidChanged?(newStatus)
    }
}
