//
//  Server.swift
//  PeerModule
//
//  Created by Thibault Tourailles on 11/05/2017.
//  Copyright © 2017 Thibault Tourailles. All rights reserved.
//

import CoreFoundation
import BlueSocket
import Dispatch

protocol DownNodesManagerDelegate: class {
    func downNodesManagerDidConnectTo(_ host: String)
    func downNodesManagerDidDisconnectFrom(_ host: String)
    func downNodesManagerDidReceiveData(_ data: Data, from host: String)
}

class DownNodesManager {

    weak var delegate: DownNodesManagerDelegate?

    private var listenSocket: Socket? = nil
    private var continueRunning = true
    private var clients: [Int32: (address: String, socket: Socket)] = [:]
    private let socketLockQueue = DispatchQueue(label: "com.applidium.peermodule.socketLockQueue")
    private let backgroundQueue = DispatchQueue.global(qos: .background)

    private let port: Int

    deinit {
        stop()
    }

    init(port: Int) {
        self.port = port
    }

    //MARK: - Private

    private func closeSocketConnection(for host: String) {
        guard let entry = clients.first(where: {$0.value.address == host}) else {
            return
        }
        clients[entry.key] = nil
        clients.removeValue(forKey: entry.key)
        entry.value.socket.close()
        delegate?.downNodesManagerDidDisconnectFrom(host)
    }

    private func write(_ data: Data, to host: String, attempt: Int = 1) {
        do {
            guard let socket = clients.first(where: {$0.value.address == host})?.value.socket else {
                return
            }
            try socket.write(from: data)
        } catch let error {
            NSLog("Error writing \(data.debugDescription) to \(host) : \(error.localizedDescription) (\(attempt))")
            guard attempt < 3 else {
                closeSocketConnection(for: host)
                return
            }

            write(data, to: host, attempt: (attempt + 1))
        }
    }

    private func addNewConnection(socket: Socket) {
        socketLockQueue.sync { [unowned self, socket] in
            self.clients[socket.socketfd] = (address: socket.remoteHostname, socket: socket)
            self.delegate?.downNodesManagerDidConnectTo(socket.remoteHostname)
        }

        let queue = DispatchQueue.global(qos: .utility)
        queue.async { [unowned self, socket] in
            var shouldKeepRunning = true
            var data = Data(capacity: PeerModule.bufferSize)
            do {
                repeat {
                    let bytesRead = try socket.read(into: &data)
                    if bytesRead > 0 {
                        self.delegate?.downNodesManagerDidReceiveData(data, from: socket.remoteHostname)
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

    //MARK: - Methods

    func run() {
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                // Create an IPV6 socket...
                NSLog("Starting server on port \(self.port)")
                try self.listenSocket = Socket.create(family: .inet)
                guard let socket = self.listenSocket else {
                    print("Unable to unwrap socket...")
                    return
                }
                try socket.listen(on: self.port)
                NSLog("Server started")
                repeat {
                    let newSocket = try socket.acceptClientConnection()
                    self.addNewConnection(socket: newSocket)
                } while self.continueRunning

            } catch let error {
                guard let socketError = error as? Socket.Error else {
                    NSLog("Fail to start server")
                    print("Unexpected error...")
                    return
                }

                if self.continueRunning {
                    print("Error reported:\n \(socketError.description)")
                }
            }
        }
    }

    func disconnect(_ host: String) {
        closeSocketConnection(for: host)
    }

    func write(_ data: Data, attempt: Int = 1) {
        guard clients.count > 0 else {
            return
        }
        backgroundQueue.async {
            for value in self.clients.values {
                self.write(data, to: value.address)
            }
        }

    }

    func stop() {
        continueRunning = false
        for value in clients.values {
            closeSocketConnection(for: value.address)
        }
        listenSocket?.close()
    }
}
