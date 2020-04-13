//
//  Shell.swift
//  Autoasset
//
//  Created by 林翰 on 2020/4/9.
//  Copyright © 2020 linhey.autoasset. All rights reserved.
//

import Foundation
import SwiftShell

@discardableResult
func shell(_ command: String, useAssert: Bool = true) throws -> RunOutput {
    if Autoasset.isDebug {
        RunPrint([String](repeating: "↓", count: 80).joined())
        RunPrint("command: \(command)")
        RunPrint([String](repeating: "-", count: 80).joined())
    }
    let out = run(bash: command)
    if Autoasset.isDebug {
        if out.stdout.isEmpty == false {
            RunPrint("stdout: \(out.stdout)")
        }
        if out.stderror.isEmpty == false {
            RunPrint("stderror: \(out.stderror)")
            if useAssert {
                throw RunError(message: out.stderror)
            } else {
                RunPrint(out.stderror)
            }
        }
        RunPrint([String](repeating: "↑", count: 80).joined())
        RunPrint("\n")
    }
    return out
}