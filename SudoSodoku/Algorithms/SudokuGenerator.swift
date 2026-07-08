import Foundation

struct SudokuGenerator {
    static let MAX_RAW_SCORE = 320.0
    static let MIN_RAW_SCORE = 30.0

    /// All 27 houses: 9 rows, 9 columns, 9 boxes.
    static let allUnits: [[Int]] = {
        var units: [[Int]] = []
        for row in 0..<9 { units.append((0..<9).map { row * 9 + $0 }) }
        for col in 0..<9 { units.append((0..<9).map { $0 * 9 + col }) }
        for box in 0..<9 {
            let origin = (box / 3) * 27 + (box % 3) * 3
            units.append((0..<9).map { origin + ($0 / 3) * 9 + $0 % 3 })
        }
        return units
    }()

    /// Minimum clues that must survive digging per row/column/box, so easier
    /// boards can't end up with near-empty regions (a top-dense board with a
    /// deserted bottom half dead-ends a human even when technically solvable).
    struct ClueFloors {
        let box: Int
        let row: Int
        let column: Int
    }

    static func clueFloors(for difficulty: Difficulty) -> ClueFloors {
        switch difficulty {
        case .easy: return ClueFloors(box: 3, row: 2, column: 2)
        case .medium: return ClueFloors(box: 2, row: 1, column: 1)
        case .hard: return ClueFloors(box: 1, row: 0, column: 0)
        case .master: return ClueFloors(box: 0, row: 0, column: 0)
        }
    }

    static func generatePuzzle(targetDifficulty: Difficulty) -> ([Int], [Int], Int) {
        let floors = clueFloors(for: targetDifficulty)
        let targetCenter = Double(targetDifficulty.scoreRange.lowerBound + targetDifficulty.scoreRange.upperBound) / 2.0

        // Best-effort fallbacks, preferring boards that pass the quality gate.
        var bestQualified: (board: [Int], solution: [Int], score: Int)?
        var bestAny: (board: [Int], solution: [Int], score: Int)?

        func isCloser(_ score: Int, than current: (board: [Int], solution: [Int], score: Int)?) -> Bool {
            guard let current else { return true }
            return abs(Double(score) - targetCenter) < abs(Double(current.score) - targetCenter)
        }

        let maxAttempts = 40
        for _ in 0..<maxAttempts {
            // A fresh solution grid per attempt: some grids simply cannot
            // yield a given technique tier under symmetric digging, and 40
            // digs of the same grid would all inherit that fate.
            let solvedBoard = generateSolvedBoard()

            let cluesToKeep: Int
            switch targetDifficulty {
            case .easy: cluesToKeep = Int.random(in: 36...50)
            case .medium: cluesToKeep = Int.random(in: 30...40)
            case .hard: cluesToKeep = Int.random(in: 24...32)
            case .master: cluesToKeep = Int.random(in: 20...25)
            }

            var puzzle = digHoles(solvedBoard: solvedBoard, targetClues: cluesToKeep, floors: floors)

            // Technique identity per difficulty, like hand-crafted books:
            // EASY reads as pure singles with breadth, MEDIUM never demands
            // more than intermediate techniques, HARD is designed around an
            // intermediate "aha" (required, but sufficient — no guessing),
            // MASTER resists even intermediate techniques.
            //
            // HARD/MASTER boards that come out too tame are progressively
            // deepened: keep digging symmetric pairs on the same board until
            // the tier is reached or nothing more can be dug.
            let qualifies: Bool
            switch targetDifficulty {
            case .easy:
                let analysis = solveWithSingles(puzzle: puzzle)
                qualifies = analysis.solved && analysis.minChoices >= 2
            case .medium:
                qualifies = techniqueTier(puzzle: puzzle) != .advanced
            case .hard, .master:
                let satisfied: (SolveTier) -> Bool = targetDifficulty == .hard
                    ? { $0 == .intermediate }
                    : { $0 == .advanced }
                var tier = techniqueTier(puzzle: puzzle)
                var clues = puzzle.filter { $0 != 0 }.count
                while !satisfied(tier), tier != .advanced, clues > 20 {
                    let deeper = digHoles(solvedBoard: puzzle, targetClues: clues - 2, floors: floors)
                    let deeperClues = deeper.filter { $0 != 0 }.count
                    guard deeperClues < clues else { break }
                    puzzle = deeper
                    clues = deeperClues
                    tier = techniqueTier(puzzle: puzzle)
                }
                qualifies = satisfied(tier)
            }

            let analysis = solveWithSingles(puzzle: puzzle)
            let normalizedScore = normalize(analysis.rawScore)

            if qualifies && targetDifficulty.scoreRange.contains(normalizedScore) {
                return (puzzle, solvedBoard, normalizedScore)
            }
            if qualifies && isCloser(normalizedScore, than: bestQualified) {
                bestQualified = (puzzle, solvedBoard, normalizedScore)
            }
            if isCloser(normalizedScore, than: bestAny) {
                bestAny = (puzzle, solvedBoard, normalizedScore)
            }
        }

        if let fallback = bestQualified ?? bestAny {
            return (fallback.board, fallback.solution, fallback.score)
        }
        let solved = generateSolvedBoard()
        return (solved, solved, 0)
    }

