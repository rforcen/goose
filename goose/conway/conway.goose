// conway polyhedron transformations
// kis, ambo, quinto, whril, chamfer, insetN, gyro, propellor, hollow

import polyhedron;
import common;
import seeds;
import vecvec;
import vec2d;

//
import dictionary;

fn kis(p: Polyhedron&, height: f32 = 0.1) {
    var new_faces: u32[][>..] = [];
    var new_vertexes = copy(p.vertexes);

    // gen new vertex (apex) and new faces
    p.calc_centers();
    p.calc_normals();

    for f_idx in p.nFaces() {
        let face = p.getFace(f_idx);

        // new vertex (apex) index
        let apex_idx = p.vertexes.len as u32 + f_idx;

        // apex extrusion
        new_vertexes.push(p.centers[f_idx] + p.normals[f_idx] * height);

        // create triangular face
        for i in face.len - 1 {
            new_faces.push([face[i], face[i + 1], apex_idx]);
        }
        // close polygon
        new_faces.push([face[face.len - 1], face[0], apex_idx]);
    }

    newPoly(p, "k", new_faces, new_vertexes);
}

fn ambo(p: Polyhedron&) {
    // unique edges
    var edge_map = dictionary<EdgeKey, u32> {}; // EdgeKey hash, u32 index in new_vertices
    var new_vertices = []; // mid points

    for iface in p.nFaces() {
        let face = p.getFace(iface);
        for i in face.len {
            var key = ek_sorted(face[i], if i < face.len - 1 { face[i + 1] } else { face[0] });
            if !edge_map.contains(key) { // new?
                edge_map.insert(key, new_vertices.len as u32);

                var v1 = p.vertexes[key.v1]; // mid points in creation order
                var v2 = p.vertexes[key.v2];
                new_vertices.push((v1 + v2) / 2.0);
            }
        }
    }

    // For each edge, register the IDs of the two faces that form it
    var edge_faces: EdgeKey[>..] = [];
    edge_faces.resize(new_vertices.len, EdgeKey { MAX_UINT, MAX_UINT });

    // List of edges that converge at each original vertex
    let nitems = max(p.vmax(), p.max_face()) + 5; // over dimension it
    var vertex_edges = vecvec::new(p.vertexes.len as u32, nitems); // len = p.vertexes.len, nitems can be greater than current one

    var new_faces: u32[][>..] = []; // cap = p.faces.len + p.vertexes.len

    // Populate original faces and map dual adjacencies
    for f_idx in p.nFaces() {
        let face = p.getFace(f_idx);

        var uint_f_idx = f_idx;

        var face_edge_ids: u32[>..] = [];

        for i in face.len {
            var v1 = face[i];
            var v2 = face[(i + 1) % face.len];

            var key = ek_sorted(v1, v2);
            var edge_id = edge_map.get(key);

            if edge_id {
                face_edge_ids.push(edge_id);

                // Register which faces share this edge
                if edge_faces[edge_id].v1 == MAX_UINT { edge_faces[edge_id].v1 = uint_f_idx; }
                else if edge_faces[edge_id].v2 == MAX_UINT { edge_faces[edge_id].v2 = uint_f_idx; }

                // Add edge to vertex umbrella without duplication
                vertex_edges.push_unique(v1, edge_id);
                vertex_edges.push_unique(v2, edge_id);
            } 
        }
        new_faces.push(copy(face_edge_ids));
    }

    //  reconstruct vertex caps in true cyclic order
    for i_el in vertex_edges.nFaces() {
        var edges_list = vertex_edges.getFace(i_el);
        var degree = edges_list.len;
        if degree < 3 { continue }

        var vert_face_ids: u32[>..]  = []; vert_face_ids.resize(degree, 0);
        var visited:       bool[>..] = []; visited.resize(degree, false);

        var current_edge = edges_list[0];
        vert_face_ids[0] = current_edge;
        visited[0] = true;

        // We will look for the first valid face that uses this edge
        var current_face = edge_faces[current_edge].v1;

        for i in 1..degree {
            var next_edge_id = current_edge;

            // We look for which of the other edges of the vertex belongs to 'current_face'
            for edge, e_idx in edges_list {
                if visited[e_idx] { continue }
                if edge_faces[edge].v1 == current_face || edge_faces[edge].v2 == current_face {
                    next_edge_id = edge;
                    visited[e_idx] = true;
                    break
                }
            }

            vert_face_ids[i] = next_edge_id;

            // Jump to the OTHER face that shares the new edge to continue the umbrella
            current_face = if edge_faces[next_edge_id].v1 == current_face { edge_faces[next_edge_id].v2 } else { edge_faces[next_edge_id].v1 };
            current_edge = next_edge_id;
        }
        new_faces.push(copy(vert_face_ids));
    }

    newPoly(p, "a", new_faces, new_vertices);
}

