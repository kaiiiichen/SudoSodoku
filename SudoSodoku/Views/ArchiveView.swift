import SwiftUI

struct ArchiveView: View {
    @ObservedObject var storage = StorageManager.shared
    @State private var selectedRecordForAction: GameRecord?
    @State private var showActionSheet = false
    @State private var navigateToGame = false
    @State private var gameToLoad: GameRecord?
    @State private var filterMode: FilterMode = .all
    @State private var isEditMode: Bool = false
    @State private var selectedIds: Set<UUID> = []
    
    enum FilterMode { case all; case favorites }
    var filteredRecords: [GameRecord] { filterMode == .all ? storage.records : storage.records.filter { $0.isFavorite } }
    
    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading) {
                HStack {
                    Text(filterMode == .favorites ? "FAVORITES:" : "USER_LOGS:")
                        .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.gray)
                    Spacer()
                    if isEditMode {
                        Button(action: { isEditMode = false; selectedIds.removeAll() }) { Text("DONE").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(.green) }
                    }
                }.padding(.leading).padding(.trailing).padding(.top)
                
                if filteredRecords.isEmpty {
                    Spacer(); Text("NO_RECORDS_FOUND").font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.5)).frame(maxWidth: .infinity); Spacer()
                } else {
                    List {
                        ForEach(filteredRecords) { record in
                            HStack {
                                if isEditMode {
                                    Image(systemName: selectedIds.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedIds.contains(record.id) ? .green : .gray)
                                        .onTapGesture { if selectedIds.contains(record.id) { selectedIds.remove(record.id) } else { selectedIds.insert(record.id) } }
                                }
                                Button(action: {
                                    if isEditMode { if selectedIds.contains(record.id) { selectedIds.remove(record.id) } else { selectedIds.insert(record.id) } }
                                    else { handleRecordTap(record) }
                                }) { RecordRow(record: record) }
                            }
                            .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain).refreshable { storage.loadData() }
                }
                
                if isEditMode {
                    HStack {
                        Button(action: { storage.batchDelete(ids: selectedIds); isEditMode = false; selectedIds.removeAll() }) {
                            VStack { Image(systemName: "trash"); Text("DELETE") }.foregroundColor(.red)
                        }
                        Spacer()
                        Button(action: { storage.batchFavorite(ids: selectedIds); isEditMode = false; selectedIds.removeAll() }) {
                            VStack { Image(systemName: "star.fill"); Text("FAVORITE") }.foregroundColor(.yellow)
                        }
                    }.padding().background(Color.white.opacity(0.1))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { filterMode = .all }) { Label("Show All Logs", systemImage: "list.bullet") }
                        Button(action: { filterMode = .favorites }) { Label("Show Favorites", systemImage: "star.fill") }
                        Divider()
                        Button(action: { isEditMode.toggle() }) { Label("Batch Edit", systemImage: "checkmark.circle") }
                    } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)).foregroundColor(.green) }
                }
            }
            .navigationDestination(isPresented: $navigateToGame) { if let rec = gameToLoad { GameView(record: rec) } }
            .confirmationDialog("COMPLETED_TASK", isPresented: $showActionSheet) {
                Button("RESTART (sudo reboot)") { if var rec = selectedRecordForAction { rec.isSolved = false; gameToLoad = rec; navigateToGame = true } }
                Button("SHOW ANSWER (cat solution)") { if let rec = selectedRecordForAction { gameToLoad = rec; navigateToGame = true } }
                Button("CANCEL", role: .cancel) { }
            }
        }.navigationBarTitleDisplayMode(.inline).onAppear { storage.loadData() }
    }
    
    func handleRecordTap(_ record: GameRecord) {
        selectedRecordForAction = record
        if record.isSolved { showActionSheet = true } else { gameToLoad = record; navigateToGame = true }
    }
}

