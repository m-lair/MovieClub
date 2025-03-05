//
//  FontExtensions.swift
//  MovieClub
//
//  Created by Marcus Lair on 3/4/25.
//

import SwiftUI

extension Font {
    
    /// Create a font with the large title text style.
    public static var largeTitle: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize)
    }
    
    /// Create a font with the title text style.
    public static var title: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
    }
    
    /// Create a font with the headline text style.
    public static var headline: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .headline).pointSize)
    }
    
    /// Create a font with the subheadline text style.
    public static var subheadline: Font {
        return Font.custom("Stolzl-Light", size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
    }
    
    /// Create a font with the callout text style.
    public static var callout: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .callout).pointSize)
    }
    
    /// Create a font with the footnote text style.
    public static var footnote: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .footnote).pointSize)
    }
    
    /// Create a font with the caption text style.
    public static var caption: Font {
        return Font.custom("Stolzl-Regular", size: UIFont.preferredFont(forTextStyle: .caption1).pointSize)
    }
    
    public static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        var font = "Stolzl-Regular"
        switch weight {
        case .bold: font = "Stolzl-Bold"
        case .heavy: font = "Stolzl-Bold"
        case .light: font = "Stolzl-Light"
        case .medium: font = "Stolzl-Regular"
        case .semibold: font = "Stolzl-Bold"
        case .thin: font = "Stolzl-Light"
        case .ultraLight: font = "Stolzl-Light"
        default: break
        }
        return Font.custom(font, size: size)
    }
}
