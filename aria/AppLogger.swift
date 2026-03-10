//
//  AppLogger.swift
//  aria
//
//  배포 빌드(Release)에서는 로그가 출력되지 않습니다.
//

import Foundation

enum AppLogger {
    /// 디버그 빌드에서만 콘솔에 출력. Release에서는 제거됨.
    static func debug(_ items: Any...) {
        #if DEBUG
        let output = items.map { "\($0)" }.joined(separator: " ")
        print(output)
        #endif
    }
}