fn quinto(p: Polyhedron&) {
    p.calc_centers();
    var mid_map = dictionary<EdgeKey, u32> {}; // EdgeKey, vertex index

    var new_vertices: Vertex<f32>[>..] = copy(p.vertexes);
    var new_faces:    Faces            = [];

    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);

        if face.len < 3 { continue }
        var centroid = p.centers[f_idx];

        // Single array for internal points. We avoid double contiguous allocation
        // This array will be permanently saved as the central face, so it does NOT have a local defer free.
        var inner_face_ids: Face = []; inner_face_ids.resize(face.len, 0);

        var v1 = face[face.len - 2];
        var v2 = face[face.len - 1];

        // Generate midpoints and internal corners
        for v3, idx in face {
            var p1 = p.vertexes[v1];
            var p2 = p.vertexes[v2];
            var mid_pt = (p1 + p2) / 2.0;

            var e_key = ek_sorted(v1, v2);
            if !mid_map.contains(e_key) { // not found -> add
                mid_map.insert(e_key, new_vertices.len as u32);
                new_vertices.push(mid_pt);
            }

            // append vertex for internal face

            inner_face_ids[idx] = new_vertices.len as u32;
            new_vertices.push((mid_pt + centroid) / 2.0);

            v1 = v2;
            v2 = v3;
        }

        // Construction of corner pentagons
        v1 = face[face.len - 2];
        v2 = face[face.len - 1];

        for v3, idx in face {
            var next_idx = if (idx + 1) < face.len { idx + 1 } else { 0 };

            var ti12 = inner_face_ids[idx];
            var ti23 = inner_face_ids[next_idx];

            var t12 = mid_map.get(ek_sorted(v1, v2));
            var t23 = mid_map.get(ek_sorted(v2, v3));

            // make the pentagon
            if t12 && t23 {
                new_faces.push([ti12, t12, v2, t23, ti23]);
            }

            v1 = v2;
            v2 = v3;
        }

        // add central face
        new_faces.push(copy(inner_face_ids));
    }
    newPoly(p, "q", new_faces, new_vertices);
}

