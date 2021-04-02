// MIT License
//
// Copyright (c) 2020 linhey
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import AutoassetModels
import StemCrossPlatform
import Logging
import VariablesMaker
import ASError

public struct TidyController {
    
    private let logger = Logger(label: "tidy")
    
    private let tidy: Tidy
    private let variablesMaker: VariablesMaker
    
    public init(tidy: Tidy, variables: Variables) {
        self.tidy = tidy
        self.variablesMaker = VariablesMaker(variables)
    }
    
    public func run(name: String) throws {
        try clearTask(name)
        try copyTask(name)
        try createTask(name)
    }
    
}

extension TidyController {
    
    func createTask(_ name: String) throws {
        guard let item = tidy.create.first(where: { $0.name == name }) else {
            return
        }
        
        var type: Tidy.CreateInput
        switch item.type {
        case .input(let result):
            type = .input(try variablesMaker.textMaker(result))
        case .text(let result):
            type = .text(try variablesMaker.textMaker(result))
        }
        
        let model = try Tidy.Create(name: name,
                                    type: type,
                                    output: variablesMaker.textMaker(item.output))
        
        var text: String
        switch model.type {
        case .input(let path):
            let input = try FilePath(path: path, type: .file).data()
            text = String(data: input, encoding: .utf8) ?? ""
        case .text(let result):
            text = result
        }
        
        text = try variablesMaker.textMaker(text)
        let output = try FilePath(path: model.output, type: .file)
        try? output.delete()
        logger.info(.init(stringLiteral: "正在创建: \(model.output)"))
        try output.create(with: text.data(using: .utf8))
    }
    
    func clearTask(_ name: String) throws {
        guard let item = tidy.clears.first(where: { $0.name == name }) else {
            return
        }
        
        let model = try Tidy.Clear(name: name, inputs: item.inputs.map(variablesMaker.textMaker(_:)))
        
        for input in model.inputs {
            do {
                logger.info("正在移除: \(input)")
                try FilePath(path: input).delete()
            } catch {
                logger.error(.init(stringLiteral: error.localizedDescription))
            }
        }
    }
    
    func copyTask(_ name: String) throws {
        guard let item = tidy.copies.first(where: { $0.name == name }) else {
            return
        }
        
        let model = try Tidy.Copy(name: name,
                                  inputs: item.inputs.map(variablesMaker.textMaker(_:)),
                                  output: variablesMaker.textMaker(item.output))

        
        let output = try FilePath(path: model.output, type: .folder)
        
        for input in model.inputs.compactMap({ try? FilePath(path: $0) }) {
            logger.info("正在复制: \(output.path)")
            try input.copy(to: output)
        }
        
    }
    
}
