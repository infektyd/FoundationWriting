import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to the Writing Coach App!")
                .font(.headline)
                .padding(.bottom)
            
            TextEditor(text: $viewModel.userInput)
                .border(Color.gray, width: 1)
                .padding()
                .frame(height: 200)
            
            Button(action: {
                Task {
                    await viewModel.performAnalysis()
                    await viewModel.generateLearningRoadmap()
                }
            }) {
                Text("Analyze and Learn")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.bottom)
            
            Text("Analysis Result:")
                .font(.headline)
                .padding(.top)
            
            Text(viewModel.analysisResult)
                .padding()
                .foregroundColor(.secondary)
            
            FeedbackView(suggestions: viewModel.improvementSuggestions)
                .padding()
            
            LearningRoadmapView(roadmap: viewModel.learningRoadmap)
                .padding()
        }
        .padding()
    }
}

struct FeedbackView: View {
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(suggestions, id: \.self) { suggestion in
                Text("• \(suggestion)")
            }
        }
    }
}

struct LearningRoadmapView: View {
    let roadmap: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Learning Roadmap")
                .font(.headline)
                .padding(.bottom)
            Text(roadmap)
                .foregroundColor(.secondary)
        }
    }
}

// Preview the view in the SwiftUI canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
