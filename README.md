# synctex-iOS - SyncTeX Library for `iOS` Platform

## Introduction

This is a Swift package for performing **SyncTeX forward and reverse search**.

- Minimum supported version: `iOS/iPadOS 13.0`.

## Notes

1. This package is a thin wrapper for the `C` language library `SyncTeX`. Memory management related to `C` language API of `SyncTeX` is entirely handled within this package.
2. Queries must be based on a real `TeX` project structure. This framework can automatically read the `synctex` synchronization file in the directory where the output file is located (these files generally have the file extension `synctex.gz` or `.synctex`).

### Example

Below is a typical example of using this framework for **reverse search** (finding the corresponding position in the source file based on a point in the `PDF` file).

Assuming the `URL` of the `TeX` engine's output file is `outputFileURL`.

```swift
import SyncTeX
function test() async {
    let outputFileURL = URL(filePath: "123.pdf")
    do {
        let scanner = try await SyncTeXScanner(outputFileURL: outputFileURL)
        let resultArray = await scanner.editQuery(page: 10, h: 0.2, v: 0.2) // Page starts from 1
        for result in resultArray {
            print(result)
        }
    } catch {
        //TODO: Catch Error
    }
}

```
All the provided public functions have detailed comments (in English), which can be directly viewed in the `./Sources/SyncTeX/Scanner.swift` file.
