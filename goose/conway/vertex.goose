// Vertex
import std;
import math;

struct Vertex<T> {
    x: T = 0.0, y: T = 0.0, z: T = 0.0,
}

inline fn add<T>(a: Vertex<T>, b: T) -> Vertex<T> { Vertex<T> { x: a.x + b, y: a.y + b, z: a.z + b } }
inline fn sub<T>(a: Vertex<T>, b: T) -> Vertex<T> { Vertex<T> { x: a.x - b, y: a.y - b, z: a.z - b } }
inline fn dot<T>(a: Vertex<T>, b: Vertex<T>) -> T { a.x * b.x + a.y * b.y + a.z * b.z }
inline fn cross<T>(a: Vertex<T>, b: Vertex<T>) -> Vertex<T> { Vertex<T> { x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x } }
inline fn length<T>(a: Vertex<T>) -> T { sqrt(a.x * a.x + a.y * a.y + a.z * a.z) }
inline fn distance<T>(a: Vertex<T>, b: Vertex<T>) -> T { return length(a - b); }
inline fn distanceSq<T>(a: Vertex<T>, b: Vertex<T>) -> T { return dot(a - b, a - b); }
inline fn lengthSq<T>(a: Vertex<T>) -> T { return dot(a, a); }
inline fn unit<T>(a: Vertex<T>) -> Vertex<T> {
    let l = lengthSq(a);
    return if l != 0 { a / l } else { a };
}
inline fn normalize<T>(a: Vertex<T>) -> Vertex<T> { unit(a) }

inline fn max_abs<T>(a: Vertex<T>) -> T {
    let abs_x = abs(a.x);
    let abs_y = abs(a.y);
    let abs_z = abs(a.z);
    return max(abs_x, max(abs_y, abs_z));
}
inline fn tween<T>(a: Vertex<T>, b: Vertex<T>, t: T) -> Vertex<T> {
    return (a * (1.0 - t)) + (b * t);
}
inline fn one_third<T>(a: Vertex<T>, b: Vertex<T>) -> Vertex<T> {
    return tween(a, b, 1.0 / 3.0);
}
inline fn normal<T>(a: Vertex<T>, b: Vertex<T>, c: Vertex<T>) -> Vertex<T> {
    return cross(b - a, c - b);
}

inline fn to_bytes<T>(a: Vertex<T>) -> u8[3] {
    var ret: u8[3] = [0, 0, 0];
    ret[0] = (a.x * 255.0) as u8;
    ret[1] = (a.y * 255.0) as u8;
    ret[2] = (a.z * 255.0) as u8;
    return ret;
}

// test
fn test_vertex() {
    var v0 = Vertex<f32> { x: 1.0, y: 2.0, z: 3.0 };
    var v1 = Vertex<f32> { x: 4.0, y: 5.0, z: 6.0 };
    var v2 = v0 + v1;
    var v3 = add(v0, 1.0);
    var v4 = v0 - v1;
    var v5 = sub(v0, 1.0);
    var v6 = v1 * v1;
    var v7 = v1 * 2.0;
    var v8 = v1 / v1;
    var v9 = v1 / 2.0;

    v0 = v0 * v1;
    v0 = -v0;

    print(v0, v1, v2, v3, v4, v5, v6, v7, v8, v9);
    var v10 = normalize(v0);
    var v11 = max_abs(v0);
    var v12 = tween(v0, v1, 0.5);
    var v13 = normal(v0, v1, v2);
    print(v10, v11, v12, dot(v0, v1), cross(v2, v3), v13);
}

// fn main() { test_vertex(); }
