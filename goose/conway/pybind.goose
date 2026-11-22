// python binding
import polyhedron;
import conway;
import common;
//
import ffi;

// c bindings - helpers to malloc & copy data to a c pool
// allocate a buffer & copy data to it, return pointer as u64
// use bytes_of to convert to u8[:]
extern fn gs_alloc_copy(src: const u8[:], size_ot_T: u64) -> u64;
extern fn gs_free(ptr: u64);

// convert faces, vertices, colors [] to global allocated buffer (u64)
// this requires using a small c wrapper to alloc & memcpy the data
fn serialize(p: Polyhedron&) -> u64, u32, u64, u32, u64, u32 {
    const Size_u32: u32 = 4;
    const Size_f32: u32 = 4;

    return
        // faces
        gs_alloc_copy(bytes_of(p.faces), Size_u32),
        p.faces.len as u32,
        // vertexes
        gs_alloc_copy(bytes_of(p.vertexes), Size_f32),
        (p.vertexes.len * 3) as u32,
        // colors
        gs_alloc_copy(bytes_of(p.colors), Size_f32),
        (p.colors.len * 3) as u32;
}

// apply transform string
export fn transform(
    tr: u64, n: u32, param: f32, // in

    faces:    u64&, faces_len: u32&, // out
    vertexes: u64&, vertexes_len: u32&,
    colors:   u64&, colors_len: u32&,
    //
) -> u32 {
    var tr = ffi::cstr(tr); // extract transformation string

    var p = Polyhedron {};
    let t_ms = p.conway(tr, n);
    // serialize in global buffers
    faces, faces_len, vertexes, vertexes_len, colors, colors_len = p.serialize();

    return t_ms;
}

export fn write_ply(tr:u64, filename:u64) {
    var tr = ffi::cstr(tr); // extract transformation string
    var filename = ffi::cstr(filename); // extract filename
    
    var p = Polyhedron {};
    p.conway(tr, 0); // calcs colors so only normals are required ->    

    p.calc_normals();

    p.write_PLYbin(filename);
}


