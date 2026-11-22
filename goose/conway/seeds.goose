// StaticPoly seeds
import math;
//
import vertex;
import polyhedron;

// static storage polyhedron
struct StaticPoly {
    name:     u8[]     = [],
    faces:    u32[][]  = [],
    vertexes: f32[3][] = [],
}

const Tetrahedron = StaticPoly {
    name:  "T",
    faces: [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]],
    vertexes: [[1.0, 1.0, 1.0], [1.0, -1.0, -1.0], [-1.0, 1.0, -1.0], [-1.0, -1.0, 1.0]] };
const Cube = StaticPoly {
    name:  "C",
    faces: [[3, 0, 1, 2], [3, 4, 5, 0], [0, 5, 6, 1], [1, 6, 7, 2], [2, 7, 4, 3], [5, 4, 7, 6]],
    vertexes: [[0.707, 0.707, 0.707], [-0.707, 0.707, 0.707], [-0.707, -0.707, 0.707], [0.707, -0.707, 0.707], [0.707, -0.707, -0.707], [0.707, 0.707, -0.707], [-0.707, 0.707, -0.707], [-0.707, -0.707, -0.707]] };
const Icosahedron = StaticPoly {
    name:  "I",
    faces: [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1], [1, 5, 7], [1, 7, 6], [1, 6, 2], [2, 6, 8], [2, 8, 3], [3, 8, 9], [3, 9, 4], [4, 9, 10], [4, 10, 5], [5, 10, 7], [6, 7, 11], [6, 11, 8], [7, 10, 11], [8, 11, 9], [9, 11, 10]],
    vertexes: [[0, 0, 1.176], [1.051, 0, 0.526], [0.324, 1.0, 0.525], [-0.851, 0.618, 0.526], [-0.851, -0.618, 0.526], [0.325, -1.0, 0.526], [0.851, 0.618, -0.526], [0.851, -0.618, -0.526], [-0.325, 1.0, -0.526], [-1.051, 0, -0.526], [-0.325, -1.0, -0.526], [0, 0, -1.176]] };
const Octahedron = StaticPoly {
    name:  "O",
    faces: [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [1, 4, 5], [1, 5, 2], [2, 5, 3], [3, 5, 4]],
    vertexes: [[0, 0, 1.414], [1.414, 0, 0], [0, 1.414, 0], [-1.414, 0, 0], [0, -1.414, 0], [0, 0, -1.414]] };
const Dodecahedron = StaticPoly {
    name:  "D",
    faces: [[0, 1, 4, 7, 2], [0, 2, 6, 9, 3], [0, 3, 8, 5, 1], [1, 5, 11, 10, 4], [2, 7, 13, 12, 6], [3, 9, 15, 14, 8], [4, 10, 16, 13, 7], [5, 8, 14, 17, 11], [6, 12, 18, 15, 9], [10, 11, 17, 19, 16], [12, 13, 16, 19, 18], [14, 15, 18, 19, 17]],
    vertexes: [[0, 0, 1.07047], [0.713644, 0, 0.797878], [-0.356822, 0.618, 0.797878], [-0.356822, -0.618, 0.797878], [0.797878, 0.618034, 0.356822], [0.797878, -0.618, 0.356822], [-0.934172, 0.381966, 0.356822], [0.136294, 1.0, 0.356822], [0.136294, -1.0, 0.356822], [-0.934172, -0.381966, 0.356822], [0.934172, 0.381966, -0.356822], [0.934172, -0.381966, -0.356822], [-0.797878, 0.618, -0.356822], [-0.136294, 1.0, -0.356822], [-0.136294, -1.0, -0.356822], [-0.797878, -0.618034, -0.356822], [0.356822, 0.618, -0.797878], [0.356822, -0.618, -0.797878], [-0.713644, 0, -0.797878], [0, 0, -1.07047]] };

const PlatoSolids = [copy(Tetrahedron), copy(Cube), copy(Octahedron), copy(Dodecahedron), copy(Icosahedron),];

const tau = PI * 2;

fn pyramid(p: Polyhedron&, n: i32, height: f32 = 1.0) {
    var theta = (tau / n) as f32; // pie angle

    var vertexes = []; // Vertexes(length=n + 1, fill=Vertex())
    // base
    for i in n { vertexes.push(Vertex { -cos(i * theta), -sin(i * theta), -0.2 }); }
    // apex
    vertexes.push(Vertex<f32> { 0.0, 0.0, height });

    var faces: Faces = [];
    // base
    var range: Face = [];
    faces.push(copy(range.calc_range((n - 1), 0, true)));

    // sides
    for i in n {
        faces.push([i as u32, ((i + 1) % n) as u32, n as u32]);
    }

    p.newPoly(str("Y", n), faces, vertexes);
}

fn prism(p: Polyhedron&, n: i32, height: f32 = 1.0) {
    var theta = (tau / n) as f32; // pie angle
    // vertexes
    var vertexes: Vertexes = []; vertexes.resize(n * 2, Vertex<f32> {});
    for i in n {
        vertexes[i] = Vertex { -cos(i * theta), -sin(i * theta), -height };
        vertexes[i + n] = Vertex { -cos(i * theta), -sin(i * theta), height };
    }

    // faces
    var faces: Faces = [];
    // vertex #'s 0 to n-1 around one face, vertex #'s n to 2n-1 around other
    var range: Face = [];
    faces.push(copy(range.calc_range(n - 1, 0, true))); // base
    faces.push(copy(range.calc_range(n, 2 * n, false))); // top

    for i in n {
        // n rectangular sides
        faces.push([i as u32, ((i + 1) % n) as u32, ((i + 1) % n + n) as u32, (i + n) as u32]);
    }

    p.newPoly(str("P", n), faces, vertexes);
}

fn antiprism(p: Polyhedron&, n: i32) {
    var theta = (tau / n) as f32; // pie angle
    var h: f32 = sqrt(1.0 - (4.0 / ((4.0 + (2.0 * cos(theta / 2.0))) - (2.0 * cos(theta)))));
    var r: f32 = sqrt(1.0 - (h * h));
    var f: f32 = sqrt((h * h) + pow(r * cos(theta / 2.0), 2.0 as f32));
    // correction so edge midpoints (not vertexes) on unit sphere
    var r_corrected = -r / f;
    var h_corrected = -h / f;
    // vertexes
    var vertexes: Vertexes = []; vertexes.resize(n * 2, Vertex<f32> {});

    for i in n {
        vertexes[i] = Vertex {
            r_corrected * cos(i * theta),
            r_corrected * sin(i * theta),
            h_corrected };
        vertexes[i + n] = Vertex {
            r_corrected * cos(i * theta + theta / 2),
            r_corrected * sin(i * theta + theta / 2),
            -h_corrected };
    }
    // faces
    var faces: Faces = [];
    var range: Face  = [];
    faces.push(copy(range.calc_range(n - 1, 0, true))); // base
    faces.push(copy(range.calc_range(n, 2 * n, false))); // top

    for i in n {
        // 2n triangular sides
        faces.push([i as u32, ((i + 1) % n) as u32, (i + n) as u32]);
        faces.push([i as u32, (i + n) as u32, ((n + i - 1) % n + n) as u32]);
    }

    p.newPoly(str("A", n), faces, vertexes);
}

fn main() {
    var p = Polyhedron {};
    antiprism(p, 5);
    print(p.name);
    print(p.vertexes);
    print(p.faces);
}
