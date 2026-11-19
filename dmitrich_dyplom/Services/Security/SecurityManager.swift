import CryptoKit
import Foundation
import LocalAuthentication
import Observation
import UIKit

@Observable
@MainActor
final class SecurityManager {
    private enum StorageKeys {
        static let isPINEnabled = "security.is_pin_enabled"
        static let isBiometryEnabled = "security.is_biometry_enabled"
        static let locksOnLaunch = "security.locks_on_launch"
        static let lockDelay = "security.lock_delay"
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let pinStore: KeychainPINStore
    @ObservationIgnored private var backgroundEnteredAt: Date?

    private(set) var isPINEnabled: Bool
    var isBiometryEnabled: Bool {
        didSet {
            userDefaults.set(isBiometryEnabled, forKey: StorageKeys.isBiometryEnabled)
        }
    }
    var locksOnLaunch: Bool {
        didSet {
            userDefaults.set(locksOnLaunch, forKey: StorageKeys.locksOnLaunch)
        }
    }
    var lockDelay: AppLockDelay {
        didSet {
            userDefaults.set(lockDelay.rawValue, forKey: StorageKeys.lockDelay)
        }
    }
    private(set) var isUnlocked: Bool
    private(set) var biometryType: LABiometryType = .none
    private(set) var isBiometryAvailable = false

    init(userDefaults: UserDefaults = .standard, pinStore: KeychainPINStore = KeychainPINStore()) {
        self.userDefaults = userDefaults
        self.pinStore = pinStore
        let storedPINEnabled = userDefaults.bool(forKey: StorageKeys.isPINEnabled)
        self.isPINEnabled = storedPINEnabled
        self.isBiometryEnabled = userDefaults.bool(forKey: StorageKeys.isBiometryEnabled)

        let storedLocksOnLaunch: Bool
        if userDefaults.object(forKey: StorageKeys.locksOnLaunch) == nil {
            storedLocksOnLaunch = true
        } else {
            storedLocksOnLaunch = userDefaults.bool(forKey: StorageKeys.locksOnLaunch)
        }
        self.locksOnLaunch = storedLocksOnLaunch
        self.lockDelay = AppLockDelay(
            rawValue: userDefaults.string(forKey: StorageKeys.lockDelay) ?? ""
        ) ?? .thirtyMinutes

        self.isUnlocked = !(storedPINEnabled && storedLocksOnLaunch)
        refreshBiometryAvailability()
    }

    var requiresUnlock: Bool {
        isPINEnabled && !isUnlocked
    }

    var canUseBiometryUnlock: Bool {
        isPINEnabled && isBiometryEnabled && isBiometryAvailable
    }

    func lockIfNeededOnLaunch() {
        guard isPINEnabled, locksOnLaunch else {
            isUnlocked = true
            return
        }

        isUnlocked = false
    }

    func sceneDidEnterBackground() {
        backgroundEnteredAt = .now

        if isPINEnabled, locksOnLaunch, lockDelay == .immediately {
            isUnlocked = false
        }
    }

    func sceneDidBecomeActive() {
        guard isPINEnabled, locksOnLaunch, let backgroundEnteredAt else {
            self.backgroundEnteredAt = nil
            return
        }

        if lockDelay == .immediately || Date().timeIntervalSince(backgroundEnteredAt) >= lockDelay.seconds {
            isUnlocked = false
        }

        self.backgroundEnteredAt = nil
    }

    func enablePIN(_ pin: String) throws {
        try validatePIN(pin)
        try pinStore.savePINHash(hash(pin))
        isPINEnabled = true
        isUnlocked = true
        userDefaults.set(true, forKey: StorageKeys.isPINEnabled)
    }

    func disablePIN() {
        pinStore.deletePINHash()
        isPINEnabled = false
        isBiometryEnabled = false
        isUnlocked = true
        userDefaults.set(false, forKey: StorageKeys.isPINEnabled)
    }

    func updatePIN(currentPIN: String, newPIN: String) throws -> Bool {
        guard verifyPIN(currentPIN) else { return false }
        try enablePIN(newPIN)
        return true
    }

    func unlock(with pin: String) -> Bool {
        guard verifyPIN(pin) else { return false }
        isUnlocked = true
        return true
    }

    func authenticateWithBiometrics(reason: String) async -> Bool {
        refreshBiometryAvailability()
        guard canUseBiometryUnlock else { return false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            isBiometryAvailable = false
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                Task { @MainActor in
                    if success {
                        self.isUnlocked = true
                    }
                    continuation.resume(returning: success)
                }
            }
        }
    }

    func refreshBiometryAvailability() {
        let context = LAContext()
        var error: NSError?
        isBiometryAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometryType = context.biometryType

        if biometryType == .faceID,
           Bundle.main.object(forInfoDictionaryKey: "NSFaceIDUsageDescription") == nil {
            isBiometryAvailable = false
        }

        if !isBiometryAvailable {
            isBiometryEnabled = false
        }
    }

    private func validatePIN(_ pin: String) throws {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            throw SecurityPINError.invalidFormat
        }
    }

    private func verifyPIN(_ pin: String) -> Bool {
        guard pin.count == 4,
              let storedHash = pinStore.loadPINHash() else {
            return false
        }

        return hash(pin) == storedHash
    }

    private func hash(_ pin: String) -> String {
        let data = Data(pin.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum SecurityPINError: Error {
    case invalidFormat
}

enum AppLockDelay: String, CaseIterable, Codable, Identifiable {
    case immediately
    case oneMinute
    case fiveMinutes
    case thirtyMinutes

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .immediately:
            return 0
        case .oneMinute:
            return 60
        case .fiveMinutes:
            return 300
        case .thirtyMinutes:
            return 1_800
        }
    }

    var localizedTitleKey: LocalizedTextKey {
        switch self {
        case .immediately:
            return L.securityLockDelayImmediately
        case .oneMinute:
            return L.securityLockDelayOneMinute
        case .fiveMinutes:
            return L.securityLockDelayFiveMinutes
        case .thirtyMinutes:
            return L.securityLockDelayThirtyMinutes
        }
    }
}
