import Foundation
import Network

// MARK: - State Management

extension NetworkHealthCoordinator {

    // MARK: - Path Monitoring

    internal func observePathChanges() async {
        for await path in await networkMonitor.pathUpdates() {
            handlePathUpdate(path)
        }
    }

    internal func handlePathUpdate(_ path: NWPath) {
        let newConnectionType = qualityEvaluator.determineConnectionType(from: path)
        let previousConnectionType = state.connectionType
        let isExpensive = path.isExpensive

        currentPath = path

        // Connection type changed - reset measurements
        if newConnectionType != previousConnectionType {
            cancelSpeedMeasurement()
            verificationTask?.cancel()
            verificationTask = nil
            measuredQuality = nil
            lastSpeedMeasurementDate = nil
        }

        let pathQuality = qualityEvaluator.qualityFromPath(path)

        if pathQuality == .offline {
            measuredQuality = nil
            cancelSpeedMeasurement()
            verificationTask?.cancel()
            verificationTask = nil
            lastSpeedMeasurementDate = nil
        } else if pathQuality != .offline && pathQuality != .poor {
            // Good path quality - schedule speed measurement if configured
            scheduleSpeedMeasurement(force: false, connectionType: newConnectionType)
        } else {
            // Poor connection according to the system — avoid additional measurements
            cancelSpeedMeasurement()
            measuredQuality = nil
        }

        updateState(connectionType: newConnectionType, isExpensive: isExpensive)
    }

    // MARK: - Continuations Management

    internal func registerContinuation(_ continuation: AsyncStream<State>.Continuation) {
        let identifier = UUID()
        continuations[identifier] = continuation
        continuation.onTermination = { @Sendable [weak self] _ in
            guard let self else { return }
            Task { await self.removeContinuation(with: identifier) }
        }
        continuation.yield(state)
    }

    internal func removeContinuation(with identifier: UUID) {
        continuations.removeValue(forKey: identifier)
    }

    internal func finishContinuations() {
        for continuation in continuations.values {
            continuation.finish()
        }
        continuations.removeAll()
    }

    internal func notifyContinuations(with newState: State) {
        for continuation in continuations.values {
            continuation.yield(newState)
        }
    }

    // MARK: - State Updates

    internal func updateState(connectionType: ConnectionRawData? = nil, isExpensive: Bool? = nil) {
        let updatedConnectionType = connectionType ?? state.connectionType
        let updatedQuality = effectiveQuality(for: updatedConnectionType)
        let updatedIsExpensive = isExpensive ?? state.isExpensive

        let updatedState = State(
            connectionType: updatedConnectionType,
            quality: updatedQuality,
            isExpensive: updatedIsExpensive
        )
        guard updatedState != state else { return }
        state = updatedState
        notifyContinuations(with: updatedState)

        // Store snapshot in history if auto-store is enabled
        if configuration.autoStoreSnapshots {
            let snapshot = createSnapshot(from: updatedState)
            Task {
                await measurementHistory.add(snapshot)
            }
        }
    }

    internal func createSnapshot(from state: State) -> NetworkQualitySnapshot {
        return NetworkQualitySnapshot(
            timestamp: dateProvider(),
            connectionType: state.connectionType,
            isExpensive: state.isExpensive,
            quality: state.quality,
            latency: measuredQuality?.latency,
            downloadSpeedMbps: measuredQuality?.downloadSpeedMbps,
            uploadSpeedMbps: measuredQuality?.uploadSpeedMbps,
            bytesDownloaded: nil,
            bytesUploaded: nil,
            downloadDuration: nil,
            uploadDuration: nil
        )
    }

    internal func effectiveQuality(for connectionType: ConnectionRawData, shouldCleanupStale: Bool = true) -> NetworkQuality {
        guard let path = currentPath else { return .offline }

        // Use evaluator to compute quality, considering measurements if available
        let quality = qualityEvaluator.evaluate(
            path: path,
            connectionType: connectionType,
            measurements: measuredQuality
        )

        // Check if measurements are stale
        if measuredQuality != nil,
           let lastMeasurement = lastSpeedMeasurementDate,
           shouldCleanupStale {
            let measurementAge = dateProvider().timeIntervalSince(lastMeasurement)
            if measurementAge >= configuration.minimumSpeedCheckInterval {
                // Measurements are stale - clean up and re-evaluate
                measuredQuality = nil
                verificationTask?.cancel()
                verificationTask = nil

                // Schedule async state update
                Task { [weak self] in
                    guard let self else { return }
                    await self.updateStateAfterStaleCleanup()
                }
            }
        }

        return quality
    }

    /// Updates state after cleaning up stale measurements
    internal func updateStateAfterStaleCleanup() {
        guard let path = currentPath else { return }

        // Re-evaluate without measurements
        let quality = qualityEvaluator.evaluate(
            path: path,
            connectionType: state.connectionType,
            measurements: nil
        )

        let updatedState = State(
            connectionType: state.connectionType,
            quality: quality,
            isExpensive: state.isExpensive
        )

        guard updatedState != state else { return }
        state = updatedState
        notifyContinuations(with: updatedState)

        // Store snapshot in history if auto-store is enabled
        if configuration.autoStoreSnapshots {
            let snapshot = createSnapshot(from: updatedState)
            Task {
                await measurementHistory.add(snapshot)
            }
        }
    }
}
