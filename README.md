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
import MadarUpdater
```

## Step 2 – Configure
Minimal config: 
```swift
let updateConfig = AppUpdateManager.Config(
    appStoreID: "1343105318",
    isArabic: applicationLanguage != "en"
)
```
All default values are customizable: 
```swift
let isArabic = applicationLanguage != "en"

let updateConfig = AppUpdateManager.Config(
    appStoreID: "1343105318",
    isArabic: isArabic,
    
    cacheExpiry: 24 * 60 * 60, // after 24 hrs
    normalReminderInterval: 120 * 60 * 60, // every 5 days
    
    latestVersionFirebaseKey: "latest_version",
    minimumVersionFirebaseKey: "minimum_version",
    managerOverrideFirebaseKey: "manager_override",
    
    // Normal
    normalUpdateTitle: isArabic ? "تحديث متوفر" : "Update Available",
    normalUpdateMessage: isArabic
        ? "نسخة أحدث من التطبيق متوفرة."
        : "A newer version is available.",
    
    // Urgent
    urgentUpdateTitle: isArabic ? "تحديث موصى به" : "Update Recommended",
    urgentUpdateMessage: isArabic
        ? "يرجى التحديث للحصول على أفضل تجربة."
        : "Please update for the best experience.",
    
    // Forced
    forcedUpdateTitle: isArabic ? "تحديث إلزامي" : "Update Required",
    forcedUpdateMessage: isArabic
        ? "يجب عليك التحديث لمواصلة استخدام التطبيق."
        : "You must update to continue using the app.",
    
    // Buttons
    laterButtonTitle: isArabic ? "لاحقاً" : "Later",
    updateButtonTitle: isArabic ? "تحديث الآن" : "Update Now",
    
    // Success
    updatedSuccessfullyTitle: isArabic
        ? "🎉 تم تحديث التطبيق بنجاح"
        : "App Updated Successfully 🎉",
    
    updatedSuccessfullyMessage: isArabic
        ? "شكراً لتحديث التطبيق. استمتع بأحدث المزايا والتحسينات."
        : "Thanks for updating! Enjoy the latest features and improvements.",
    
    successButtonTitle: isArabic ? "حسناً" : "OK"
)
```

## Step 3 – Setup
=> inside AppDelegate 
```swift
AppUpdateManager.shared.setup(with: updateConfig) 
```

## Step 4 – Check for Updates
=> with every network request

```swift
func checkforUpdate(strURL: String) {
    let AllowToSkipUpdateAlertsRoutes: Set<String> = [
       ... all critical & important routes ....
    ]
    
    Task {
        let isAllowToSkip = AllowToSkipUpdateAlertsRoutes.contains(strURL)
        let state = await AppUpdateManager.shared.checkForUpdate(allowSkip: isAllowToSkip)
        print("Update check: \(state)")
    }
}
```
