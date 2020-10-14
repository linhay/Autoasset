//
//  Autoasset.swift
//  Autoasset
//
//  Created by 林翰 on 2020/4/7.
//  Copyright © 2020 linhey.autoasset. All rights reserved.
//

import Foundation
import Stem

class Autoasset {

    var config: Config

    init(config: Config) throws {
        self.config = config
    }

    func start() throws {
        do {
            try start(with: config.mode.types)
        } catch {
            try Warn.output(config: config.warn)
            try Message(config: config.message)?.output(error: error.localizedDescription)
            throw error
        }
    }

}

private extension Autoasset {

    func start(with type: ModeModel.Style) throws {
        switch type {
        case .pod_with_branch:
            let git = Git()
            try Asset(config: config.asset).run()
            let name = try git.branch.currentName()
            try start(with: .test_podspec)
            try pushToGit(git)
            try Warn.output(config: config.warn)
            try Message(config: config.message)?.output(version: config.mode.variables.version, branch: name)
        case .test_warn:
            Warn.test()
            try Warn.output(config: config.warn)
        case .test_message:
            try Message(config: config.message)?.output(version: config.mode.variables.version, branch: "test")
        case .test_podspec:
            guard let podspec = Podspec(config: config.podspec) else {
                return
            }
            try podspec.version()
            try podspec.output(version: config.mode.variables.version)
            try podspec.lint()
        case .local:
            try Asset(config: config.asset).run()
            try Warn.output(config: config.warn)
        case .normal_without_git_push:
            try normal_without_git_push()
        case .test_config:
            break
        case .normal:
            try normalMode()
        }
    }

    func start(with types: [ModeModel.Style]) throws {
        for type in types {
            RunPrint.create(title: "mode type: \(type) ")
            try start(with: type)
        }
    }

    func commitMessage() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "[ci skip] author: autoasset(\(Env.version)), date: \(dateFormatter.string(from: Date()))"
    }

    func pushToGit(_ git: Git) throws {
        try git.addAllFile(path: try git.rootPath())
        try git.commit(message: commitMessage())
        try git.push()
    }

    func normal_without_git_push() throws {
        let podspec = Podspec(config: config.podspec)
        let git = Git()

        guard try git.isInsideWorkTree() else {
            Warn.init("模式 'normal' 需要在 git 仓库中才能执行")
            return
        }

        /// 下载目标文件
        try FilePath(path: GitModel.Clone.output, type: .folder).delete()
        try config.git.inputs.forEach { item in
            try item.branchs.forEach { branch in
                try git.clone.get(url: item.url, branch: branch, to: item.folder(for: branch))
            }
        }

        try Asset(config: config.asset).run()
        try FilePath(path: GitModel.Clone.output, type: .folder).delete()

        let lastVersion = try? git.tag.lastVersion() ?? config.mode.variables.version
        let version = try git.tag.nextVersion(with: lastVersion ?? config.mode.variables.version)
        try podspec?.output(version: version)
        try podspec?.lint()
    }

    func normalMode() throws {
        let podspec = Podspec(config: config.podspec)
        let git = Git()

        guard try git.isInsideWorkTree() else {
            Warn.init("模式 'normal' 需要在 git 仓库中才能执行")
            return
        }

        /// 下载目标文件
        try FilePath(path: GitModel.Clone.output, type: .folder).delete()
        try config.git.inputs.forEach { item in
            try item.branchs.forEach { branch in
                try git.clone.get(url: item.url, branch: branch, to: item.folder(for: branch))
            }
        }

        try Asset(config: config.asset).run()
        try FilePath(path: GitModel.Clone.output, type: .folder).delete()

        let lastVersion = try? git.tag.lastVersion() ?? config.mode.variables.version
        let version = try git.tag.nextVersion(with: lastVersion ?? config.mode.variables.version)
        try podspec?.output(version: version)
        try podspec?.lint()

        do {
            try pushToGit(git)
        } catch { }

        do {
            try git.tag.remove(version: version)
        } catch { }

        do {
            try git.tag.add(version: version, message: commitMessage())
        } catch { }

        do {
            try git.tag.push(version: version)
        } catch { }

        try podspec?.push()

        try Warn.output(config: config.warn)
        try Message(config: config.message)?.output(version: version, branch: version)
    }

}
