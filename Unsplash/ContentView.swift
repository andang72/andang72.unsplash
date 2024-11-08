import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
       @State private var weatherInfo: String = "Loading weather..."
       @AppStorage("OpenWeatherMapAPIKey") private var openWeatherMapApiKey: String = ""
       @AppStorage("UnsplashAPIKey") private var unsplashApiKey: String = ""
       @AppStorage("OpenAIAPIKey") private var openAIAPIKey: String = "" // OpenAI API 키 저장
        
       @State private var image: NSImage? = nil
       @State private var quote: String = ""
       @State private var translatedQuote: String = ""
       @State private var isLoading = false
       @State private var imageTitle: String = ""
       @State private var authorName: String = ""
       @State private var authorProfileImage: NSImage? = nil
       @State private var isUnsplashImage = false // Unsplash 이미지를 표시할 때만 true
       @State private var showTranslatedQuote = false // 번역을 표시할지 여부를 관리하는 상태 변수
    
       var body: some View {
           GeometryReader { geometry in
               ZStack {
                   ImageView(image: image)
                       .frame(width: geometry.size.width, height: geometry.size.height)
                       .clipped()
                   
                   VStack {
                       Spacer()
                       if isLoading {
                           ProgressView()
                               .scaleEffect(2)
                               .progressViewStyle(CircularProgressViewStyle(tint: .white))
                               .padding(.bottom, 20)
                       }
                       if !quote.isEmpty {
                           TypewriterText(text: quote){
                               showTranslatedQuote = true
                           }
                                   .font(.title)
                                   .foregroundColor(.white)
                                   .padding()
                                   .background(Color.black.opacity(0.2))
                                   .cornerRadius(1)
                                   .padding(.bottom, 0)
                           
                                    if showTranslatedQuote && !translatedQuote.isEmpty {
                                               Text("번역: \(translatedQuote)")
                                                   .font(.title3)
                                                   .foregroundColor(.white)
                                                   .multilineTextAlignment(.center)
                                                   .padding(.top, 1)
                                                   .padding([.leading, .bottom], 0)
                                                   //.background(Color.black.opacity(0.2))
                               
                                    }
 
                       }
                       
                   }.frame(maxWidth: .infinity)
                       .padding([.leading, .bottom], 90)
                   
                   VStack {
                       HStack {
                           Spacer()
                           VStack(alignment: .trailing) {
                               WeatherView(locationString: $locationManager.locationString, weatherInfo: weatherInfo)
                           }
                           .padding(.trailing, 20)
                           .padding(.top, 40)
                       }
                       Spacer()
                   }
                    
                   // Unsplash 이미지일 경우에만 하단 좌측에 작성자 정보 및 이미지 제목 표시
                                  if isUnsplashImage {
                                      VStack {
                                          Spacer()
                                          HStack {
                                              if let authorProfileImage = authorProfileImage {
                                                  Image(nsImage: authorProfileImage)
                                                      .resizable()
                                                      .frame(width: 40, height: 40)
                                                      .clipShape(Circle())
                                                      .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                              }
                                              
                                              VStack(alignment: .leading) {
                                                  Text(imageTitle)
                                                      .font(.caption)
                                                      .foregroundColor(.white)
                                                  Text("by \(authorName)")
                                                      .font(.caption2)
                                                      .foregroundColor(.white.opacity(0.8))
                                              }
                                              Spacer()
                                          }
                                          .padding()
                                          .background(Color.black.opacity(0.2))
                                          .cornerRadius(0)
                                          .padding([.leading, .bottom], 0)
                                      }
                                  }
               }
               .onAppear {
                   if unsplashApiKey.isEmpty {
                       print("Unsplash API Key is missing. Please go to Settings to set it.")
                   } else {
                       fetchRandomLocalImage()
                   }
                   locationManager.requestLocation()
               }
               .onReceive(locationManager.$userLocation) { newLocation in
                   if let location = newLocation {
                       fetchWeather(latitude: location.latitude, longitude: location.longitude)
                   }
               }
               .onTapGesture {
                   fetchImageAndQuote()
               }
           }
           .edgesIgnoringSafeArea(.all)
       }
    
    // 날씨 정보를 가져오는 함수
    private func fetchWeather(latitude: Double, longitude: Double) {
        guard !openWeatherMapApiKey.isEmpty else {
            print("Error: OpenWeatherMap API Key is missing.")
            return
        }
        
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(openWeatherMapApiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid weather URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching weather data: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Error: Received HTTP status code \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received for weather.")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let main = json["main"] as? [String: Any],
                   let temp = main["temp"] as? Double,
                   let weatherArray = json["weather"] as? [[String: Any]],
                   let weather = weatherArray.first,
                   let description = weather["description"] as? String,
                   let cityName = json["name"] as? String {
                    
                    let weatherText = "\(cityName): \(description.capitalized), \(Int(temp))°C"
                    DispatchQueue.main.async {
                        self.weatherInfo = weatherText
                    }
                } else {
                    print("Error: Required fields missing or data type mismatch in weather JSON.")
                }
            } catch {
                print("Error parsing JSON for weather: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func fetchImageAndQuote() {
        showTranslatedQuote = false
        isLoading = true
        image = nil
        fetchImageFromUnsplash()
    }
    
    private func fetchImageFromUnsplash() {
            guard !unsplashApiKey.isEmpty, let url = URL(string: "https://api.unsplash.com/photos/random?client_id=\(unsplashApiKey)") else {
                print("Error: Unsplash API Key is missing or invalid URL.")
                fetchRandomLocalImage()
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { isLoading = false }
                
                if let error = error {
                    print("Error fetching image: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.fetchRandomLocalImage()
                    }
                    return
                }
                
                guard let data = data else {
                    print("Error: No data received.")
                    DispatchQueue.main.async {
                        self.fetchRandomLocalImage()
                    }
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let urls = json["urls"] as? [String: String],
                       let imageUrlString = urls["regular"],
                       let imageUrl = URL(string: imageUrlString),
                       let user = json["user"] as? [String: Any],
                       let authorName = user["name"] as? String,
                       let profileImageUrls = user["profile_image"] as? [String: String],
                       let profileImageUrlString = profileImageUrls["small"],
                       let profileImageUrl = URL(string: profileImageUrlString),
                       let description = json["description"] as? String {
                        
                        self.imageTitle = description
                        self.authorName = authorName
                        self.isUnsplashImage = true // Unsplash 이미지임을 설정
                        DispatchQueue.main.async {
                            self.downloadImage(from: imageUrl)
                            self.downloadAuthorProfileImage(from: profileImageUrl)
                        }
                    } else {
                        print("Error: Could not parse JSON.")
                        DispatchQueue.main.async {
                            self.fetchRandomLocalImage()
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.fetchRandomLocalImage()
                    }
                }
            }.resume()
        }
        
        private func downloadImage(from url: URL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let nsImage = NSImage(data: data) else {
                    if let error = error {
                        print("Error downloading image: \(error.localizedDescription)")
                    } else {
                        print("Error: Unable to create image from data.")
                    }
                    DispatchQueue.main.async {
                        self.fetchRandomLocalImage()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.image = nsImage
                    self.fetchRandomQuote() // 이미지가 로드된 후에 명언을 가져옴
                }
            }.resume()
        }
        
        private func downloadAuthorProfileImage(from url: URL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data, let nsImage = NSImage(data: data) else {
                    print("Error downloading author profile image: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    self.authorProfileImage = nsImage
                }
            }.resume()
        }
    
    private func fetchRandomLocalImage() {
        let imageNames = (1...8).map { "\($0)" }
        guard let randomImageName = imageNames.randomElement(), let nsImage = NSImage(named: randomImageName) else {
            print("Error: Could not load local image.")
            self.image = nil
            return
        }
        self.isUnsplashImage = false // Unsplash 이미지가 아님을 설정
        self.image = nsImage
        self.fetchRandomQuote()
    }

    private func fetchRandomQuote() {
        guard let url = URL(string: "https://zenquotes.io/api/random") else {
            print("Error: Invalid URL for quote.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching quote: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Error: No data received for quote.")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let quoteData = jsonArray.first,
                   let quoteText = quoteData["q"] as? String,
                   let quoteAuthor = quoteData["a"] as? String {
                    
                    let fullQuote = "\(quoteText) - \(quoteAuthor)"
                    DispatchQueue.main.async {
                        self.quote = fullQuote
                        self.translateQuoteToKorean(fullQuote)
                    }
                } else {
                    print("Error: Could not parse quote JSON.")
                }
            } catch {
                print("Error parsing JSON for quote: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // ChatGPT API를 사용하여 영어 명언을 한국어로 번역하는 함수
    func translateQuoteToKorean(_ quote: String) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("Error: Invalid URL for OpenAI API")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = "Translate this quote to Korean: \(quote)"
        let parameters: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "user", "content": prompt ]
            ],
            "max_tokens": 60
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Error: Failed to serialize JSON for request body - \(error)")
            return
        }
        
        print("Sending request to ChatGPT API with prompt: \(prompt)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: Network request failed - \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Received HTTP response: \(httpResponse.statusCode)")
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                    print("Quota exceeded. Please check your API plan and usage.")
                    // 사용자에게 할당량 초과 메시지를 표시하는 로직 추가
                    //return
            }
            
            guard let data = data else {
                print("Error: No data received from ChatGPT API")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Received JSON response: \(json)")
                    
                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let translatedText = message["content"] as? String {
                        
                        DispatchQueue.main.async {
                            self.translatedQuote = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    } else {
                        print("Error: Unexpected JSON structure or missing 'choices' key")
                    }
                }
            } catch {
                print("Error: Failed to parse JSON response - \(error)")
            }
        }.resume()
    }
    
}

