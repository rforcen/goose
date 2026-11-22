// sudoku problem generator
// implements a recursive and linear approach
/*
    usage:

        var sudoku = newSudoku(5);
        sudoku.shuffle();

        let cells = sudoku.emptyCellsList();
        sudoku.solve_nr(cells);

        sudoku.print();
        assert(sudoku.test());

*/
import std;
import os;

var rng = rng { random_seed() };

let MAX_N = 10;
let MAX_MOVES = MAX_N * MAX_N + 1;
let Array_MAX_MOVES = [0 as i32; MAX_MOVES];
let EMPTY_CELL = 0;

// Sudoku struct
struct Soduku {
    n:       i32,
    nxn:     i32,
    n_moves: i32,
    grid:    i32[>..],
}

// Create a new Sudoku instance
fn newSudoku(n: i32) -> Soduku {
    assert(n < MAX_N);

    var s = Soduku {
        n:       n,
        nxn:     n * n,
        grid:    [],
        n_moves: 0,
    };
    s.fillGrid();

    return s;
}

// Fill the grid with a valid Sudoku pattern
fn fillGrid(s: Soduku&) {
    for r in s.nxn {
        for c in s.nxn {
            s.grid.push((s.n * (r % s.n) + r / s.n + c) % s.nxn + 1);
        }
    }
}

// Generate a random integer in the range [min, max]
fn random_range(min: i32, max: i32) -> i32 {
    return (rng.rand_range(min, max - min + 1) + 1) as i32;
}

// Generate a random float in the range [0, 1)
fn rand_f32() -> f32 {
    return rng.rand_f32();
}

fn rnd_list(start: i32, end: i32) -> i32[>..] {
    var arr: i32[>..] = [];
    for i in start..end {
        arr.push(i);
    }
    shuffle(arr, rng);
    return arr;
}

inline fn getCell(s: Soduku&, r: i32, c: i32) -> i32 {
    return s.grid[r * s.nxn + c];
}
inline fn setCell(s: Soduku&, r: i32, c: i32, value: i32) {
    s.grid[r * s.nxn + c] = value;
}

fn print(s: Soduku&) {
    // convert a u8 to string
    fn to_string(ch: u8) -> u8[>..] {
        var ss: u8[>..] = "";
        ss.push(ch);
        return ss;
    }

    fn repeat(ch: u8, count: i32) -> u8[>..] {
        var res: u8[>..] = "";
        for _ in count {
            res.push(ch);
        }
        return res;
    }
    fn line() -> u8[>..] {
        var ret = repeat('-', s.nxn * 2 + 1);
        ret.push('\n');
        return ret;
    }
    fn is_mod(r: i32, n: i32) -> bool {
        return r != 0 && (r + 1) % n == 0;
    }

    const _symbols = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",

        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",

        "α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ", "λ", "μ",
        "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ", "φ", "χ", "ψ", "ω",

        "а", "б", "в", "г", "д", "е", "ж", "з", "и", "й", "к", "л", "м",
        "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ",
        "ъ", "ы", "ь", "э", "ю", "я",

        "א", "ב", "ג", "ד", "ה", "ו", "ז", "ח", "ט", "י", "כ", "ך",
        "ל", "מ", "ם", "נ", "ן", "ס", "ע", "פ", "ף", "צ", "ץ", "ק", "ר", "ש", "ת",
    ];

    var buffer: u8[>..] = [];
    var dashes = line();

    format(buffer, "Sudoku ", s.n, "x", s.n, "\n", dashes);

    for r in s.nxn {
        buffer.push('|');
        for c in s.nxn {
            let g = s.getCell(r, c);
            if g == 0 {
                format(buffer, " ");
            } else if s.nxn < _symbols.len {
                format(buffer, _symbols[g]);
            } else {
                format(buffer, g);
            }
            format(buffer, if is_mod(c, s.n) { "|" } else { " " });
        }
        format(buffer, "\n", if is_mod(r, s.n) { dashes } else { "" });
    }
    write_stdout(buffer);
}

fn create_seen(s: Soduku&) -> bool[>..] {
    var seen: bool[>..] = [];
    for _ in s.nxn + 1 {
        seen.push(false);
    }
    return seen;
}

