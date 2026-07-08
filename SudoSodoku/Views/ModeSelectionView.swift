import SwiftUI

/// Difficulty selection as a live terminal: the command line up top awaits
/// its flag, the menu below is tab completion. Picking a flag types it into
/// the command, the command "executes", and the breach begins — flowing into
/// the loading log, which opens with this very command.
struct ModeSelectionView: View {
    /// The shell session so far, e.g. "sudo sudosodoku" — echoed back before this
    /// screen's own "breach" subcommand so the whole run reads as one line.
    var commandPrefix: String = "sudo sudosodoku"

    @State private var launchDifficulty: Difficulty?
    @State private var composerKey = UUID()

    var body: some View {
        ZStack {
            TerminalBackground()
            TerminalCommandComposer(
                awaitingComment: "# awaiting breach parameters",
                baseCommand: "\(commandPrefix) breach",
                completionComment: "# tab_completion:",
                options: Difficulty.allCases.map { difficulty in
                    CommandOption(
                        id: difficulty.rawValue,
                        label: difficulty.flag,
                        detail: "DIFFICULTY_INDEX: \(difficulty.scoreRange.lowerBound)-\(difficulty.scoreRange.upperBound)",
                        color: difficulty.color
                    )
                },
                hint: "# hint: higher difficulty_index -> higher elo yield",
                onExecute: { option in
                    launchDifficulty = Difficulty(rawValue: option.id)
                },
                hero: { EmptyView() }
            )
            .id(composerKey)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $launchDifficulty) { difficulty in
            GameView(difficulty: difficulty)
        }
        .onAppear {
            // Fresh composer state each time this screen is entered, including
            // when returning from a finished game.
            composerKey = UUID()
        }
    }
}
