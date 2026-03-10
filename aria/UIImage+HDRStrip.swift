//
//  UIImage+HDRStrip.swift
//  aria
//
//  HDR 메타데이터 제거 — IIOCallConvertHDRData -50 에러 방지
//

import UIKit

extension UIImage {
    /// 표준 sRGB 컬러 스페이스로 다시 그려서 HDR 메타데이터를 제거한 이미지 반환.
    /// jpegData(compressionQuality:) 호출 전에 사용하면 IIOCallConvertHDRData 에러를 방지할 수 있음.
    func byStrippingHDR() -> UIImage {
        let size = self.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = false
        format.preferredRange = .standard  // sRGB, HDR 아님
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(at: .zero)
        }
    }
}
