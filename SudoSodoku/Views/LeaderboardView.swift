import GameKit
import SwiftUI

struct LeaderboardView: View {
    enum Board: String, CaseIterable, Identifiable {
        case elo = "ELO"
        case easy = "EASY"
        case medium = "MEDIUM"
        case hard = "HARD"
        case master = "MASTER"

        var id: String { rawValue }

        var leaderboardID: String {
            self == .elo
                ? AppConstants.eloLeaderboardID
                : AppConstants.leaderboardID(for: rawValue)
        }
    }

    private enum LoadState {
        case loading
        case loaded(local: GKLeaderboard.Entry?, entries: [GKLeaderboard.Entry])
        case failed(String)
    }

    @ObservedObject private var gcManager = GameCenterManager.shared
    @State private var selectedBoard: Board = .elo
    @State private var state: LoadState = .loading

    var body: some View {
        ZStack {
            TerminalBackground()
            VStack(alignment: .leading, spacing: 16) {
                Text("GLOBAL_RANKINGS:")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)

                boardPicker

                if gcManager.isAuthenticated {
                    content
                } else {
                    guestNotice
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedBoard) { await load() }
        .onChange(of: gcManager.isAuthenticated) { _, authenticated in
            if authenticated { Task { await load() } }
        }
        // Native Game Center overlay as a fallback entry point while this
        // screen is visible.
        .onAppear {
            GKAccessPoint.shared.location = .topTrailing
            GKAccessPoint.shared.isActive = true
        }
        .onDisappear { GKAccessPoint.shared.isActive = false }
    }

    // MARK: - Sections

    private var boardPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Board.allCases) { board in
                    Button(action: { selectedBoard = board }) {
                        Text(board.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedBoard == board ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                            .foregroundColor(selectedBoard == board ? .green : .gray)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedBoard == board ? Color.green : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                ProgressView().tint(.green)
                Text("querying game center...")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)

        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text("ERR: \(message)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.red)
                Button(action: { Task { await load() } }) {
                    Text("> RETRY")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            .padding(.top, 20)

        case .loaded(let local, let entries):
            if entries.isEmpty {
                Text("NO_ENTRIES_YET // be the first to breach")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(entries, id: \.rank) { entry in
                            entryRow(entry, isLocalPlayer: isLocal(entry))
                        }
                    }
                }
                .refreshable { await load() }

                if let local, !entries.contains(where: { isLocal($0) }) {
                    Divider().background(Color.gray.opacity(0.3))
                    entryRow(local, isLocalPlayer: true)
                }
            }
        }
    }

    private var guestNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTH_REQUIRED")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            Text("sign in to Game Center to access global rankings\n(Settings > Games)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.top, 20)
    }

    private func entryRow(_ entry: GKLeaderboard.Entry, isLocalPlayer: Bool) -> some View {
        HStack(spacing: 10) {
            Text(String(format: "#%02d", entry.rank))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(rankColor(entry.rank))
            Text(isLocalPlayer ? "\(entry.player.displayName) <you>" : entry.player.displayName)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(isLocalPlayer ? .green : .white)
                .lineLimit(1)
            Spacer()
            Text(entry.formattedScore)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isLocalPlayer ? Color.green.opacity(0.12) : Color.white.opacity(0.03))
        .cornerRadius(8)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2, 3: return .cyan
        default: return .gray
        }
    }

    private func isLocal(_ entry: GKLeaderboard.Entry) -> Bool {
        entry.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
    }

    // MARK: - Loading

    private func load() async {
        guard gcManager.isAuthenticated else { return }
        state = .loading
        do {
            guard let leaderboard = try await GKLeaderboard
                .loadLeaderboards(IDs: [selectedBoard.leaderboardID]).first else {
                state = .failed("leaderboard_not_configured")
                return
            }
            let (local, entries, _) = try await leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 25)
            )
            state = .loaded(local: local, entries: entries)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
