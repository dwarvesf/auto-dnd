//
//  callingChecker.swift
//  foundation.dwarves.dnd.callingChecker
//
//  Created by phucld on 4/16/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation
import Cocoa

class CallingChecker: NSObject, dndHelperProtocol {
    private var listener: NSXPCListener
    
    private var shouldQuit = false
    private var shouldQuitCheckInterval = 1.0
    
    override init() {
        // Set up our XPC listener to handle requests on our Mach service.
        self.listener = NSXPCListener(machServiceName: kServiceName)
        super.init()
        self.listener.delegate = self
    }
    
    func run() {
        // Tell the XPC listener to start processing requests.
        // Resume the listener. At this point, NSXPCListener will take over the execution of this service, managing its lifetime as needed.
        self.listener.resume()
        
        // Run the run loop forever.
        while !self.shouldQuit {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: self.shouldQuitCheckInterval))
        }
    }
    
    func getVersion(with reply: @escaping replyBlock) {
        reply(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String)
    }
    
    func getDecision(scriptPath: String, with reply: @escaping replyBlock) {
        
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = [scriptPath]
        let pipe = Pipe()
        task.standardOutput = pipe
        
        let outHandle = pipe.fileHandleForReading
        
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                // Update your view with the new text here
                reply(line)
            } else {
                NSLog("Error decoding data: \(pipe.availableData)")
            }
        }
        
        if #available(OSX 10.13, *) {
            try? task.run()
        } else {
            task.launch()
        }
        
        task.waitUntilExit()
        
    }
}

extension CallingChecker: NSXPCListenerDelegate {
    // Called by our XPC listener when a new connection comes in.  We configure the connection
    // with our protocol and ourselves as the main object.
    func listener(_ listener:NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        // Setup income connection
        newConnection.exportedInterface = NSXPCInterface(with: dndHelperProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.invalidationHandler = { NSLog("Connection did invalidate") }
        newConnection.interruptionHandler = {
            NSLog("Connection did interrupt")
            self.shouldQuit = true
        }
        
        newConnection.resume()
        
        return true
    }
}