struct ImageView: View {
    var image: NSImage?
    
    var body: some View {
        if let image = image {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Color.gray
        }
    }
}

struct TypewriterText: View {
    var text: String
    var onComplete: (() -> Void)? = nil // 타입 효과 완료 시 호출되는 클로저
    @State private var displayedText: String = ""
    @State private var currentIndex: Int = 0
    @State private var typingTimer: Timer? = nil
    private let typingSpeed = 0.07

    var body: some View {
        Text(displayedText)
            .onAppear {
                startTyping()
            }
            .onChange(of: text) {
                resetTyping()
                startTyping()
            }
    }
    
    private func startTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedText = ""
        currentIndex = 0
        
        typingTimer = Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentIndex < text.count {
                let index = text.index(text.startIndex, offsetBy: currentIndex)
                displayedText.append(text[index])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                onComplete?() // 타이핑이 완료되면 onComplete 클로저 호출
            }
        }
    }

    private func resetTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedText = ""
        currentIndex = 0
    }
}

struct WeatherView: View {
    @Binding var locationString: String?
    let weatherInfo: String

    var body: some View {
        VStack(alignment: .trailing) {
            Text(weatherInfo)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .padding(.trailing, 20)
        }
        .padding(.top, 40)
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationString: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLocation = location.coordinate
            locationString = "Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
