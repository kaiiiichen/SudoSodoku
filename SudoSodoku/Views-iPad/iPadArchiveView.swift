import SwiftUI

/// iPad-optimized archive view
struct iPadArchiveView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var filterMode: FilterMode = .all
    @State private var selectedRecordForAction: GameRecord?
    @State private var showActionSheet = false
    @State private var navigateToGame = false
    @State private var gameToLoad: GameRecord?
    @State private var isEditMode: Bool = false
    @State private var selectedIds: Set<UUID> = []
    
    enum FilterMode { case all; case favorites }
    
    var filteredRecords: [GameRecord] {
        filterMode == .all ? storage.records : storage.records.filter { $0.isFavorite }
    }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            
            VStack(spacing: 0) {
                HStack {
                    Text(filterMode == .favorites ? "FAVORITES:" : "USER_LOGS:")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    if isEditMode {
                        Button(action: { isEditMode = false; selectedIds.removeAll() }) {
                            Text("DONE")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 30)
                .padding(.bottom, 18)
                
                if filteredRecords.isEmpty {
                    Spacer()
                    Text("NO_RECORDS_FOUND")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(filteredRecords) { record in
                                iPadArchiveRow(
                                    record: record,
                                    isEditMode: isEditMode,
                                    isSelected: selectedIds.contains(record.id),
                                    action: {
                                        if isEditMode {
                                            toggleSelection(for: record.id)
                                        } else {
                                            handleRecordTap(record)
                                        }
                                    },
                                    selectionAction: {
                                        toggleSelection(for: record.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                    .refreshable { storage.loadData() }
                }

                if isEditMode {
                    HStack {
                        Button(action: {
                            storage.batchDelete(ids: selectedIds)
                            isEditMode = false
                            selectedIds.removeAll()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("DELETE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.red)
                        }

                        Spacer()

                        Button(action: {
                            storage.batchFavorite(ids: selectedIds)
                            isEditMode = false
                            selectedIds.removeAll()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                Text("FAVORITE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.yellow)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 18)
                    .background(Color.white.opacity(0.08))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { filterMode = .all }) {
                        Label("Show All Logs", systemImage: "list.bullet")
                    }
                    Button(action: { filterMode = .favorites }) {
                        Label("Show Favorites", systemImage: "star.fill")
                    }
                    Divider()
                    Button(action: { isEditMode.toggle() }) {
                        Label("Batch Edit", systemImage: "checkmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
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
                if let rec = selectedRecordForAction { 
                    gameToLoad = rec.restartedCopy()
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
        .navigationBarTitleDisplayMode(.inline)
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

    func toggleSelection(for id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

/// iPad-optimized archive row
private struct iPadArchiveRow: View {
    let record: GameRecord
    let isEditMode: Bool
    let isSelected: Bool
    let action: () -> Void
    let selectionAction: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            if isEditMode {
                Button(action: selectionAction) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }

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
                    Text(isEditMode ? "SELECT" : "PLAY")
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
