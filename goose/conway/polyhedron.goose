// polyhedron
import std;
import os;
import dictionary;
//
import vertex;
import seeds;
import common;

var rng = rng { random_seed() };

root struct Polyhedron {
    name:     u8[>..]  = "",
    faces:    u32[>..] = [],
    faces_ix: u32[>..] = [],
    vertexes: Vertexes = [],
    normals:  Vertexes = [],
    colors:   Vertexes = [],
    centers:  Vertexes = [],
    areas:    f32[>..] = [],
}

fn copy(p: Polyhedron&, dest: Polyhedron&) {
    dest.name = copy(p.name);
    dest.faces = copy(p.faces);
    dest.faces_ix = copy(p.faces_ix);
    dest.vertexes = copy(p.vertexes);
    dest.normals = copy(p.normals);
    dest.colors = copy(p.colors);
    dest.centers = copy(p.centers);
    dest.areas = copy(p.areas);
}

inline fn getFace(p: Polyhedron&, n_face: u32) -> u32[] {
    if n_face >= p.faces_ix.len {
        return [];
    }
    var ix = p.faces_ix[n_face];
    var len = p.faces[ix];
    return p.faces[ix + 1..ix + len + 1];
}

inline fn nFaces(p: Polyhedron&) -> u32 { p.faces_ix.len as u32 }

// find the face that includes vertex_id
fn face_index(p: Polyhedron&, vertex_idx: u32) -> u32 {
    for f in p.nFaces() {
        for ix in p.getFace(f) {
            if vertex_idx == ix { return f } // found face 'f'
        }
    }

    return 0 // not found
}

// serialize faces -> (data, ix)
fn serial_faces(faces: u32[][>..]&) -> u32[>..], u32[>..] {
    var result:    u32[>..] = [];
    var result_ix: u32[>..] = [];

    for face in faces {
        result_ix.push(result.len as u32);

        result.push(face.len as u32);
        result.append(face)
    }

    return result, result_ix;
}

// create from static polyhedron
fn fromStatic(polyOut: Polyhedron&, ps: StaticPoly&) {
    // convert static faces & vertexes
    polyOut.faces = [];
    polyOut.faces_ix = [];

    for f in ps.faces {
        polyOut.faces_ix.push(polyOut.faces.len as u32); // faces_ix -> index to len

        polyOut.faces.push(f.len as u32); // len
        polyOut.faces.append(f); // vertex index
    }

    polyOut.vertexes = [];
    for v in ps.vertexes { polyOut.vertexes.push(Vertex<f32> { x: v[0], y: v[1], z: v[2] }) }

    polyOut.name = copy(ps.name);
}

fn newPoly(p: Polyhedron&, faces: u32[], vertexes: Vertexes) {
    p.faces = copy(faces);
    p.vertexes = copy(vertexes);
}

fn newPoly(p: Polyhedron&, tr: u8[], faces: u32[][>..]&, vertexes: Vertexes&) {
    // insert at 0 tr
    let name: u8[>..] = [];
    format(name, tr, p.name);
    p.name = copy(name);

    // serialize faces
    p.faces, p.faces_ix = serial_faces(faces);
    p.vertexes = copy(vertexes);
}

fn calc_normals(p: Polyhedron&) {
    p.normals = [];
    for i in p.nFaces() {
        var face = p.getFace(i);
        p.normals.push(normal(p.vertexes[face[0]], p.vertexes[face[1]], p.vertexes[face[2]]));
    }
}

fn avg_normals(p: Polyhedron&) -> Vertexes {
    var normals: Vertexes = [];

    for i in p.nFaces() {
        var face = p.getFace(i);
        let face_len = face.len;
        var normalV = Vertex<f32> {};
        var v1 = p.vertexes[face[face_len - 2]];
        var v2 = p.vertexes[face[face_len - 1]];

        for ic in face_len {
            var v3 = p.vertexes[ic];
            normalV += normal(v1, v2, v3);
            v1 = v2;
            v2 = v3;
        }

        normals.push(normalV.unit());
    }

    normals
}

fn calc_centers(p: Polyhedron&) {
    p.centers = [];
    for i in p.nFaces() {
        var face = p.getFace(i);
        var center = Vertex<f32> {};
        for vertex_idx in face { center += p.vertexes[vertex_idx]; }
        p.centers.push(center / face.len);
    }
}

fn calc_center(p : Polyhedron&, face_idx : u32) -> Vertex<f32> {
    var face = p.getFace(face_idx);
    var center = Vertex<f32> {};
    for vertex_idx in face { center += p.vertexes[vertex_idx]; }
    return center / face.len;
}

fn calc_areas(p: Polyhedron&) {
    p.areas = [];
    for i in p.nFaces() {
        var face = p.getFace(i);
        var vsum = Vertex<f32> {};
        let fl = face.len;
        var v1 = p.vertexes[face[fl - 2]];
        var v2 = p.vertexes[face[fl - 1]];

        for vertex_idx in face {
            vsum += v1.cross(v2);
            v1 = v2;
            v2 = p.vertexes[vertex_idx];
        }

        p.areas.push(p.normals[i].dot(vsum) / 2.0);
    }
}

