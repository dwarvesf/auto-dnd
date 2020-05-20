
//
//  dndHelperProtocol.swift
//  dnd
//
//  Created by phucld on 4/15/20.
//  Copyright © 2020 Dwarves Foundation. All rights reserved.
//

import Foundation

let kServiceName = "foundation.dwarves.dnd.callingChecker"

typealias replyBlock = (String) -> ()

@objc protocol dndHelperProtocol {
    func getVersion(with reply: @escaping replyBlock)
    func getDecision(scriptPath: String, with reply: @escaping replyBlock)
}
