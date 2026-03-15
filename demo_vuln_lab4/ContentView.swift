import SwiftUI
internal import Combine

// Basic model for the PokéAPI response
struct Pokemon: Codable {
    let name: String
    let weight: Int
    let height: Int
}

@MainActor
class PokedexViewModel: ObservableObject {
    @Published var currentPokemon: Pokemon?
    @Published var errorMessage: String?
    
    // VULNERABLE: Uses the default shared session which caches HTTP responses to disk.
    func fetchPokemonVulnerable(name: String) async {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(name.lowercased())") else { return }
        
        do {
            // URLSession.shared automatically caches decrypted data at rest
            let (data, _) = try await URLSession.shared.data(from: url)
            self.currentPokemon = try JSONDecoder().decode(Pokemon.self, from: data)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = PokedexViewModel()
    @State private var searchName = "pikachu"
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Pokémon Name", text: $searchName)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Fetch Data (Vulnerable)") {
                Task {
                    await viewModel.fetchPokemonVulnerable(name: searchName)
                }
            }
            .buttonStyle(.borderedProminent)
            
            if let pokemon = viewModel.currentPokemon {
                Text("Name: \(pokemon.name.capitalized)")
                    .font(.title)
                Text("Weight: \(pokemon.weight)")
                Text("Height: \(pokemon.height)")
            }
        }
        .padding()
    }
}