fn test(s: Soduku&) -> bool {
    // any empty?
    if (any(s.grid) { x => x == EMPTY_CELL }) {
        false
    }

    // row check
    var row_fail = false;
    for r in s.nxn {
        var seen = s.create_seen();

        for c in s.nxn {
            var val = s.getCell(r, c);
            if seen[val] {
                row_fail = true;
                break;
            }
            seen[val] = true;
        }
        if row_fail {
            false
        }
    }
    // col check
    var col_fail = false;
    for c in s.nxn {
        var seen = s.create_seen();

        for r in s.nxn {
            var val = s.getCell(r, c);
            if seen[val] {
                col_fail = true;
                break;
            }
            seen[val] = true;
        }
        if col_fail {
            false
        }
    }

    // We flatten the block grid to use prange effectively
    var num_blocks = s.nxn;
    var block_fail = false;
    for b_idx in num_blocks {
        var seen = s.create_seen();

        var br = (b_idx / s.n) * s.n;
        var bc = (b_idx % s.n) * s.n;
        for r in br..(br + s.n) {
            for c in bc..(bc + s.n) {
                var val = s.getCell(r, c);
                if seen[val] {
                    block_fail = true;
                    break;
                }
                seen[val] = true;
            }
            if block_fail {
                false
            }
        }
    }

    true
}

// must define return array as fixed size array due to recursive restrictions
fn moves(s: Soduku&, r: i32, c: i32) -> i32[MAX_MOVES], i32 {
    if s.getCell(r, c) != 0 { return Array_MAX_MOVES, 0 }

    var seen = s.create_seen();

    // row & col
    for i in s.nxn {
        seen[s.getCell(r, i)] = true;
        seen[s.getCell(i, c)] = true;
    }
   
    // block
    var rb = (r / s.n) * s.n;
    var cb = (c / s.n) * s.n;

    for i in rb..(rb + s.n) {
        for j in cb..(cb + s.n) {
            seen[s.getCell(i, j)] = true;
        }
    }

    // create moves
    var moves = Array_MAX_MOVES;
    var moves_len: i32 = 0;

    for i in 1..(s.nxn + 1) { // skip 0
        if !seen[i] {
            moves[moves_len] = i;
            moves_len += 1;
        }
    }

    return moves, moves_len
}

fn moves_dynamic(s: Soduku&, r: i32, c: i32) -> i32[>..] {
    if s.getCell(r, c) != 0 { return [] }

    var seen = s.create_seen();

    // row & col
    for i in s.nxn {
        seen[s.getCell(r, i)] = true;
        seen[s.getCell(i, c)] = true;
    }

    // block
    var rb = (r / s.n) * s.n;
    var cb = (c / s.n) * s.n;

    for i in rb..(rb + s.n) {
        for j in cb..(cb + s.n) {
            seen[s.getCell(i, j)] = true;
        }
    }

    // create moves
    var moves = [];

    for i in 1..(s.nxn + 1) { // skip 0
        if !seen[i] {
            moves.push(i);
        }
    }

    moves
}

// using backtracking
recursive fn solve(s: Soduku&, row: i32 = 0, col: i32 = 0) -> bool {
    if s.getCell(row, col) != 0 {
        // Move to next cell in col or row
        if col < s.nxn - 1 { s.solve(row, col + 1) }
        else if row < s.nxn - 1 { s.solve(row + 1, 0) }
        else { true } // solved
    }

    // Try each move
    var moves, moves_len = s.moves(row, col);
    for i in moves_len {
        var move = moves[i];
        // self.n_moves += 1

        s.setCell(row, col, move);
        if s.solve(row, col) { return true }
        s.setCell(row, col, EMPTY_CELL);
    }

    false
}

fn shuffle(s: Soduku&) {
    fn swap_rows(s: Soduku&, r1: Int, r2: Int) {
        if r1 == r2 { return }

        for c in 0..s.nxn {
            swap_at(s.grid, r1 * s.nxn + c, r2 * s.nxn + c)
        }
    }

    fn swap_cols(s: Soduku&, c1: Int, c2: Int) {
        if c1 == c2 { return }

        for r in 0..s.nxn {
            swap_at(s.grid, r * s.nxn + c1, r * s.nxn + c2)
        }
    }

    fn rotate_90_clockwise(s: Soduku&) {
        var n = s.nxn;
        for i in 0..(n / 2) {
            for j in i..(n - i - 1) {
                var temp = s.grid[i * n + j];
                s.grid[i * n + j] = s.grid[(n - 1 - j) * n + i];
                s.grid[(n - 1 - j) * n + i] = s.grid[(n - 1 - i) * n + (n - 1 - j)];
                s.grid[(n - 1 - i) * n + (n - 1 - j)] = s.grid[j * n + (n - 1 - i)];
                s.grid[j * n + (n - 1 - i)] = temp;
            }
        }
    }

    for _ in s.n {
        for b in s.n {
            var box = b * s.n;
            var i = 0;
            rotate_90_clockwise(s);

            for ix in rnd_list(0, s.n) {
                swap_cols(s, box + i, box + ix);
                swap_rows(s, box + i, box + ix);
                i += 1;
                rotate_90_clockwise(s);
            }
        }
    }
}

