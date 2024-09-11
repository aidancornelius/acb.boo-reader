//
//  ToastView.swift
//  acb.boo reader
//
//  Created by Aidan Cornelius-Bell on 11/9/2024.
//

import Foundation
import SwiftUI

struct Toast: View {
    let message: String
    let isError: Bool
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            if isShowing {
                Text(message)
                    .padding()
                    .background(isError ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.move(edge: .bottom))
            }
        }
        .onChange(of: isShowing) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
        }
    }
}
