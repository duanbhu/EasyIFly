import Foundation

public class IATConfig {

    public static let shared = IATConfig()

    public static let mandarin   = "mandarin"
    public static let cantonese  = "cantonese"
    public static let sichuanese = "lmz"
    public static let chinese    = "zh_cn"
    public static let english    = "en_us"
    public static let lowSampleRate  = "8000"
    public static let highSampleRate = "16000"
    public static let isDot  = "1"
    public static let noDot  = "0"

    public var speechTimeout = "86400000"
    public var vadEos        = "86400000"
    public var vadBos        = "86400000"
    public var dot           = "0"
    public var sampleRate    = "16000"
    public var language      = IATConfig.chinese
    public var accent        = IATConfig.mandarin

    private init() {}
}
