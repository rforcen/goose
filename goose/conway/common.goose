// commoon struct and misc fn
import vertex;
import conway;
import johnson;

const MAX_UINT: u32 = 0xffffffff;

type Face = u32[>..];
type Faces = u32[][>..];
type Vertexes = Vertex<f32>[>..];

// EdgeKey
struct EdgeKey {
    v1: u32,
    v2: u32,
}

fn ek_sorted(v1: u32, v2: u32) -> EdgeKey {
    if v1 < v2 { EdgeKey { v1, v2 } }
    else { EdgeKey { v2, v1 } }
}

// hash for EdgeKey, solves low v1 values hash congestion
// produced by (v1<<32 | v2)
fn hash(ek: EdgeKey) -> u64 {
    var x: u64 = (ek.v1 as u64) << 32 | ek.v2;
    x ^= x >> 33;
    x *= 0xff51afd7ed558ccd;
    x ^= x >> 33;
    return x;
}

// misc fn
fn calc_range(result: Face&, from_val: i32, to_val: i32, inclusive: bool) -> Face& {
    var step:    i32 = if from_val <= to_val { 1 } else { -1 };
    var current: i32 = from_val;
    var end:     i32 = to_val;

    result = [];
    loop {
        if step == 1 {
            if inclusive && current > end {
                break
            }
            if !inclusive && current >= end {
                break
            }
        } else {
            if inclusive && current < end {
                break
            }
            if !inclusive && current <= end {
                break
            }
        }

        result.push(current as u32);
        current += step;
    }
    return result;
}

// apply conway transformation 'tr' to poly
fn conway(p: Polyhedron&, tr: u8[:], n: u32) -> u32 {
    tr.reverse(); // reverse it to get the original order

    // static poly?
    var poly = match tr[0] { // first char is now the base poly
        'T' => { copy(Tetrahedron) },
        'C' => { copy(Cube) },
        'O' => { copy(Octahedron) },
        'I' => { copy(Icosahedron) },
        'D' => { copy(Dodecahedron) },

        _ => { copy(Tetrahedron) },
    };

    // rest of calculated seeds
    match tr[0] {
        'Y' => { p.pyramid(5, 0.1) },
        'L' => { p.prism(5, 0.1) },
        'U' => { p.antiprism(5) },
        'J' => { var j = getJohnson(n); p.fromStatic(j) },
        _ => { p.fromStatic(poly) },
    }

    var t_ms = lap() {
        for i in 1..tr.len {
            match tr[i] {
                'k' => { kis(p) },
                'a' => { ambo(p) },
                'q' => { quinto(p) },
                'w' => { whirl(p) },
                'c' => { chamfer(p) },
                'n' => { insetN(p) },
                'g' => { gyro(p) },
                'p' => { propellor(p) },
                'h' => { hollow(p) },
                _ => {},
            }
        }
        p.calc_colors(); // only using colors for now
    };
    return t_ms;
}
fn serial_len(faces: u32[][]) -> u32 {
    var tlen: u32 = 0;
    for face in faces {
        tlen += 1 + face.len as u32;
    }
    return tlen;
}
// flat Vertex[] -> f32[]
fn flattern(vtx: Vertex<f32>[:]) -> f32[>..] {
    var result: f32[>..] = [];
    for v in vtx {
        result.push(v.x);
        result.push(v.y);
        result.push(v.z);
    }
    result
}

// lap a fn
fn lap<F>() -> u32 {
    var start = clock();
    F();
    return (1000.0 * (clock() - start)) as u32;
}