fn whirl(p: Polyhedron&) {
    p.calc_centers();

    // dict for points at 1/3 of edges
    var edge_map = dictionary<EdgeKey, u32> {};

    var new_vertices: Vertexes = copy(p.vertexes);
    var new_faces:    Faces    = [];

    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        if face.len < 3 { continue }

        var centroid = p.centers[f_idx];

        // Local array to store the IDs of the interior vertices of THIS face
        var inner_ids: Face = []; inner_ids.resize(face.len, 0);

        var v1 = face[face.len - 2];
        var v2 = face[face.len - 1];

        // Generate all new vertices for this face
        for v3, idx in face {
            // We deterministically generate the point at 1/3 from v1 towards v2
            var e_key = EdgeKey { v1, v2 };
            if !edge_map.contains(e_key) {
                edge_map.insert(e_key, new_vertices.len as u32);
                new_vertices.push(p.vertexes[v1].one_third(p.vertexes[v2]));
            }

            var e_key_21 = EdgeKey { v2, v1 };
            if !edge_map.contains(e_key_21) {
                edge_map.insert(e_key_21, new_vertices.len as u32);
                new_vertices.push(p.vertexes[v2].one_third(p.vertexes[v1]));
            }

            var v1_2 = p.vertexes[v1].one_third(p.vertexes[v2]);
            var cv1 = centroid.one_third(v1_2).normalize();

            inner_ids[idx] = new_vertices.len as u32;
            new_vertices.push(cv1);

            v1 = v2;
            v2 = v3;
        }

        // Build the perimeter Hexagons
        v1 = face[face.len - 2];
        v2 = face[face.len - 1];

        for v3, idx in face {
            var next_idx = (idx + 1) % face.len;

            // Now we guarantee that they exist independently in the map
            var e_v1_v2 = edge_map.get(EdgeKey { v1, v2 });
            var e_v2_v1 = edge_map.get(EdgeKey { v2, v1 });
            var e_v2_v3 = edge_map.get(EdgeKey { v2, v3 });

            var cv1name = inner_ids[idx];
            var cv2name = inner_ids[next_idx];

            if e_v1_v2 && e_v2_v1 && e_v2_v3 {
                new_faces.push([cv1name, e_v1_v2, e_v2_v1, v2, e_v2_v3, cv2name]);
            }

            v1 = v2;
            v2 = v3;
        }

        // Add the rotated central face (we reuse inner_ids)
        new_faces.push(copy(inner_ids));
    }
    newPoly(p, "w", new_faces, new_vertices);
}

fn chamfer(p: Polyhedron&, dist: f32 = 0.1) {
    p.calc_normals();

    // Map to build edge hexagons in a shared way.
    // We store a slice of 6 u32 for each canonical edge (sorted).
    var hex_map = dictionary<EdgeKey, u32> {}; // u32 index to face_pool
    var face_pool = vec2d::Vec2d<u32> {}; // face depot as a dictionary can't hold Face (u32[>..])

    var new_vertices: Vertexes = [];
    var new_faces:    Faces    = [];

    // Add modified original vertices (radially stretched)
    for v in p.vertexes { new_vertices.push(v * (1.0 + dist)) }

    // Process faces to push corners and structure hexagons
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        if face.len < 3 { continue }

        var f_normal = p.normals[f_idx];

        // Array for the new version of the displaced original face
        var orig_face_new: Face = [];  orig_face_new.resize(face.len, 0);

        // Temporary array for the IDs of the new internal vertices of this face
        var face_inner_ids: Face = []; face_inner_ids.resize(face.len, 0);

        // Generate the vertices of the corners displaced by the normal
        for v2, idx in face {
            var v2_pos = p.vertexes[v2];
            var v2new_pos = v2_pos + (f_normal * (dist * 1.5));
            var v2new_id = new_vertices.len as u32;

            new_vertices.push(v2new_pos);

            face_inner_ids[idx] = v2new_id;
            orig_face_new[idx] = v2new_id; // Fill the central face
        }
        // Once the internal points of the face are generated, we stitch the hexagons
        var v1_idx = face.len - 1;
        for v2, v2_idx in face {
            var v1 = face[v1_idx];

            var v1new = face_inner_ids[v1_idx];
            var v2new = face_inner_ids[v2_idx];

            // Symmetric canonical key for the edge between v1 and v2
            var e_key = ek_sorted(v1, v2);
            var f_ix = hex_map.get(e_key);

            if f_ix {
                // We recover the buffer and mandatorily write the neighboring vertices

                var face = face_pool.get(f_ix);
                if v1 < v2 {
                    face[4] = v1new;
                    face[5] = v2new;
                } else {
                    face[4] = v2new;
                    face[5] = v1new;
                }
                face_pool.set(f_ix, face);
            } else {
                // not found -> add it
                // First face that visits the edge: initialize the buffer
                var hex_buffer = if v1 < v2 { [v2, v2new, v1new, v1, MAX_UINT, MAX_UINT] }
                    else { [v1, v1new, v2new, v2, MAX_UINT, MAX_UINT] };

                hex_map.insert(e_key, face_pool.n_items());
                face_pool.push(hex_buffer);
            }

            v1_idx = v2_idx;
        }

        // Add the displaced original face to the global list
        new_faces.push(copy(orig_face_new));
    }
    // copy values from face_pool to new_faces
    // Fix hexagons that were not connected to a face
    for i in face_pool.n_items() {
        var face = face_pool.get(i);
        if face.len == 6 && face[4] == MAX_UINT {
            face[4] = face[2];
            face[5] = face[1];
        }
        new_faces.push(copy(face));
    }

    newPoly(p, "c", new_faces, new_vertices);
}

