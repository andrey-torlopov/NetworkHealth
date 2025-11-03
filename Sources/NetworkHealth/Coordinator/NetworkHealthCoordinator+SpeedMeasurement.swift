import Foundation
import Network

// MARK: - Speed Measurement

extension NetworkHealthCoordinator {

    /// Forces an immediate quality refresh by performing a speed test, ignoring the throttling interval.
    ///
    /// If a speed tester was configured, this method triggers an immediate measurement and updates
    /// the quality assessment based on the results. If no speed tester is configured, this method
    /// resets any cached measurements and re-evaluates quality based on connection type only.
    ///
    /// This is useful when you want to get fresh quality data immediately without waiting for
    /// the next scheduled measurement.
    public func refreshQuality() {
        guard let path = currentPath, path.status == .satisfied else { return }
        measuredQuality = nil
        scheduleSpeedMeasurement(force: true, connectionType: state.connectionType)
    }

    /// Performs a detailed speed measurement and returns the snapshot
    /// This method bypasses throttling and always performs a fresh measurement
    /// This is designed for manual/on-demand measurements and does NOT affect the automatic quality state
    /// - Returns: NetworkQualitySnapshot with detailed metrics if measurement succeeds
    /// - Throws: NetworkQualityError if measurement fails
    public func performDetailedMeasurement() async throws -> NetworkQualitySnapshot {
        guard let speedTester = configuration.speedTester else {
            throw NetworkQualityError.speedTesterNotConfigured
        }

        guard let path = currentPath, path.status == .satisfied else {
            throw NetworkQualityError.offline
        }

        // If the speed tester supports detailed measurements, use it
        if let detailedTester = speedTester as? any DetailedSpeedTester {
            do {
                let detailed = try await detailedTester.measureSpeedDetailed()

                // Determine quality from measurements
                let qualityFromMeasurement = NetworkQuality.from(
                    latency: detailed.latency,
                    downloadSpeedMbps: detailed.downloadSpeedMbps,
                    uploadSpeedMbps: detailed.uploadSpeedMbps
                )

                // Create snapshot directly without affecting the automatic state
                let snapshot = NetworkQualitySnapshot(
                    timestamp: dateProvider(),
                    connectionType: state.connectionType,
                    isExpensive: state.isExpensive,
                    quality: qualityFromMeasurement,
                    latency: detailed.latency,
                    downloadSpeedMbps: detailed.downloadSpeedMbps,
                    uploadSpeedMbps: detailed.uploadSpeedMbps,
                    bytesDownloaded: detailed.bytesDownloaded,
                    bytesUploaded: detailed.bytesUploaded,
                    downloadDuration: detailed.downloadDuration,
                    uploadDuration: detailed.uploadDuration
                )

                // Store in history if enabled
                if configuration.autoStoreSnapshots {
                    await measurementHistory.add(snapshot)
                }

                return snapshot
            } catch {
                throw NetworkQualityError.measurementFailed(error)
            }
        } else {
            // Standard measurement
            do {
                let result = try await speedTester.measureSpeed()

                // Determine quality from measurements
                let qualityFromMeasurement = NetworkQuality.from(
                    latency: result.latency,
                    downloadSpeedMbps: result.downloadSpeedMbps,
                    uploadSpeedMbps: result.uploadSpeedMbps
                )

                // Create snapshot directly without affecting the automatic state
                let snapshot = NetworkQualitySnapshot(
                    timestamp: dateProvider(),
                    connectionType: state.connectionType,
                    isExpensive: state.isExpensive,
                    quality: qualityFromMeasurement,
                    latency: result.latency,
                    downloadSpeedMbps: result.downloadSpeedMbps,
                    uploadSpeedMbps: result.uploadSpeedMbps,
                    bytesDownloaded: nil,
                    bytesUploaded: nil,
                    downloadDuration: nil,
                    uploadDuration: nil
                )

                // Store in history if enabled
                if configuration.autoStoreSnapshots {
                    await measurementHistory.add(snapshot)
                }

                return snapshot
            } catch {
                throw NetworkQualityError.measurementFailed(error)
            }
        }
    }

    // MARK: - Internal Helpers

    internal func scheduleSpeedMeasurement(force: Bool, connectionType: ConnectionRawData) {
        guard let speedTester = configuration.speedTester else { return }
        guard connectionType.supportsActiveMeasurements else { return }

        if !force {
            if let lastCheck = lastSpeedMeasurementDate,
               dateProvider().timeIntervalSince(lastCheck) < configuration.minimumSpeedCheckInterval {
                return
            }
            guard speedMeasurementTask == nil else { return }
        } else {
            cancelSpeedMeasurement()
        }

        let measurementID = UUID()
        speedMeasurementIdentifier = measurementID
        lastSpeedMeasurementDate = dateProvider()

        speedMeasurementTask = Task { [weak self] in
            let measurementResult: SpeedTestResult
            do {
                measurementResult = try await speedTester.measureSpeed()
            } catch {
                measurementResult = SpeedTestResult(latency: nil, downloadSpeedMbps: nil, uploadSpeedMbps: nil)
            }
            await self?.completeSpeedMeasurement(
                result: measurementResult,
                measurementID: measurementID
            )
        }
    }

    internal func cancelSpeedMeasurement() {
        speedMeasurementTask?.cancel()
        speedMeasurementTask = nil
        speedMeasurementIdentifier = nil
    }

    internal func completeSpeedMeasurement(
        result: SpeedTestResult,
        measurementID: UUID
    ) {
        guard measurementID == speedMeasurementIdentifier else { return }
        speedMeasurementTask = nil
        speedMeasurementIdentifier = nil

        guard let path = currentPath, path.status == .satisfied else { return }

        // Store measurement
        measuredQuality = result

        // Check if quality is degraded
        if qualityEvaluator.isDegradedQuality(result) {
            // Schedule verification check to see if quality improves
            scheduleVerificationCheck()
        } else {
            // Quality is good - cancel any pending verification
            verificationTask?.cancel()
            verificationTask = nil
        }

        updateState()
    }

    /// Schedules a verification check after poor quality measurement
    internal func scheduleVerificationCheck() {
        // Cancel previous verification task
        verificationTask?.cancel()

        verificationTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                guard let self = self else { return }

                // Check if quality is still degraded
                guard await self.measuredQuality != nil else { return }
                guard let path = await self.currentPath, path.status == .satisfied else { return }

                // Run new measurement to verify
                await self.scheduleSpeedMeasurement(force: true, connectionType: await self.state.connectionType)
            } catch {
                // Task was cancelled - normal behavior
                return
            }
        }
    }
}
