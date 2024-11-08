import SwiftUI

struct SettingsView: View {
    
    @AppStorage("UnsplashAPIKey") private var unsplashApiKey: String = ""
    @AppStorage("OpenWeatherMapAPIKey") private var weatherApiKey: String = ""
    @AppStorage("OpenAIAPIKey") private var openAIAPIKey: String = ""
        
    @State private var showSaveConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            // API Key Table
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Unsplash API Key")
                        .frame(width: 150, alignment: .leading)
                    TextField("Enter Unsplash API Key", text: $unsplashApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                }

                HStack {
                    Text("OpenWeatherMap API Key")
                        .frame(width: 150, alignment: .leading)
                    TextField("Enter OpenWeatherMap API Key", text: $weatherApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                }
                HStack {
                    Text("OpenAI API Key")
                        .frame(width: 150, alignment: .leading)
                    TextField("Enter OpenAI API Key", text: $openAIAPIKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 300)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            
            Spacer()

            // Save Button with Clear Background
            Button(action: {
                showSaveConfirmation = true
            }) {
                Text("Save Changes")
                    .font(.headline)
                    .foregroundColor(.blue) // Text color only, no background color
                    .padding()
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle()) // Ensures the button has no additional background styling
            .padding([.leading, .trailing, .bottom], 20)
            .alert(isPresented: $showSaveConfirmation) {
                Alert(title: Text("Settings Saved"), message: Text("Your API keys have been saved."), dismissButton: .default(Text("OK")))
            }
        }
        .frame(width: 500, height: 250)
    }
}