fn create_problem(s: Soduku&, empty: i32) { // empty = 100% number of cells to remove
    var sz = s.nxn * s.nxn;
    var ncr = sz * min(100, empty) / 100; // # cells to remove -> EMPTY_CELL
    var ix = rnd_list(0, sz);

    for  i, cnt  in ix {
        var r = i / s.nxn;
        var c = i % s.nxn;

        s.setCell(r, c, EMPTY_CELL);
        if cnt >= ncr {
            break
        }
    }
}

// create a sorted list of empty cells by number of moves
struct CellsMoves {
    col:   i32,
    row:   i32,
    moves: i32,
}

fn emptyCellsList(s: Soduku&) -> CellsMoves[>..] {
    var cellMoves = [];
    for r in 0..s.nxn {
        for c in 0..s.nxn {
            if s.getCell(r, c) == 0 {
                let m, cnt = s.moves(r, c);
                cellMoves.push(CellsMoves { col: c, row: r, moves: cnt });
            }
        }
    }
    stable_sort(cellMoves) { a, b => a.moves < b.moves }; // sort asc moves
    cellMoves
}

// non recursive version of solve
fn solve_nr(s: Soduku&, cellMoves: CellsMoves[>..]&) -> bool {
    let total = cellMoves.len;
    if total == 0 {
        true
    }

    var moves_cache = [];
    var counts_cache = []; // Almacena el número real de movimientos válidos (cnt)
    var move_idx = [];

    // Inicializamos capturando tanto el array fijo como su contador real (cnt)
    for cell in cellMoves {
        let m_arr, cnt = s.moves(cell.row, cell.col);
        moves_cache.push(m_arr);
        counts_cache.push(cnt);
        move_idx.push(0);
    }

    var idx = 0;
    while idx >= 0 && idx < total {
        let cell = cellMoves[idx];
        let moves = moves_cache[idx];
        let max_moves = counts_cache[idx]; // Límite real basado en cnt

        // Comparamos contra el contador real, no contra la len fija del array
        if move_idx[idx] < max_moves {
            let m = moves[move_idx[idx]];
            move_idx[idx] = move_idx[idx] + 1;

            // Intentar colocar el movimiento en el tablero
            s.setCell(cell.row, cell.col, m);
            s.n_moves++;

            // Avanzar a la siguiente celda vacía
            idx = idx + 1;
            if idx < total {
                let next_cell = cellMoves[idx];
                // Recalculamos y actualizamos tanto el array como su nuevo cnt
                let m_arr, cnt = s.moves(next_cell.row, next_cell.col);
                moves_cache[idx] = m_arr;
                counts_cache[idx] = cnt;
                move_idx[idx] = 0;
            }
        } else {
            // No quedan más movimientos válidos: Backtracking
            s.setCell(cell.row, cell.col, EMPTY_CELL);
            move_idx[idx] = 0;
            idx = idx - 1;
        }
    }

    idx == total
}

// compare grids
fn eq_grid(grid1: i32[>..]&, grid2: i32[>..]&) -> bool {
    for i in 0..grid1.len {
        if grid1[i] != grid2[i] {
            false
        }
    }
    true
}
// test

fn test01() {
    var sudoku = newSudoku(6);
    sudoku.shuffle();

    sudoku.create_problem(10);
    sudoku.print();

    sudoku.solve();
    print(sudoku.test());

    sudoku.print();
    print(sudoku.test());
}

fn test02() {
    for i in 1..10 {
        var sudoku = newSudoku(5);
        sudoku.shuffle();
        var grid = copy(sudoku.grid);
        sudoku.create_problem(35);
        // sudoku.print();

        let cells = sudoku.emptyCellsList();
        var t0 = clock();
        sudoku.solve_nr(cells);
        t0 = clock() - t0;

        // sudoku.print();
        assert(sudoku.test());
        print(i, " solved :", sudoku.test(), ", grids equal? :", eq_grid(grid, sudoku.grid), ", lap: ", (t0 * 1000) as i32, " ms, n_moves: ", sudoku.n_moves); // they don't have to be eq as there can be many solutions
    }
}
fn main() {
    test02()
}
