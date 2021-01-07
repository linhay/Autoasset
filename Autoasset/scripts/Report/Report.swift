//
//  AssetReport.swift
//  Autoasset
//
//  Created by 林翰 on 2021/1/7.
//  Copyright © 2021 linhey.autoasset. All rights reserved.
//

import Foundation
import Stem

class Report {
    
    var rows: [Row] = []
    
    static func read(from path: FilePath) throws -> [Row] {
        return try String(data: path.data(), encoding: .utf8)!
            .components(separatedBy: "\n")
            .map({ $0.components(separatedBy: ",") })
            .dropFirst()
            .map({ row -> Row in
                let result = Row()
                result.variableName     = .init(value: row[0])
                result.outputFolderName = .init(value: row[1])
                result.inputFilesSize   = .init(value: Int(row[2])!)
                result.inputFilesSizeDescription = .init(value: row[3])
                result.outputFolderPath = .init(value: row[4])
                result.inputFilePaths   = .init(value: row[5].components(separatedBy: "|"))
                return result
            })
    }
    
    func write(to path: FilePath) throws {
        var items = [[String]]()
        
        items.append([
            VariableName.name,
            OutputFolderName.name,
            InputFilesSize.name,
            InputFilesSizeDescription.name,
            OutputFolderPath.name,
            InputFilePaths.name,
        ])
        
        items.append(contentsOf: rows.map { item -> [String] in
            return [
                item.variableName.value,
                item.outputFolderName.value,
                item.inputFilesSize.value.description,
                item.inputFilesSizeDescription.value,
                item.outputFolderPath.value,
                item.inputFilePaths.value.joined(separator: "|"),
            ]
        })
        
        let data = items
            .map { $0.joined(separator: ",") }
            .joined(separator: "\n")
            .data(using: .utf8)
        
        try path.create(with: data)
    }
    
    class Row {
        var variableName     = VariableName(value: "")
        var inputFilePaths   = InputFilePaths(value: [])
        var outputFolderName = OutputFolderName(value: "")
        var outputFolderPath = OutputFolderPath(value: "")
        var inputFilesSize   = InputFilesSize(value: 0)
        var inputFilesSizeDescription = InputFilesSizeDescription(value: "")
    }
    
    /// 变量名
    struct VariableName: CSVColumnProtocol {
        static var name: String = "variable_name"
        var value: String
    }
    
    /// 输入的文件,以 | 号分割
    struct InputFilePaths: CSVColumnProtocol {
        static var name: String = "input_file_paths"
        var value: [String]
    }
    
    /// 输出文件夹名
    struct OutputFolderName: CSVColumnProtocol {
        static var name: String = "output_folder_name"
        var value: String
    }
    
    /// 输入的文件总大小
    struct InputFilesSize: CSVColumnProtocol {
        static var name: String = "input_files_size"
        var value: Int
    }
    
    /// 格式化大小
    struct InputFilesSizeDescription: CSVColumnProtocol {
        static var name: String = "input_files_size_description"
        var value: String
    }
    
    /// 输出文件夹路径
    struct OutputFolderPath: CSVColumnProtocol {
        static var name: String = "output_folder_path"
        var value: String
    }
    
}