fn insetN(p: Polyhedron&, n: u32 = 0, inset_dist: f32 = 0.5, popout_dist: f32 = -0.2) {
    p.calc_normals();
    p.calc_centers();

    var new_vertices = copy(p.vertexes);
    var new_faces: Faces = [];

    var found_any = false;

    // process faces
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue }

        // Does this face meet the 'n' sides filter? (If n == 0, all enter)
        if n == 0 || flen == n {
            found_any = true;
            var centroid = p.centers[f_idx];
            var f_normal = p.normals[f_idx];

            var inner_face_ids: Face = []; inner_face_ids.resize(flen, 0);

            // Generate the new internal vertices of the cap
            for v, idx in face {
                var v_pos = p.vertexes[v];

                // Calculate the base position interpolating towards the center
                var base_tween = v_pos.tween(centroid, inset_dist);
                // Add the three-dimensional displacement of the normal (extrusion)
                // v_new = base_tween + (normal * popout_dist)
                var v_new_pos = base_tween + (f_normal * popout_dist);

                var new_id = new_vertices.len;
                new_vertices.push(v_new_pos);
                inner_face_ids[idx] = new_id as u32;
            }
            // Build the walls (lateral trapezoids)
            var v1_idx = flen - 1;
            for v2, v2_idx in face {
                var v1 = face[v1_idx];
                var v1_new = inner_face_ids[v1_idx];
                var v2_new = inner_face_ids[v2_idx];

                var iv1 = v1;
                var iv2 = v2;

                // Build the lateral trapezoid: {iv1, iv2, v2new, v1new}
                new_faces.push([iv1, iv2, v2_new, v1_new]);

                v1_idx = v2_idx;
            }

            // Add the reduced internal cap as a new face
            new_faces.push(copy(inner_face_ids));
        } else {
            // If the face does not meet the filter, we clone it exactly like the original
            new_faces.push(copy(face));
        }
    }

    if !found_any && n != 0 {
        print("No faces matched the filter criteria.")
    } else {
        newPoly(p, "n", new_faces, new_vertices);
    }
}

fn gyro(p: Polyhedron&) {
    p.calc_centers();

    var edge_map = dictionary<EdgeKey, EdgeKey> {};

    var new_vertices = copy(p.vertexes);
    var new_faces: Faces = [];

    // Save the ID of the center of each face
    var face_centers_ids: Face = []; face_centers_ids.resize(p.nFaces(), 0);

    // Generate face centers and the 2 unified vertices per edge
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue }

        face_centers_ids[f_idx] = new_vertices.len as u32;
        new_vertices.push(p.centers[f_idx]);

        for j in flen {
            var v1 = face[(j + flen - 2) % flen];
            var v2 = face[(j + flen - 1) % flen];

            var e_key = ek_sorted(v1, v2);
            if !edge_map.contains(e_key) {
                // Since e_key orders internally from lowest to highest, we determine the real order in space
                var v_low = if v1 < v2 { v1 } else { v2 };
                var v_high = if v1 < v2 { v2 } else { v1 };

                var id_low_third = new_vertices.len as u32;
                new_vertices.push(p.vertexes[v_low].one_third(p.vertexes[v_high]));

                var id_high_third = new_vertices.len as u32;
                new_vertices.push(p.vertexes[v_high].one_third(p.vertexes[v_low]));

                edge_map.insert(e_key, EdgeKey { id_low_third, id_high_third });
            }
        }
    }

    // Exact stitching of chiral pentagons
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue }

        var cntr_id = face_centers_ids[f_idx];

        for j in flen {
            var v1 = face[(j + flen - 2) % flen];
            var v2 = face[(j + flen - 1) % flen];
            var v3 = face[j];

            // Recover the vertex pairs of the three involved edges
            var ev_12 = edge_map.get(ek_sorted(v1, v2));
            var ev_23 = edge_map.get(ek_sorted(v2, v3));

            if ev_12 && ev_23 {
                // Solve mathematically which ID corresponds to the real directional sense
                // e_v1_v2: the point at 1/3 of the way from v1 towards v2
                var e_v1_v2 = if v1 < v2 { ev_12.v1 } else { ev_12.v2 };
                // e_v2_v1: the point at 1/3 of the way from v2 towards v1 (that is, at 2/3 from v1)
                var e_v2_v1 = if v1 < v2 { ev_12.v2 } else { ev_12.v1 };
                // e_v2_v3: the point at 1/3 of the way from v2 towards v3
                var e_v2_v3 = if v2 < v3 { ev_23.v1 } else { ev_23.v2 };

                // Stitch the chiral pentagon identical to the C++ Winding Order
                new_faces.push([cntr_id, e_v1_v2, e_v2_v1, v2, e_v2_v3]);
            }
        }
    }

    newPoly(p, "g", new_faces, new_vertices);
}

