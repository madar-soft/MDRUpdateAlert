# MDRUpdateAlert

A lightweight iOS SDK for showing update alerts (forced, urgent, or normal), driven by Firebase Remote Config.

> Firebase Console: Run/Remote Config
> 
![firebase](https://github.com/madar-soft/MDRUpdateAlert/blob/main/Media/firebase.png?raw=true)

## Overview

- Supports forced, urgent, and normal updates
- Uses Firebase Remote Config as the primary source
- Falls back to local cache when offline
- Detects app version changes and shows a "successfully updated" alert
- Skips alerts on protected flows (auth, payment, etc.)
- Works with Firebase installed via either **CocoaPods** or **SPM**

## Update Flow

- **New Session** → Fetch → Cache → Evaluate
- **Cached** → Use cache (expires after 24 hrs by default)
- **Offline** → Fallback to cache
- **App Updated** → show success alert + clear cache

---

## Installation

### 1. Add MDRUpdateAlert via Swift Package Manager

#### Via Xcode

1. In Xcode, go to **File → Add Package Dependencies**
2. Paste the repository URL:
   ```
   https://github.com/madar-soft/MDRUpdateAlert.git
   ```
   OR
   ```
   git@github.com:madar-soft/MDRUpdateAlert.git
   ```
4. Set the version rule to **Up to Next Major** from `1.0.7`
5. Click **Add Package**

#### Via `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/madar-soft/MDRUpdateAlert.git", from: "1.0.7")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["MDRUpdateAlert"]
    )
]
```

### 2. Install Firebase Remote Config in your app

`MDRUpdateAlert` does **not** declare Firebase as its own dependency. It talks to your app's existing Firebase installation at runtime, so you can use whichever package manager you already have.

**CocoaPods:**
```ruby
pod 'Firebase/RemoteConfig'
```

**SPM:**
Add `https://github.com/firebase/firebase-ios-sdk` to your project and link the **`FirebaseRemoteConfig`** product to your app target.

> Recommended minimum: `firebase-ios-sdk 12.8.0+`.

### 3. Add an explicit `import` in your `AppDelegate`

```swift
import FirebaseRemoteConfig
```

> ⚠️ **This import is required**, not optional. It tells the linker to keep Firebase Remote Config's symbols in your final binary. Without it, dead-code stripping may drop the symbols (especially in Release builds), and `MDRUpdateAlert` will throw `firebaseNotInstalled` at runtime even though Firebase is installed correctly.
>
> You don't need to *use* anything from this import — just having the line is enough.

### Requirements

- iOS 15.0+
- Swift 5.0+
- Xcode 15+
- `firebase-ios-sdk 12.8.0+` (installed by you, see step 2)

---

## Implementation Steps

### Step 1 – Import

```swift
import MDRUpdateAlert
import FirebaseRemoteConfig   // ← keep this, see Installation step 3
```

### Step 2 – Configure

One-liner config:

```swift
let updateConfig = AppUpdateManager.Config(appStoreID: "0123456789")
```

All defaults are customizable:

```swift
let updateConfig = AppUpdateManager.Config(
    appStoreID: "0123456789",
    
    cacheExpiry: 24 * 60 * 60,             // 24 hrs
    normalReminderInterval: 120 * 60 * 60, // 5 days
    
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
    successButtonTitle: "حسناً"
)
```

### Step 3 – Set up at launch

Inside `AppDelegate`, make sure `FirebaseApp.configure()` is called **first**:

```swift
FirebaseApp.configure()
AppUpdateManager.shared.setup(with: updateConfig)
```

### Step 4 – Check for updates

Trigger a check with every screen appearance, **or** with every base network request (GET, POST, …):

```swift
Task {
    let state = await AppUpdateManager.shared.checkForUpdate()
    print("Update check: \(state)")
}
```

### Step 5 – Protected flows

If the update isn't forced, don't present the alert over sensitive flows like Auth or Payment.

#### Protected screens

```swift
AppUpdateManager.shared.protectedScreens = [
    String(describing: AuthViewController.self),
    String(describing: PaymentViewController.self)
]
```

#### Protected routes

```swift
func checkforUpdate(strURL: String) {
    let domain = "https://api.test.net"

    let protectedRoutes: Set<String> = [
        domain + "/api/test/auth",
        domain + "/api/test/payment"
    ]

    let isAllowToSkip = protectedRoutes.contains(strURL)
    
    Task {
        let state = await AppUpdateManager.shared.checkForUpdate(allowSkip: isAllowToSkip)
        print("Update check: \(state)")
    }
}
```

### Step 6 – Localize alerts

Whenever the app language changes:

```swift
AppUpdateManager.shared.isArabic = applicationLanguage != "en"
```
