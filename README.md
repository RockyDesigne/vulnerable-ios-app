//
//  README.md
//  demo_vuln_lab4
//
//  Created by Horia Banica on 15.03.2026.
//

# The Silent Leak: iOS Default Caching Vulnerability (OWASP M9)

This repository contains a vulnerable iOS application demonstrating the silent data leakage caused by Apple's default `URLSession` caching mechanisms. It was created as a practical demonstration for the Security of Mobile Devices lab at UPB.

## ⚠️ The Vulnerability (OWASP M9 - Insecure Data Storage)

By default, iOS applications using standard `URLSession.shared` networking configurations automatically cache decrypted HTTP responses directly to the device's physical disk.

While this app simply fetches public Pokémon data, in an enterprise environment, this exact default behavior can leak sensitive data such as:
* OAuth Bearer Tokens
* Private Messages
* Medical Records
* Financial Data

## 🚀 How to Reproduce the Exploit

To see the vulnerability in action, you don't need a proxy or jailbroken device. You just need Xcode and the macOS Terminal.

### Step 1: Generate the Traffic
1. Clone this repository and open the project in Xcode.
2. Build and run the application in the **iOS Simulator**.
3. Type a Pokémon name (e.g., "pikachu") and tap **Fetch Data**.
4. **Crucial:** Send the app to the background by pressing `Cmd + Shift + H` (or swiping up from the bottom). This forces iOS to flush its active memory and write the cached data to the disk.

### Step 2: Extract the Data
Open your macOS Terminal and run the following commands in order:

**1. Navigate to the app's hidden cache container:**
```bash
cd $(xcrun simctl get_app_container booted test.demo-vuln-lab4 data)/Library/Caches/test.demo-vuln-lab4/
```

**2. Verify the network request was logged by iOS:**
*This queries the SQLite database to show the metadata and UUID assigned to your API call.*

```bash
sqlite3 Cache.db "SELECT * FROM cfurl_cache_receiver_data;"
```

**3. Locate the hidden payload directory:**
*Modern iOS versions store the actual large JSON/Image payloads outside the database in a separate folder.*

```bash
ls fsCachedData
```

**4. Dump the unencrypted payload:**
*This command outputs the raw, plain-text JSON data sitting on the hard drive. Change "pikachu" to match whatever you searched for in the app.*

```bash
cat fsCachedData/* | grep -i "pikachu"
```

## 🛡️ The Solution

This catastrophic data leak can be fixed with a single line of code. Instead of using the shared session, use an **ephemeral session configuration**, which forces the OS to keep all caches, cookies, and credentials strictly in RAM:

```swift
let config = URLSessionConfiguration.ephemeral
let session = URLSession(configuration: config)
```

Alternatively, you can globally disable disk caching for the shared session:

```swift
URLCache.shared.diskCapacity = 0
```

---