    static func normalize(_ raw: Int) -> Int {
        let percentage = (Double(raw) - MIN_RAW_SCORE) / (MAX_RAW_SCORE - MIN_RAW_SCORE)
        let score = Int(percentage * 100)
        return max(0, min(100, score))
    }

    /// How a singles-only solver (the model of a human on EASY) experiences
    /// the puzzle: total effort, whether it ever dead-ends, and the narrowest
    /// count of simultaneously available moves. The last 8 cells are exempt
    /// from the breadth measure — the endgame is naturally forced.
    struct SinglesAnalysis {
        let rawScore: Int
        let solved: Bool
        let minChoices: Int
    }

    static func solveWithSingles(puzzle: [Int]) -> SinglesAnalysis {
        var board = puzzle
        var score = 0
        var emptyCells = board.filter { $0 == 0 }.count
        var minChoices = Int.max

        while emptyCells > 0 {
            var nakedSingles: [Int] = []
            for index in 0..<81 where board[index] == 0 {
                if getCandidates(board: board, index: index).count == 1 {
                    nakedSingles.append(index)
                }
            }

            if !nakedSingles.isEmpty {
                if emptyCells > 8 { minChoices = min(minChoices, nakedSingles.count) }
                for index in nakedSingles {
                    let candidates = getCandidates(board: board, index: index)
                    guard candidates.count == 1 else { continue }
                    board[index] = candidates[0]
                    score += 1
                    emptyCells -= 1
                }
                continue
            }

            let hidden = hiddenSingles(board: board)
            if !hidden.isEmpty {
                if emptyCells > 8 { minChoices = min(minChoices, hidden.count) }
                for (index, value) in hidden where board[index] == 0 {
                    board[index] = value
                    score += 3
                    emptyCells -= 1
                }
                continue
            }

            // Requires techniques beyond singles.
            score += emptyCells * 5
            return SinglesAnalysis(rawScore: score, solved: false, minChoices: minChoices == .max ? 0 : minChoices)
        }

        return SinglesAnalysis(rawScore: score, solved: true, minChoices: minChoices == .max ? 9 : minChoices)
    }

    static func evaluateDifficulty(puzzle: [Int]) -> Int {
        solveWithSingles(puzzle: puzzle).rawScore
    }

    // MARK: - Technique tiers (the identity of each difficulty)

    /// The human technique level a puzzle demands, mirroring how published
    /// (hand-crafted) collections grade: EASY reads as singles, HARD is
    /// designed around an intermediate "aha", MASTER resists even that.
    enum SolveTier {
        case singles        // naked + hidden singles finish it
        case intermediate   // needs locked candidates and/or naked pairs
        case advanced       // resists all of the above
    }

    static let peersByCell: [[Int]] = (0..<81).map { index in
        let row = index / 9
        let col = index % 9
        var peers = Set<Int>()
        for i in 0..<9 {
            peers.insert(row * 9 + i)
            peers.insert(i * 9 + col)
            peers.insert(((row / 3) * 3 + i / 3) * 9 + (col / 3) * 3 + i % 3)
        }
        peers.remove(index)
        return Array(peers)
    }

