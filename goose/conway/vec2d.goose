// Vec2d simulated in a linear arr with index/len in SoA (Structure of Arrays)

namespace vec2d;

root struct Vec2d<T> {
    arr:  T[>..]   = [],
    index: u32[>..] = [],
    lens:  u32[>..] = [],
}

fn push<T>(v: Vec2d<T>&, items: T[]) {
    v.index.push(v.arr.len as u32); // point to len
    v.lens.push(items.len as u32);

    v.arr.append(items);
}
fn push<T>(v: Vec2d<T>&, items: T[][]) {
    for item in items {
        v.push(copy(item));
    }
}
inline fn get<T>(v: Vec2d<T>&, ix: u32) -> T[] {
    if ix >= v.index.len { abort(str("Vec2d get: index out of range: ", ix, " >= ", v.index.len)) }

    var start = v.index[ix];
    var len = v.lens[ix];
    return v.arr[start..start + len];
}

inline fn set<T>(v: Vec2d<T>&, ix: u32, value: T[]&) {
    if ix >= v.index.len { abort(str("Vec2d set: index out of range: ", ix, " >= ", v.index.len)) }
    
    var start = v.index[ix];
    var len = v.lens[ix];
    for i in 0..len {
        v.arr[start + i] = value[i];
    }
}

inline fn n_items<T>(v: Vec2d<T>&) -> u32 { v.index.len as u32 }

fn copy<T>(v: Vec2d<T>&) -> Vec2d<T> {
    return Vec2d<T>{
        arr: copy(v.arr),
        index: copy(v.index),
        lens: copy(v.lens),
    };
}

fn clear<T>(v: Vec2d<T>&) {
    v.arr.clear();
    v.index.clear();
    v.lens.clear();
}

fn initVec2d<T>(v: Vec2d<T>&, items: T[][]) {    
    v.clear(); // clean up
    v.push(copy(items));
}



// test
/*
fn t01() {
    const faces: u32[][] = [[0, 1, 4, 7, 2], [0, 2, 6, 9, 3], [0, 3, 8, 5, 1], [1, 5, 11, 10, 4], [2, 7, 13, 12, 6], [3, 9, 15, 14, 8], [4, 10, 16, 13, 7], [5, 8, 14, 17, 11], [6, 12, 18, 15, 9], [10, 11, 17, 19, 16], [12, 13, 16, 19, 18], [14, 15, 18, 19, 17]];

    let v = Vec2d<u32>{};
    initVec2d(v, copy(faces));
    initVec2d(v, copy(faces));

    for i in v.n_items() {
        print(v.get(i));
    }
    print(v.get(12));
}

fn main() { t01() }
*/
