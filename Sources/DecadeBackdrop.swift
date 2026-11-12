import SwiftUI

/// #FCFCFC with three pale blobs (130:2824–2827) under a heavily blurred, 64% white veil (130:2828): the backdrop the
/// advisory screens and the FD page share
struct DecadeBackdrop: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xFCFCFC)
            Ellipse().fill(Color(hex: 0xF6F5DF))
                .frame(width: 165, height: 378)
                .at(97, 118)
                .blur(radius: 72)
            Ellipse().fill(Color(hex: 0xBBC5B0))
                .frame(width: 119.38, height: 273.04)
                .rotationEffect(.degrees(-86.94))
                .at(7 + (279.03 - 119.38) / 2, 559 + (133.8 - 273.04) / 2)
                .blur(radius: 72)
            Ellipse().fill(Color(hex: 0xF0F0F0))
                .frame(width: 359.54, height: 446)
                .rotationEffect(.degrees(-3.73))
                .at(171 + (387.81 - 359.54) / 2, -19 + (468.46 - 446) / 2)
                .blur(radius: 72)
            Ellipse().fill(Color(hex: 0xF0F0F0))
                .frame(width: 359.54, height: 446)
                .rotationEffect(.degrees(-3.73))
                .at(195 + 73.91 - 359.54 / 2, 422 + 93.23 - 446 / 2)
                .blur(radius: 72)
        }
        .frame(width: MutualFundScreen.canvasWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: 0xFCFCFC))
        // Each blob is blurred on its own: one blur over the whole layer left them as hard-edged rectangles
        .overlay(Color.white.opacity(0.64))
        .ignoresSafeArea()
    }
}
