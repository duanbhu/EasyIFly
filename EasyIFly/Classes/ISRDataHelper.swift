import Foundation

public class ISRDataHelper {

    /// 解析讯飞语音听写 JSON 结果，返回拼接后的文字
    public static func string(fromJson params: String?) -> String? {
        guard let params, !params.isEmpty,
              let data = params.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ws = result["ws"] as? [[String: Any]] else { return nil }

        return ws.compactMap { wsDic -> String? in
            guard let cw = wsDic["cw"] as? [[String: Any]] else { return nil }
            return cw.compactMap { $0["w"] as? String }.joined()
        }.joined()
    }

    /// 解析云端语法识别 JSON 结果
    public static func stringFromABNF(json params: String?) -> String? {
        guard let params, !params.isEmpty,
              let data = params.data(using: .utf8),
              let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let ws = result["ws"] as? [[String: Any]] else { return nil }

        return ws.compactMap { wsDic -> String? in
            guard let cw = wsDic["cw"] as? [[String: Any]] else { return nil }
            return cw.compactMap { wDic -> String? in
                guard let w = wDic["w"] as? String else { return nil }
                let score = wDic["sc"] as? String ?? ""
                return "\(w) Confidence:\(score)\n"
            }.joined()
        }.joined()
    }
}