fn propellor(p: Polyhedron&) {
    var edge_map = dictionary<EdgeKey, EdgeKey> {};

    var new_vertices = copy(p.vertexes);
    var new_faces: Faces = [];

    // Generate the 2 unified vertices per edge
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue }

        for j in flen {
            var v1 = face[(j + flen - 2) % flen];
            var v2 = face[(j + flen - 1) % flen];

            var e_key = ek_sorted(v1, v2);
            if !edge_map.contains(e_key) {
                // Since e_key orders internally from lowest to highest, we determine the real order in space
                var v_low = if v1 < v2 { v1 } else { v2 };
                var v_high = if v1 < v2 { v2 } else { v1 };

                var id_low_third = new_vertices.len as u32;
                new_vertices.push(p.vertexes[v_low].one_third(p.vertexes[v_high]));

                var id_high_third = new_vertices.len as u32;
                new_vertices.push(p.vertexes[v_high].one_third(p.vertexes[v_low]));

                edge_map.insert(e_key, EdgeKey { id_low_third, id_high_third });
            }
        }
    }

    // Build the faces central helix + quadrilaterals of union
    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue }

        // Reserve memory for the new central cap (same number of sides as the original)
        var central_face: Face = []; central_face.resize(flen, 0);

        for j in flen {
            var v1 = face[(j + flen - 2) % flen];
            var v2 = face[(j + flen - 1) % flen];
            var v3 = face[j];

            // Recover the vertex pairs of the three involved edges
            var ev_12 = edge_map.get(ek_sorted(v1, v2));
            var ev_23 = edge_map.get(ek_sorted(v2, v3));

            if ev_12 && ev_23 {
                // Solve the exact geometric directional senses
                var e_v1_v2 = if v1 < v2 { ev_12.v1 } else { ev_12.v2 };
                var e_v2_v1 = if v1 < v2 { ev_12.v2 } else { ev_12.v1 };
                var e_v2_v3 = if v2 < v3 { ev_23.v1 } else { ev_23.v2 };

                // fill the corresponding gap of the central helix [e_v1_v2, e_v2_v3, ...]
                central_face[j] = e_v1_v2;
                // Stitch the chiral pentagon identical to the C++ Winding Order
                new_faces.push([e_v1_v2, e_v2_v1, v2, e_v2_v3]);
            }
        }
        // At the end of STEP 2 of propellor, before adding central_face:
        // We invert the slice to correct the Winding Order (counterclockwise direction)

        var right = central_face.len - 1;
        var left = 0;

        while left < right {
            swap_at(central_face, left, right);

            right -= 1;
            left += 1;
        }
        new_faces.push(copy(central_face));
    }

    newPoly(p, "p", new_faces, new_vertices);
}

