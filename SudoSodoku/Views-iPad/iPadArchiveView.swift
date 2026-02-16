import SwiftUI

/// iPad-optimized archive view
struct iPadArchiveView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedRecordForAction: GameRecord?
    @State private var showActionSheet = false
    @State private var navigateToGame = false
    @State private var gameToLoad: GameRecord?
    
    enum FilterOption: String, CaseIterable {
        case all = "ALL"
        case archived = "ARCHIVED"
        case favorites = "FAVORITES"
        case solved = "SOLVED"
    }
    
    var filteredRecords: [GameRecord] {
        switch selectedFilter {
        case .all:
            return storage.records
        case .archived:
            return storage.records.filter { $0.isArchived }
        case .favorites:
            return storage.records.filter { $0.isFavorite }
        case .solved:
            return storage.records.filter { $0.isSolved }
        }
    }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            
            VStack(spacing: 0) {
                // Header with filter options
                VStack(spacing: 20) {
                    Text("GAME_ARCHIVES")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Filter buttons
                    HStack(spacing: 15) {
                        ForEach(FilterOption.allCases, id: \.self) { filter in
                            iPadFilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                
                // Archive list
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredRecords) { record in
                            iPadArchiveRow(record: record) {
                                handleRecordTap(record)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationDestination(isPresented: $navigateToGame) { 
            if let rec = gameToLoad { 
                iPadGameView(record: rec) 
            } 
        }
        .confirmationDialog("COMPLETED_TASK", isPresented: $showActionSheet) {
            Button("RESTART (sudo reboot)") { 
                if var rec = selectedRecordForAction { 
                    rec.isSolved = false; 
                    gameToLoad = rec; 
                    navigateToGame = true 
                } 
            }
            Button("SHOW ANSWER (cat solution)") { 
                if let rec = selectedRecordForAction { 
                    gameToLoad = rec; 
                    navigateToGame = true 
                } 
            }
            Button("CANCEL", role: .cancel) { }
        }
        .onAppear { 
            storage.loadData() 
            GameCenterManager.shared.authenticateUser()
        }
    }
    
    func handleRecordTap(_ record: GameRecord) {
        selectedRecordForAction = record
        if record.isSolved { 
            showActionSheet = true 
        } else { 
            gameToLoad = record; 
            navigateToGame = true 
        }
    }
}

/// iPad-optimized filter button
private struct iPadFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.green : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.clear : Color.gray, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// iPad-optimized archive row
private struct iPadArchiveRow: View {
    let record: GameRecord
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Left side - Game info
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(record.difficulty.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Difficulty(rawValue: record.difficulty)?.color ?? .gray)
                    
                    Spacer()
                    
                    if record.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.yellow)
                    }
                    
                    if record.isArchived {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text("PROGRESS: \(record.progress)%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    if record.isSolved {
                        Text("SOLVED")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                
                Text(DateFormatter.archiveDate.string(from: record.lastPlayedTime))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Right side - Play button
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("PLAY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)
            }
        }
        .padding(.all, 25)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Date formatter for archive display
extension DateFormatter {
    static let archiveDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy HH:mm"
        return formatter
    }()
}
