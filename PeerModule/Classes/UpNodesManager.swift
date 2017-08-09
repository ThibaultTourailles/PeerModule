//
//  Source.swift
//  PeerModule
//
//  Created by Thibault Tourailles on 17/05/2017.
//  Copyright © 2017 Thibault Tourailles. All rights reserved.
//

import CoreFoundation
import BlueSocket
import Dispatch

protocol UpNodesManagerDelegate: class {
    func upNodesManagerDidConnectTo(_ host: String)
    func upNodesManagerDidDisconnectFrom(_ host: String)
    func upNodesManagerDidReceiveData(_ data: Data, from host: String)
}

class UpNodesManager {

    weak var delegate: UpNodesManagerDelegate?

    private var continueRunning = true
    private var sources: [Int32: (address: String, socket: Socket)] = [:]
    private let socketLockQueue = DispatchQueue(label: "com.applidium.peermodule.socketLockQueue")
    private let backgroundQueue = DispatchQueue.global(qos: .background)

    deinit {
        stop()
    }

    //MARK: - Private

    private func closeSocketConnection(for host: String) {
        guard let entry = sources.first(where: {$0.value.address == host}) else {
            return
        }
        sources[entry.key] = nil
        sources.removeValue(forKey: entry.key)
        entry.value.socket.close()
        delegate?.upNodesManagerDidDisconnectFrom(host)
    }

    //MARK: - Methods

    func connect(to host: String, on port: Int) {
        backgroundQueue.async {
            do {
                let socket = try Socket.create()
                NSLog("Trying to connect to \(host) on \(port)")
                try socket.connect(to: host, port: Int32(port))
                NSLog("Connected")
                self.addNewConnection(socket: socket)
            } catch let error {
                guard let socketError = error as? Socket.Error else {
                    NSLog("Impossible to connect")
                    NSLog("Unexpected error...")
                    return
                }

                if self.continueRunning {
                    NSLog("Error reported:\n \(socketError.description)")
                }
            }
        }
    }

    func addNewConnection(socket: Socket) {

        socketLockQueue.sync { [unowned self, socket] in
            self.sources[socket.socketfd] = (address: socket.remoteHostname, socket: socket)
            self.delegate?.upNodesManagerDidConnectTo(socket.remoteHostname)
        }

        let queue = DispatchQueue.global(qos: .utility)
        queue.async { [unowned self, socket] in
            var shouldKeepRunning = true
            var data = Data(capacity: PeerModule.bufferSize)
            do {
                repeat {
                    let bytesRead = try socket.read(into: &data)
                    guard bytesRead > 0 else {
                        shouldKeepRunning = false
                        break
                    }
                    if bytesRead > 0 {
                        self.delegate?.upNodesManagerDidReceiveData(data, from: socket.remoteHostname)
                        data.count = 0
                    }

                    if bytesRead == 0 {
                        shouldKeepRunning = false
                        break
                    }
                } while shouldKeepRunning
                self.closeSocketConnection(for: socket.remoteHostname)
            } catch let error {
                guard let socketError = error as? Socket.Error else {
                    NSLog("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    NSLog("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }

    func disconnect(_ host: String) {
        closeSocketConnection(for: host)
    }

    func stop() {
        continueRunning = false
        for value in sources.values {
            closeSocketConnection(for: value.address)
        }
    }
}