fn calc_area(p : Polyhedron&, face_idx : u32) -> f32 {
    var face = p.getFace(face_idx);
    var vsum = Vertex<f32> {};
    let fl = face.len;
    var v1 = p.vertexes[face[fl - 2]];
    var v2 = p.vertexes[face[fl - 1]];

    for vertex_idx in face {
        vsum += v1.cross(v2);
        v1 = v2;
        v2 = p.vertexes[vertex_idx];
    }

    return p.normals[face_idx].dot(vsum) / 2.0;
}

fn calc_colors(p: Polyhedron&) {
    fn random_palette(n: i32 = 64) -> Vertexes {
        var palette: Vertexes = [];
        for i in n {
            palette.push(Vertex<f32> { rng.rand_f32(), rng.rand_f32(), rng.rand_f32() });
        }
        return palette;
    }

    p.calc_centers();

    // max dist from origin
    var max_dist: f32 = 0.0;
    for center in p.centers {
        max_dist = max(max_dist, center.length());
    }
    if max_dist == 0.0 { max_dist = 1.0; }

    // adapt tolerance
    var relative_eps: f32 = max_dist * 0.001;
    let palette = random_palette();

    var unique_distances: f32[>..] = [];
    var color_dict = dictionary<const i32, Vertex<f32>> {};

    p.colors = [];

    for cntr, i in p.centers {
        let face_dist = cntr.length();
        var group_idx: i32 = -1;

        for known_dist, idx in unique_distances {
            if abs(known_dist - face_dist) < relative_eps {
                group_idx = idx as i32;
                break
            }
        }

        if group_idx == -1 {
            unique_distances.push(face_dist);
            group_idx = unique_distances.len as i32 - 1;
            color_dict.insert(group_idx, palette[group_idx % palette.len]);
        }

        let c = color_dict.get(group_idx);
        if c { p.colors.push(c); }
    }
}

fn centroid(p: Polyhedron&, face: u32[]) -> Vertex<f32> {
    var center = Vertex<f32> {};
    for vertex_idx in face { center += p.vertexes[vertex_idx]; }
    return center / face.len;
}

fn scale_vertexes(p: Polyhedron&) {
    var max_val: f32 = 0.0;
    for vertex in p.vertexes { max_val = max(max_val, vertex.max_abs()); }

    if max_val != 0.0 { for &vertex in p.vertexes { vertex = vertex / max_val; } }
}

fn max_face(p: Polyhedron&) -> u32 {
    var pl = 0;
    var max_face: u32 = 0;

    while pl < p.faces.len {
        max_face = max(max_face, p.faces[pl]);
        pl += p.faces[pl] + 1;
    }
    return max_face;
}

fn vmax(p:Polyhedron&) -> u32 {
    var grade : u32[>..]=[];
    grade.resize(p.vertexes.len, 0);    

    for f in p.nFaces(){
        for ix in p.getFace(f) {
            grade[ix] += 1;
        }
    }
    return grade.max();
}

fn write_PLYbin(p: Polyhedron&, filename: u8[:]) -> bool {
    var buff: u8[>..] = []; // write buffer
    format(buff, "ply\nformat binary_little_endian 1.0\nelement vertex ", p.vertexes.len, "\nproperty float x\nproperty float y\nproperty float z\nproperty float nx\nproperty float ny\nproperty float nz\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nelement face ", p.nFaces(), "\nproperty list uchar int vertex_indices\nend_header\n");

    // write mesh.points[] -> coords (3 x f32), normals (3 x f32), colors (3 x bytes r,g,b)
    for i in p.vertexes.len {
        format(buff, bytes_of([p.vertexes[i]])); // vertexes 3 x f32
        format(buff, bytes_of([p.normals[p.face_index(i as u32)]])); // normals 3 x f32
        format(buff, bytes_of(p.colors[p.face_index(i as u32)].to_bytes())); // colors 3 x bytes (rgb)
    }

    // write faces (len:u8, face:u32[])
    for f in p.nFaces() {
        var face = p.getFace(f);
        format(buff, bytes_of([face.len as u8])); // len
        format(buff, bytes_of(face[..]));
    }

    return write_file(filename, buff); // write buffer to file
}

fn recalc(p: Polyhedron&) {
    p.calc_normals();
    p.calc_centers();
    p.calc_areas();
    p.calc_colors();
    p.scale_vertexes();
}

// test
fn test_polyhedron() {
    var p = Polyhedron {};

    p.fromStatic(Dodecahedron);

    let n = 100000;
    print("recalculating ", n, " times...");
    var t0 = clock();
    for i in n {
        p.recalc();
    }
    print("lap:", (1000.0 * (clock() - t0)) as i32, " ms");

    if !p.write_PLYbin("dodeca.ply") { print("Failed to write PLY file"); }
    else { print("done"); }
}

// fn main() { test_polyhedron(); }
