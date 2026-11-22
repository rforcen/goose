
// test
import dictionary;
import common;
import vecvec;

fn test_dict() {
    var d = dictionary<EdgeKey, u32> {};

    d.insert(EdgeKey { 1, 1 }, 200);
    d.insert(EdgeKey { 1, 2 }, 300);
    d.insert(EdgeKey { 1, 3 }, 400);

    d.each() { k, v => print(k, ",", v); }
}

// to index a variable array, we need a reference to the array
// both global...
var ar:    u32[][>..]               = [];
var ar_at: (u32[]&<u32 in ar>)[>..] = [];

fn test_array() {
    let a: u32[] = [1, 2, 3, 4];
    a[0] = 66;

    print(a.position(3));
    print(a.position(6));

    for i in 5 { ar_at.push(ar.push([i as u32])); }
    var pp = ar_at[0];
    // pp.push(0); // can't do this!!

    var al: u32[>..] = [];

    al.push(a.len as u32);
    al.append(a);
    print(al);

    print(ar_at[0], ar_at);
}

// test
fn test_vv() {
    let nRows:  u32 = 5;
    let nitems: u32 = 8;

    var vv = vecvec::new(nRows, nitems);
    for v, i in [3, 6, 7] {
        for j in v {
            vv.push(i as u32, j as u32);
        }
    }
    for i in vv.nFaces() { print(vv.getFace(i)); }
    print("----");
    var a: u32[] = [11, 22, 33];
    vv.set(0, a);
    print(vv.getFace(0));
    print("----");
    vv.print();
}

fn main() { test_vv(); }
