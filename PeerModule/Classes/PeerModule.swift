//
//  PeerModule.swift
//  PeerModule
//
//  Created by Thibault Tourailles on 17/05/2017.
//  Copyright © 2017 Thibault Tourailles. All rights reserved.
//

import Foundation

public protocol PeerModuleDelegate: class {
    func peerModuleHasUpcomingDataAvailable(_ data: Data, from host: String)
    func peerModuleHasDowncomingDataAvailable(_ data: Data, from host: String)
    func peerModuleConnectedToNewClient(_ host: String)
    func peerModuleConnectedToNewServer(_ host: String)
    func peerModuleDisconnectedFromClient(_ host: String)
    func peerModuleDisconnectedFromServer(_ host: String)
}

public class PeerModule: NSObject, UpNodesManagerDelegate, DownNodesManagerDelegate {

    public var port = 1337
    static let bufferSize = 4096

    public weak var delegate: PeerModuleDelegate?

    private let upNodesManager: UpNodesManager
    private var downNodesManager: DownNodesManager

    override public init() {
        upNodesManager = UpNodesManager()
        downNodesManager = DownNodesManager(port: port)
        super.init()

        upNodesManager.delegate = self
        downNodesManager.delegate = self
    }

    //MARK: - Methods

    public func start() {
        downNodesManager = DownNodesManager(port: port)
        downNodesManager.run()
    }

    public func connect(to host: String) {
        upNodesManager.connect(to: host, on: port)
    }

    public func write(_ data: Data) {
        downNodesManager.write(data)
    }

    public func disconnect(client: String) {
        downNodesManager.disconnect(client)
    }

    public func disconnect(source: String) {
        upNodesManager.disconnect(source)
    }

    public func stop() {
        upNodesManager.stop()
        downNodesManager.stop()
    }

    //MARK: - UpNodesManagerDelegate

    func upNodesManagerDidReceiveData(_ data: Data, from host: String) {
        downNodesManager.write(data)
        delegate?.peerModuleHasUpcomingDataAvailable(data, from: host)
    }

    func upNodesManagerDidConnectTo(_ host: String) {
        delegate?.peerModuleConnectedToNewServer(host)
    }

    func upNodesManagerDidDisconnectFrom(_ host: String) {
        delegate?.peerModuleDisconnectedFromServer(host)
    }

    //MARK: - DownNodesManagerDelegate

    func downNodesManagerDidReceiveData(_ data: Data, from host: String) {
        delegate?.peerModuleHasDowncomingDataAvailable(data, from: host)
    }

    func downNodesManagerDidConnectTo(_ host: String) {
        delegate?.peerModuleConnectedToNewClient(host)
    }

    func downNodesManagerDidDisconnectFrom(_ host: String) {
        delegate?.peerModuleDisconnectedFromClient(host)
    }
}
