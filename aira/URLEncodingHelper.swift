//
//  URLEncodingHelper.swift
//  aira
//
//  PostgREST/Supabase query 파라미터용 URL 인코딩
//

import Foundation

enum URLEncodingHelper {
    /// user_id 등 PostgREST eq 쿼리 값에 사용
    /// (애플 userId의 점(.) 등 특수문자, URL 예약문자 대응)
    static func encodeForQuery(_ value: String) -> String {
        // PostgREST: 문자열은 따옴표 없이 그대로 두고, URL 인코딩만 하면 됨
        // 예) ?user_id=eq.abc.123  → value = "abc.123" 를 인코딩
        return value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