    static func techniqueTier(puzzle: [Int]) -> SolveTier {
        var board = puzzle
        var candidates: [Set<Int>] = (0..<81).map {
            board[$0] == 0 ? Set(getCandidates(board: board, index: $0)) : []
        }
        var usedIntermediate = false

        func place(_ index: Int, _ value: Int) {
            board[index] = value
            candidates[index] = []
            for peer in peersByCell[index] {
                candidates[peer].remove(value)
            }
        }

        while true {
            // Singles first, to a fixpoint.
            if let index = (0..<81).first(where: { board[$0] == 0 && candidates[$0].count == 1 }) {
                place(index, candidates[index].first!)
                continue
            }

            var placedHiddenSingle = false
            hiddenScan: for unit in allUnits {
                var positions = [Int: [Int]]()
                for index in unit where board[index] == 0 {
                    for value in candidates[index] {
                        positions[value, default: []].append(index)
                    }
                }
                for (value, cells) in positions where cells.count == 1 {
                    place(cells[0], value)
                    placedHiddenSingle = true
                    break hiddenScan
                }
            }
            if placedHiddenSingle { continue }

            if !board.contains(0) {
                return usedIntermediate ? .intermediate : .singles
            }

            // Intermediate eliminations: locked candidates (pointing and
            // claiming) plus naked pairs. Any elimination re-enters the
            // singles loop.
            var eliminated = false

            // Pointing: within a box, a value confined to one row/column
            // eliminates that value from the rest of the line.
            for box in 18..<27 {
                let cells = allUnits[box]
                var positions = [Int: [Int]]()
                for index in cells where board[index] == 0 {
                    for value in candidates[index] {
                        positions[value, default: []].append(index)
                    }
                }
                for (value, spots) in positions where spots.count > 1 {
                    let rows = Set(spots.map { $0 / 9 })
                    let cols = Set(spots.map { $0 % 9 })
                    if let row = rows.first, rows.count == 1 {
                        for index in allUnits[row] where !cells.contains(index) {
                            if candidates[index].remove(value) != nil { eliminated = true }
                        }
                    }
                    if let col = cols.first, cols.count == 1 {
                        for index in allUnits[9 + col] where !cells.contains(index) {
                            if candidates[index].remove(value) != nil { eliminated = true }
                        }
                    }
                }
            }

            // Claiming: within a row/column, a value confined to one box
            // eliminates it from the rest of that box.
            for line in 0..<18 {
                let cells = allUnits[line]
                var positions = [Int: [Int]]()
                for index in cells where board[index] == 0 {
                    for value in candidates[index] {
                        positions[value, default: []].append(index)
                    }
                }
                for (value, spots) in positions where spots.count > 1 {
                    let boxes = Set(spots.map { ($0 / 9 / 3) * 3 + ($0 % 9) / 3 })
                    if let box = boxes.first, boxes.count == 1 {
                        for index in allUnits[18 + box] where !cells.contains(index) {
                            if candidates[index].remove(value) != nil { eliminated = true }
                        }
                    }
                }
            }

            // Naked pairs: two cells of a unit sharing the same two
            // candidates eliminate them from the unit's other cells.
            for unit in allUnits {
                let pairCells = unit.filter { board[$0] == 0 && candidates[$0].count == 2 }
                guard pairCells.count >= 2 else { continue }
                for i in 0..<(pairCells.count - 1) {
                    for j in (i + 1)..<pairCells.count where candidates[pairCells[i]] == candidates[pairCells[j]] {
                        for index in unit
                        where index != pairCells[i] && index != pairCells[j] && board[index] == 0 {
                            for value in candidates[pairCells[i]] {
                                if candidates[index].remove(value) != nil { eliminated = true }
                            }
                        }
                    }
                }
            }

            if eliminated {
                usedIntermediate = true
                continue
            }
            return .advanced
        }
    }

    static func getCandidates(board: [Int], index: Int) -> [Int] {
        var candidates: [Int] = []
        let row = index / 9
        let col = index % 9
        for num in 1...9 {
            if isValid(board, num, row, col) {
                candidates.append(num)
            }
        }
        return candidates
    }

    /// First hidden single, scanning all 27 houses. (A row-only scan here
    /// misgraded puzzles solvable via column/box logic as dead ends — the
    /// root cause of unfair "easy" boards.)
    static func findHiddenSingle(board: [Int]) -> (index: Int, value: Int)? {
        hiddenSingles(board: board).first
    }

    /// Every cell that is the only possible home for some value within one
    /// of its houses, deduplicated by cell.
    static func hiddenSingles(board: [Int]) -> [(index: Int, value: Int)] {
        var results: [(index: Int, value: Int)] = []
        var claimedCells = Set<Int>()

        for unit in allUnits {
            var counts = [Int](repeating: 0, count: 10)
            var positions = [Int](repeating: -1, count: 10)
            for index in unit where board[index] == 0 {
                for value in getCandidates(board: board, index: index) {
                    counts[value] += 1
                    positions[value] = index
                }
            }
            for value in 1...9 where counts[value] == 1 {
                let index = positions[value]
                if claimedCells.insert(index).inserted {
                    results.append((index, value))
                }
            }
        }
        return results
    }

    static func generateSolvedBoard() -> [Int] {
        var board = Array(repeating: 0, count: 81)
        _ = solve(&board)
        return board
    }

    static func solve(_ board: inout [Int]) -> Bool {
        guard let index = board.firstIndex(of: 0) else { return true }
        let numbers = (1...9).shuffled()
        for num in numbers {
            if isValid(board, num, index / 9, index % 9) {
                board[index] = num
                if solve(&board) { return true }
                board[index] = 0
            }
        }
        return false
    }

    static func isValid(_ board: [Int], _ num: Int, _ row: Int, _ col: Int) -> Bool {
        for i in 0..<9 {
            if board[row * 9 + i] == num { return false }
            if board[i * 9 + col] == num { return false }
            let r = (row / 3) * 3 + i / 3
            let c = (col / 3) * 3 + i % 3
            if board[r * 9 + c] == num { return false }
        }
        return true
    }

