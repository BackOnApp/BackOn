//
//  ViewExtensions.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 10/08/2020.
//

import Foundation
import SwiftUI
import UIKit

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
//            .frame(minWidth: 0, maxWidth: .infinity)
//            .overlay(configuration.isPressed ? AnyView(Color.gray.opacity(0.1)) : AnyView(EmptyView()))
            .blur(radius: configuration.isPressed ? 2 : 0)
    }
}

extension Button {
    func customButtonStyle() -> some View {
        return self.buttonStyle(CustomButtonStyle())
    }
}

extension View {
    func transparentNavBar() -> some View {
        return self.background(NavigationConfigurator { nc in
            nc.navigationBar.standardAppearance.configureWithTransparentBackground()
        })
    }
    
    func opaqueOverlay<Content:View>(isPresented: Binding<Bool>, toOverlay: Content) -> some View {
        return self.overlay(OpaqueOverlay(isPresented: isPresented, toOverlay: toOverlay))
    }
    func loadingOverlayIf(_ show: Binding<Bool>, opacity: Double = 0.1) -> some View {
        return self.overlay(OpaqueOverlay(isPresented: show, toOverlay: ProgressView().scaleEffect(1.5), alignment: .center, opacity: opacity))
    }
    func blackOverlayIf(_ show: Binding<Bool>, opacity: Double = 0.6) -> some View {
        return self.overlay(OpaqueOverlay(isPresented: show, toOverlay: EmptyView(), alignment: .center, opacity: opacity))
    }
    func overlayIf<Content:View>(_ show: Binding<Bool>, toOverlay: Content, alignment: Alignment = .center) -> some View {
        return show.wrappedValue ? self.overlay(AnyView(toOverlay), alignment: alignment) : self.overlay(AnyView(EmptyView()))
    }
    
    func tint(_ color: Palette) -> some View {
        return self.foregroundColor(getColor(color))
    }
    func tintIf(_ apply: Bool, _ color: Palette, _ otherwise: Palette = .orange) -> some View {
        return apply ? self.tint(color) : self.tint(otherwise)
    }
    func background(_ color: Palette) -> some View {
        return self.background(getColor(color))
    }
    func backgroundIf(_ apply: Bool, _ color: Palette, _ otherwise: Palette = .orange) -> some View {
        return apply ? self.background(color) : self.background(otherwise)
    }
    func orange() -> some View {
        return self.foregroundColor(Color(.systemOrange))
    }
}

extension Text {
    func orange() -> Text {
        return self.foregroundColor(Color(.systemOrange))
    }
    func colorIf(_ apply: Bool, _ color: UIColor, _ otherwise: UIColor = .systemOrange) -> Text {
        return apply ? self.foregroundColor(Color(color)) : self.foregroundColor(Color(otherwise))
    }
    static func ofEditButton(_ editMode: Bool) -> Text {
        return editMode ? Text("Done").orange().bold() : Text("Edit").orange()
    }
}

extension Image {
    init(mapSnapData: Data?) {
        if mapSnapData == nil {
            self.init("DefaultMap")
        } else {
            if let uiImage = UIImage(data: mapSnapData!) {
                self.init(uiImage: uiImage)
            } else {
                self.init("DefaultMap")
            }
            self = self.renderingMode(.original)
        }
    }
    
    func avatar(size: CGFloat = 75) -> some View {
        return self
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1))
            .orange()
    }
}


enum Palette {
    case need
    case expiredNeed
    case grayLabel
    case detailedTaskHeaderBG
    case button
    case yellow
    case orange
    case red
    case green
    case gray
    case gray3
    case gray6
    case black
    case white
    case primary
    case secondary
    case systemBG
    case test
}

func getColor(_ color: Palette) -> Color {
    switch color {
    case .need:
        return Color(#colorLiteral(red: 0.9910104871, green: 0.6643157601, blue: 0.3115140796, alpha: 1))
    case .expiredNeed:
        return Color(#colorLiteral(red: 0.9425833355, green: 0.9425833355, blue: 0.9425833355, alpha: 1))
//    case .expiredNeed:
//        return Color(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1))
    case .detailedTaskHeaderBG, .button: //dovrà avvicinarsi al caso .task
        return Color(#colorLiteral(red: 0.9910104871, green: 0.6643157601, blue: 0.3115140796, alpha: 1)).opacity(0.9)
    case .grayLabel:
        return Color(UIColor.secondaryLabel.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)))
    case .yellow:
        return Color(.systemYellow)
    case .green:
        return Color(.systemGreen)
    case .orange:
        return Color(.systemOrange)
    case .red:
        return Color(.systemRed)
    case .gray:
        return Color(.systemGray)
    case .gray3:
        return Color(.systemGray3)
    case .gray6:
        return Color(.systemGray6)
    case .white:
        return Color.white
    case .systemBG:
        return Color(.systemBackground)
    case .test: //SOLO DI TEST
        return UIScreen.main.traitCollection.userInterfaceStyle == .dark ? Color(.green) : Color(.red)
    case .secondary:
        return Color.secondary
    case .primary:
        return Color.primary
    case .black:
        return Color.black
    }
}

/*
 GUIDA AI COLORI
 - aggiungere alla palette i nomi dei colori
 - aggiungere i case corrispondenti nella funzione tint
 - applicare tint agli elementi desiderati
 
 N.B. i Color(.system^^^^^) si adattano automaticamente ai cambi light/dark mode e viceversa
 (e le coppie di colori utilizzati sono studiate da Apple. Le potete vedere a questo link: https://www.avanderlee.com/wp-content/uploads/2019/02/SemanticUI_app_Aaron_Brethorst.png)
 
 Se usate colori non .system^^^^^ e che devono cambiare a seconda della modalità nella vista in cui chiamate la .tint aggiungete
 @Environment(.\colorScheme) var colorScheme
 */

extension Color {
    public init(hex: String) {
        let r, g, b: CGFloat
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    self.init(UIColor(red: r, green: g, blue: b, alpha: 1))
                    return
                }
            }
        }
        self.init(.clear)
    }
}
