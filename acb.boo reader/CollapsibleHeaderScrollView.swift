//
//  CollapsibleHeaderScrollView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 10/9/2024.
//

import Foundation
import SwiftUI

struct CollapsibleHeaderScrollView<Content: View, Header: View>: View {
    let content: Content
    let header: Header
    let height: CGFloat
    let minHeight: CGFloat

    @State private var headerHeight: CGFloat = 0

    init(height: CGFloat, minHeight: CGFloat, @ViewBuilder content: () -> Content, @ViewBuilder header: () -> Header) {
        self.content = content()
        self.header = header()
        self.height = height
        self.minHeight = minHeight
    }

    var body: some View {
        ScrollView {
            ZStack {
                GeometryReader { geometry in
                    Color.clear.preference(key: ViewOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }

                VStack(spacing: 0) {
                    header
                        .frame(height: max(headerHeight, minHeight))
                        .clipped()
                    content
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ViewOffsetKey.self) { value in
            headerHeight = max(minHeight, height + value)
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
