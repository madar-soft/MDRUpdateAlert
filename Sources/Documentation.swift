//
//  Documentation.swift
//  MDRUpdateAlert
//
//  Created by Belal Samy on 23/02/2026.
//

/*
Happy Path (First Launch)
============================
No cache → Fetch from Firebase → Save to cache → Evaluate → Show alert

Cached Path (Within 24h)
============================
Valid cache exists → Use cached config → Evaluate → Maybe show alert

Offline Path
============================
Offline + expired cache → Use expired cache → Evaluate → Maybe show alert
Offline + no cache → Return .none

Override Path
============================
managerOverride = 3 → .forced (ignores versions)
managerOverride = 2 → .urgent
managerOverride = 1 → .normal
managerOverride = 0 → Use version logic

Reminder Path
============================
Forced → Always show
Normal/Urgent → Check last shown date → Show if interval passed
*/

// =======================================================================

/*
============================
How to setup MadarUpdate
============================

// step 1 - import
import MadarUpdater 

// step 2 - setup 
AppUpdateManager.shared.setup(with: .init(appStoreID: "1234567890"))

// step 3 - check (optional)
Task {
    let state = await AppUpdateManager.shared.checkForUpdate()
    print("Update check: \(state)")
}
*/