    /// Digs point-symmetric holes down to `targetClues`. Accepts a full
    /// solution or an already partially dug (symmetric) board, so callers
    /// can progressively deepen a puzzle.
    static func digHoles(solvedBoard: [Int], targetClues: Int, floors: ClueFloors) -> [Int] {
        var puzzle = solvedBoard
        var rowClues = [Int](repeating: 0, count: 9)
        var colClues = [Int](repeating: 0, count: 9)
        var boxClues = [Int](repeating: 0, count: 9)
        for index in 0..<81 where puzzle[index] != 0 {
            let row = index / 9
            let col = index % 9
            rowClues[row] += 1
            colClues[col] += 1
            boxClues[(row / 3) * 3 + col / 3] += 1
        }
        var holesToDig = puzzle.filter { $0 != 0 }.count - targetClues

        // Would digging every cell in the group keep all floors intact?
        func groupRespectsFloors(_ cells: [Int]) -> Bool {
            var rows = rowClues, cols = colClues, boxes = boxClues
            for idx in cells {
                let row = idx / 9
                let col = idx % 9
                let box = (row / 3) * 3 + col / 3
                rows[row] -= 1
                cols[col] -= 1
                boxes[box] -= 1
                if rows[row] < floors.row || cols[col] < floors.column || boxes[box] < floors.box {
                    return false
                }
            }
            return true
        }

        // Handmade puzzles (Nikoli style) place givens with 180-degree
        // rotational symmetry, so holes are dug in point-symmetric pairs
        // (the center cell pairs with itself). The clue pattern reads as
        // designed rather than scattered.
        for idx in Array(0...40).shuffled() {
            if holesToDig <= 0 { break }
            guard puzzle[idx] != 0 else { continue } // pair already dug
            let partner = 80 - idx
            let cells = idx == partner ? [idx] : [idx, partner]
            guard cells.count <= holesToDig, groupRespectsFloors(cells) else { continue }

            let backups = cells.map { puzzle[$0] }
            for cell in cells { puzzle[cell] = 0 }

            if countSolutions(board: puzzle, limit: 2) == 1 {
                holesToDig -= cells.count
                for cell in cells {
                    let row = cell / 9
                    let col = cell % 9
                    rowClues[row] -= 1
                    colClues[col] -= 1
                    boxClues[(row / 3) * 3 + col / 3] -= 1
                }
            } else {
                for (offset, cell) in cells.enumerated() { puzzle[cell] = backups[offset] }
            }
        }
        return puzzle
    }

    /// Bitmask MRV solution counter: row/column/box occupancy as 9-bit
    /// masks, candidates via bitwise complement, branching on the most
    /// constrained cell with contradiction pruning. This is the generator's
    /// hot path — it runs once per attempted dig.
    static func countSolutions(board: [Int], limit: Int) -> Int {
        var cells = board
        var rowMask = [Int](repeating: 0, count: 9)
        var colMask = [Int](repeating: 0, count: 9)
        var boxMask = [Int](repeating: 0, count: 9)
        for index in 0..<81 where cells[index] != 0 {
            let bit = 1 << (cells[index] - 1)
            rowMask[index / 9] |= bit
            colMask[index % 9] |= bit
            boxMask[(index / 9 / 3) * 3 + (index % 9) / 3] |= bit
        }

        var count = 0

        func search() {
            if count >= limit { return }

            var bestIndex = -1
            var bestMask = 0
            var bestOptions = 10
            for index in 0..<81 where cells[index] == 0 {
                let row = index / 9
                let col = index % 9
                let box = (row / 3) * 3 + col / 3
                let mask = ~(rowMask[row] | colMask[col] | boxMask[box]) & 0x1FF
                let options = mask.nonzeroBitCount
                if options == 0 { return } // contradiction: dead branch
                if options < bestOptions {
                    bestOptions = options
                    bestIndex = index
                    bestMask = mask
                    if options == 1 { break }
                }
            }
            guard bestIndex != -1 else {
                count += 1
                return
            }

            let row = bestIndex / 9
            let col = bestIndex % 9
            let box = (row / 3) * 3 + col / 3
            var mask = bestMask
            while mask != 0 {
                let bit = mask & -mask
                mask &= mask - 1
                cells[bestIndex] = bit.trailingZeroBitCount + 1
                rowMask[row] |= bit
                colMask[col] |= bit
                boxMask[box] |= bit
                search()
                rowMask[row] &= ~bit
                colMask[col] &= ~bit
                boxMask[box] &= ~bit
                cells[bestIndex] = 0
                if count >= limit { return }
            }
        }

        search()
        return count
    }
}
