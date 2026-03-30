# MDRUpdateAlert
SDK for show alert for update Version, built on Firebase Remote Config.

> Firebase Console: Run/Remote Config
> 
![firebase](https://github.com/madar-soft/MDRUpdateAlert/blob/main/Media/firebase.png?raw=true)

## Overview
- Supports forced, urgent, and normal updates.
- Uses Firebase as primary source.
- Falls back to local cache when offline.
- Detects app version changes.

## Setup
1. Call `setup(with:)` at launch.
2. Call `checkForUpdate()` after network calls.

## Update Flow
- New Session → Fetch → Cache → Evaluate.
- Cached → Use cache `"expired after 24 hrs"`
- Offline → Fallback to cache
- App Updated → show success alert + Clear cache

# Implementation Steps 

## Step 1 – Import

```swift
import MDRUpdateAlert
```

## Step 2 – Configure
One-liner config: 
```swift
let updateConfig = AppUpdateManager.Config(appStoreID: "1343105318")
```
Default values are customizable: 
```swift
let updateConfig = AppUpdateManager.Config(
    appStoreID: "1343105318",

    cacheExpiry: 24 * 60 * 60, // after 24 hrs
    normalReminderInterval: 120 * 60 * 60, // every 5 days
    
    latestVersionFirebaseKey: "latest_version",
    minimumVersionFirebaseKey: "minimum_version",
    managerOverrideFirebaseKey: "manager_override",
    
    // Normal
    normalUpdateTitle: "تحديث متوفر",
    normalUpdateMessage: "نسخة أحدث من التطبيق متوفرة.",
    
    // Urgent
    urgentUpdateTitle: "تحديث موصى به",
    urgentUpdateMessage: "يرجى التحديث للحصول على أفضل تجربة.",
    
    // Forced
    forcedUpdateTitle: "تحديث إلزامي",
    forcedUpdateMessage: "يجب عليك التحديث لمواصلة استخدام التطبيق.",
    
    // Buttons
    laterButtonTitle: "لاحقاً",
    updateButtonTitle: "تحديث الآن",
    
    // Success
    updatedSuccessfullyTitle: "🎉 تم تحديث التطبيق بنجاح",
    updatedSuccessfullyMessage: "شكراً لتحديث التطبيق. استمتع بأحدث المزايا والتحسينات.",
    successButtonTitle: "حسناً",
)
```

## Step 3 – Setup
=> inside AppDelegate, make sure `FirebaseApp.configure()` called first !
```swift
AppUpdateManager.shared.setup(with: updateConfig) 
```

## Step 4 - Localize [OPTIONAL]
Whenever need to update alert default strings localization
```swift
AppUpdateManager.shared.isArabic = applicationLanguage != "en"
```

## Step 5 – Check for Updates
=> with every base network request (GET, POST, ...)

```swift
func checkforUpdate(strURL: String) {
    let domain = "https://api.test.net"

    // don't present update alert over those routes
    let protectedRoutes: Set<String> = [
        domain + "/api/test/auth",
        domain + "/api/test/payment"
    ]

    // don't present update alert over those screens[OPTIONAL]
    AppUpdateManager.shared.protectedScreens = [
        String(describing: AuthViewController.self),
        String(describing: PaymentViewController.self)
    ]
    
    // make sure language updated before checkForUpdate()
    AppUpdateManager.shared.isArabic = applicationLanguage != "en"

    // if it's a protected route, it should be allowed to skip
    let isAllowToSkip = protectedRoutes.contains(strURL)
    
    Task {
        let state = await AppUpdateManager.shared.checkForUpdate(allowSkip: isAllowToSkip)
        print("Update check: \(state)")
    }
}
```
## Installation

### Swift Package Manager

MDRUpdateAlert is available through [Swift Package Manager](https://swift.org/package-manager/).

#### Via Xcode

1. In Xcode, go to **File → Add Package Dependencies**
2. Paste the repository URL:
```
https://github.com/madar-soft/MDRUpdateAlert.git
```
3. Set the version rule to **Up to Next Major** from `1.0.0`
4. Click **Add Package**

#### Via `Package.swift`

Add MDRUpdateAlert as a dependency in your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/madar-soft/MDRUpdateAlert.git", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["MDRUpdateAlert"]
    )
]
```

> **Note:** MDRUpdateAlert uses [Firebase Remote Config](https://firebase.google.com/docs/remote-config) under the hood (`firebase-ios-sdk 12.8.0+`), which will be resolved automatically as a transitive dependency.

#### Requirements

- iOS 15.0+
- Swift 5.0+
- Xcode 15+
