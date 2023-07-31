# SyncTeX——适用于 `iOS` 平台的 `SyncTeX` 库

## 简介

这是一个用于执行 **SyncTeX 正向查找与反向查找** 的 Swift 包。

- 最低运行版本：`iOS/iPadOS 13.0`。

## 注意事项

1. 本包只是对 `C` 语言库 `SyncTeX` 的一层浅包装。与 `SyncTeX` 的 `C` 语言 API 有关的内存管理完全在本包内部进行。
2. 本包非常稳定，不会出现内存泄漏等情况。
3. 必须基于真实的 `TeX` 工程结构进行查询，本框架可以自动读取该输出文件所在目录的 `synctex` 同步文件（它们一般以 `synctex.gz` 或者 `.synctex` 为文件后缀）。


### 例子

以下给出了一个使用本框架进行 **向后查找** （根据 `PDF` 文件中的某个点，查找源文件的对应位置）的典型例子。

假设 `TeX` 引擎的输出文件 `URL` 为 `outputFileURL`。

```swift
import SyncTeX
function test() {
    let outputFileURL = URL(filePath: "123.pdf")
    do {
        let scanner = try SyncTeXScanner(outputFileURL: outputFileURL)
        let resultArray = scanner.editQuery(page: 10, h: 0.2, v: 0.2) // Page 从 1 开始
        for result in resultArray {
            print(result)
        }
    } catch {
        //TODO: Catch Error
    }
}

```
所有提供的公开函数均有详细的注释（英文），可以直接查看 `./Sources/SyncTeX/Scanner.swift` 文件中的相关内容。



