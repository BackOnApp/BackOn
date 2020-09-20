//
//  OverlayView.swift
//  BackOn
//
//  Created by Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro on 19/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation
import SwiftUI
import MapKit


struct OpaqueOverlay<Content: View>: View {
    @Binding var isPresented: Bool
    let opacity: Double
    let alignment: Alignment
    let toOverlay: Content
    
    init(isPresented: Binding<Bool>, toOverlay: Content, alignment: Alignment = .bottom, opacity: Double = 0.6) {
        self._isPresented = isPresented
        self.toOverlay = toOverlay
        self.alignment = alignment
        self.opacity = opacity
    }
    
    var body: some View {
        GeometryReader { geometry in
            if self.isPresented {
                Color
                    .black
                    .opacity(self.opacity)
                    .onTapGesture{withAnimation{self.isPresented = false}}
                    .overlay(self.toOverlay, alignment: self.alignment)
                    .edgesIgnoringSafeArea(.all)
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                    .animation(.easeInOut)
            } else {
                EmptyView()
                    .animation(.easeInOut)
            }
        }
    }
}

struct SheetView<Content: View>: View {
    let radius: CGFloat = 16
    let indicatorHeight: CGFloat = 6
    let indicatorWidth: CGFloat = 60
    let snapRatio: CGFloat = 0.40
    let minHeightRatio: CGFloat = 0.3
    
    @Binding var isOpen: Bool
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
    let onClose: () -> Void
    
    @GestureState private var translation: CGFloat = 0
    
    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.secondary)
            .frame(width: indicatorWidth, height: indicatorHeight)
            .onTapGesture{self.isOpen.toggle()}
    }
    
    init(isOpen: Binding<Bool>, onClose: @escaping () -> Void = {}, @ViewBuilder content: () -> Content) {
        self.minHeight = 0 //invece di mostrarla chiusa, la spinge fuori dallo schermo
        self.maxHeight = UIScreen.main.bounds.height - 450 //valore da cambiare
        self.content = content()
        self._isOpen = isOpen
        self.onClose = onClose
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.content
                .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
                .background(.systemBG)
                .cornerRadius(self.radius)
                .frame(height: geometry.size.height, alignment: .bottom)
                .offset(y: max(self.offset + self.translation, 0))
                .animation(.interactiveSpring(response: 0.05, dampingFraction: 1))
                //.animation(.interactiveSpring(response:  0.45, dampingFraction:  0.86, blendDuration:  0.7))
                .gesture(
                    DragGesture().updating(self.$translation) { value, state, _ in
                        state = value.translation.height
                    }.onEnded { value in
                        let snapDistance = self.maxHeight * self.snapRatio
                        guard abs(value.translation.height) > snapDistance else {return}
                        self.isOpen = value.translation.height < 0
                        if !self.isOpen {
                            onClose()
                        }
                    }
                )
        }.edgesIgnoringSafeArea(.bottom)
    }
}
