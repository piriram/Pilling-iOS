import UIKit

struct Typography {
    static func headline1(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 28, weight: weight) }
    static func headline1() -> UIFont { headline1(.bold) }
    
    static func headline2(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 26, weight: weight) }
    static func headline2() -> UIFont { headline2(.regular) }
    
    static func headline3(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 24, weight: weight) }
    static func headline3() -> UIFont { headline3(.regular) }
    
    static func headline4(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 22, weight: weight) }
    static func headline4() -> UIFont { headline4(.regular) }
    
    static func headline5(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 20, weight: weight) }
    static func headline5() -> UIFont { headline5(.regular) }
    
    static func body1(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 18, weight: weight) }
    static func body1() -> UIFont { body1(.regular) }
    
    static func body2(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 16, weight: weight) }
    static func body2() -> UIFont { body2(.regular) }
    
    static func caption(_ weight: UIFont.Weight) -> UIFont { .systemFont(ofSize: 14, weight: weight) }
    static func caption() -> UIFont { caption(.regular) }
}