fn hollow(p: Polyhedron&, inset_dist: f32 = 0.2, thickness: f32 = 0.1) {
    p.calc_centers();
    var normals = p.avg_normals();

    var new_vertices = copy(p.vertexes);
    var new_faces: Faces = [];

    for f_idx in p.nFaces() {
        var face = p.getFace(f_idx);
        var flen = face.len;
        if flen < 3 { continue; }

        var centroid = p.centers[f_idx];
        var normal = normals[f_idx];

        // PROTECTION AGAINST TOPOLOGICAL EXPLOSION (For HaaaaD and similar)
        // If the accumulated normal of the face came collapsed or null, we use a safe spherical fallback

        var normal_len_sq = normal.lengthSq();
        if normal_len_sq < 0.9 {
            var cent_len = centroid.length();
            normal = if cent_len > 0.0001 {
                centroid / cent_len
            } else {
                // use a safe spherical fallback
                Vertex<f32> { 1.0, 0.0, 0.0 }
            };
        }

        // DYNAMIC ADAPTATION OF MEASUREMENTS (Prevents microscopic faces from piercing the mesh)
        // We measure the real distance of the first vertex to the centroid to estimate the size of the face

        // We measure the real distance of the first vertex to the centroid to estimate the size of the face
        var v0 = p.vertexes[face[0]];
        var dist_to_centroid = v0.distanceSq(centroid);

        // If the face is a tiny "needle", we smooth the inset and proportionally scale the thickness
        var local_inset = if (inset_dist * dist_to_centroid < 0.001) { 0.05 } else { inset_dist };
        var local_thickness = if thickness > dist_to_centroid { dist_to_centroid * 0.2 } else { thickness };

        // STABLE ORIENTATION CORRECTION
        var invert_winding = false;
        if normal.dot(centroid) < 0.0 {
            normal = -normal;
            invert_winding = true;
        }

        // 1st step. local ID mappings of this face
        var inset_ids: Face = []; inset_ids.resize(flen, 0);
        var down_ids:  Face = []; down_ids.resize(flen, 0);

        // 1st step. generate vertices (towards the inside)
        for v, idx in face {
            var v_pos = p.vertexes[v];

            // Inset Vertex on the exterior plane of the face
            var ins_pt = v_pos.tween(centroid, local_inset);
            inset_ids[idx] = new_vertices.len as u32;
            new_vertices.push(ins_pt);

            // Down Vertex (Sunk perpendicularly subtracting the clean normal)
            var down_pt = ins_pt - (normal * local_thickness);
            down_ids[idx] = new_vertices.len as u32;
            new_vertices.push(down_pt);
        }

        // 2nd step, make final faces
        var idx1 = flen - 1;
        for v2, idx2 in face {
            var iv1, iv2 = face[idx1], v2;
            var fin1, fin2 = inset_ids[idx1], inset_ids[idx2];
            var down1, down2 = down_ids[idx1], down_ids[idx2];

            var frame_face: Face = if invert_winding { [iv1, iv2, fin2, fin1] } else { [fin1, fin2, iv2, iv1] };
            var wall_face:  Face = if invert_winding { [down1, down2, fin2, fin1] } else { [fin1, fin2, down2, down1] };

            new_faces.push(copy(frame_face));
            new_faces.push(copy(wall_face));

            idx1 = idx2;
        }
    }

    newPoly(p, "H", new_faces, new_vertices);
}

// test

fn test_trans() {
    var p = Polyhedron {};
    p.fromStatic(Dodecahedron);
    print(p.name, ", faces:", p.nFaces(), ", vertices:", p.vertexes.len,);

    let t0 = clock();
    for i in 2 {
        hollow(p);
        print(i + 1, ":", p.name, ", faces:", p.nFaces(), ", vertices:", p.vertexes.len, ", lap:", (1000.0 * (clock() - t0)) as i32, " ms");
    }

    if false {
        p.recalc();
        p.write_PLYbin("conway.ply");
    }
}

fn main() { test_trans() }
