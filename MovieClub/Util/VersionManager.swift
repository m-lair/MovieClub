import Foundation

class VersionManager {
    private static let lastViewedVersionKey = "lastViewedVersion"
    private static let firstLaunchKey = "isFirstLaunch"
    
    /// Get the current app version from the Info.plist
    static var currentVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0" // Default if unable to read version
        }
        return version
    }
    
    /// The last version the user viewed the What's New screen for
    static var lastViewedVersion: String {
        return UserDefaults.standard.string(forKey: lastViewedVersionKey) ?? ""
    }
    
    /// Check if this is the first launch of the app ever
    static var isFirstLaunch: Bool {
        let firstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchKey)
        if firstLaunch {
            // Set it to false for next time
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
        return firstLaunch
    }
    
    /// Check if there's a new version that hasn't been seen by the user
    static func shouldShowWhatsNew() -> Bool {
        // Skip on first launch since onboarding is more appropriate
        if isFirstLaunch {
            // Still mark as seen so future updates will work properly
            markCurrentVersionAsSeen()
            return false
        }
        
        let lastViewed = lastViewedVersion
        
        // If no version has been stored or the stored version is different
        // from the current version, we should show What's New
        return lastViewed.isEmpty || lastViewed != currentVersion
    }
    
    /// Check if we're running a specific version
    static func isRunningVersion(_ version: String) -> Bool {
        return currentVersion == version
    }
    
    /// Mark the current version as seen
    static func markCurrentVersionAsSeen() {
        UserDefaults.standard.set(currentVersion, forKey: lastViewedVersionKey)
    }
    
    /// Reset the version tracking (for testing)
    static func resetVersionTracking() {
        UserDefaults.standard.removeObject(forKey: lastViewedVersionKey)
    }
} 
