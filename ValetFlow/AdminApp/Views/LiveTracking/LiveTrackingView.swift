import SwiftUI
import MapKit

struct LiveTrackingView: View {
    var body: some View {
        NavigationView {
            ZStack {
                Map()
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    Text("Live GPS tracking coming soon")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding()
                }
            }
            .navigationTitle("Live Tracking")
        }
    }
}
