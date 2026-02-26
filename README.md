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

```swift
let updateConfig = AppUpdateManager.Config(
    appStoreID: "1343105318",
    isArabic: applicationLanguage != "en",
    
    cacheExpiry: 24 * 60 * 60, // every 24 hrs
    normalReminderInterval: 120 * 60 * 60, // every 5 days
    
    latestVersionFirebaseKey: "latest_version",
    minimumVersionFirebaseKey: "minimum_version",
    managerOverrideFirebaseKey: "manager_override"
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
