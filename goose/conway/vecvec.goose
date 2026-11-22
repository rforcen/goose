// vector<vector<u32>> aka Faces simulator in a flat array
import std;

namespace vecvec;

struct VecVec {
    rows:   u32,
    nitems: u32,
    data:   u32[>..], // each row has |nitems|item0...item(nfaces)| -> (n+1)*rows
}

fn new(rows: u32, nitems: u32) -> VecVec {
    var v = VecVec { rows: rows, nitems: nitems, data: [] };
    v.data.resize((nitems + 1) * rows, 0);
    v
}

inline fn getFace(vv: VecVec&, row: u32) -> u32[] {
    var offset: u32 = row * (vv.nitems + 1);
    var n:      u32 = vv.data[offset];

    vv.data[offset + 1..offset + 1 + n]
}

inline fn find( vv: VecVec&, row : u32, item : u32) -> bool {
    vv.getFace(row).position(item) != -1
}

fn push_unique(vv: VecVec&, row: u32, value: u32) {
    if !vv.find(row, value) {
        vv.push(row, value);
    }
}

fn push(vv: VecVec&, row: u32, value: u32) {
    var offset: u32 = row * (vv.nitems + 1);
    var n:      u32 = vv.data[offset];

    vv.data[offset + 1 + n] = value;
    vv.data[offset] += 1; // inc nitems
}

fn set(vv: VecVec&, row: u32, idx: u32, value: u32) {
    var offset: u32 = row * (vv.nitems + 1);
    vv.data[offset + 1 + idx] = value;
}
fn set(vv: VecVec&, row: u32, value: u32[]&) {
    var offset: u32 = row * (vv.nitems + 1);
    var l = min(value.len, vv.nitems) as u32;

    vv.data[offset] = l; // nitems
    for i in l { vv.data[offset + 1 + i] = value[i]; }
}

inline fn nFaces(vv: VecVec&) -> u32 { vv.rows }

fn print(vv: VecVec&) {
    for i in vv.nFaces() { print(vv.getFace(i)); }
}


