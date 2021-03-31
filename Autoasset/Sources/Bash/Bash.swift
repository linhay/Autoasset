//
//  File.swift
//  
//
//  Created by 林翰 on 2021/3/31.
//

import Foundation
import Logging
import SwiftShell
import ASError

@discardableResult
public func shell(_ command: String, logger: Logger?) throws -> String {
    logger?.info(.init(stringLiteral: command))
    let output = SwiftShell.run(bash: command)
    if output.succeeded {
        logger?.info(.init(stringLiteral: output.stdout))
        return output.stdout
    } else {
        logger?.error(.init(stringLiteral: command))
        logger?.error(.init(stringLiteral: output.stderror))
        throw ASError(message: output.error?.description ?? output.stderror)
    }
}
