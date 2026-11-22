import ctypes
import numpy as np


class ConwayLib:
    def __init__(self, so_path: str = "./libconway.so"):
        self.lib = ctypes.CDLL(so_path)

        self.lib.goose_init.argtypes = [ctypes.c_int, ctypes.POINTER(ctypes.c_char_p)]
        self.lib.goose_init.restype = None

        self.lib.goose_exit.argtypes = []
        self.lib.goose_exit.restype = None

        self.lib.gs_free.argtypes = [ctypes.c_uint64]
        self.lib.gs_free.restype = None
        
        self.lib.write_ply.argtypes = [ctypes.c_uint64, ctypes.c_uint64]
        self.lib.write_ply.restype = None

        # export fn transform(
        #     tr: u64,
        #     n: u32,
        #     param: f32,
        #     out_faces_ptr: u64&,
        #     faces_len: u32&,
        #     out_verts_ptr: u64&,
        #     vertexes_len: u32&,
        #     out_colors_ptr: u64&,
        #     colors_len: u32&
        # )
        self.lib.transform.argtypes = [
            ctypes.c_uint64,                  # tr
            ctypes.c_uint32,                  # n
            ctypes.c_float,                   # param
            ctypes.POINTER(ctypes.c_uint64),  # out_faces_ptr: u64&
            ctypes.POINTER(ctypes.c_uint32),  # faces_len: u32&
            ctypes.POINTER(ctypes.c_uint64),  # out_verts_ptr: u64&
            ctypes.POINTER(ctypes.c_uint32),  # vertexes_len: u32&
            ctypes.POINTER(ctypes.c_uint64),  # out_colors_ptr: u64&
            ctypes.POINTER(ctypes.c_uint32),  # colors_len: u32&
        ]
        self.lib.transform.restype = ctypes.c_uint32

        self.lib.goose_init(0, None)
        self._initialized = True

    def close(self):
        if self._initialized:
            self.lib.goose_exit()
            self._initialized = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()

    def __del__(self):
        self.close()

    def _wrap_ptr(self, ptr: int, count: int, dtype, shape=None) -> np.ndarray:
        if not ptr or count == 0:
            return np.empty(0, dtype=dtype).reshape(shape) if shape else np.empty(0, dtype=dtype)

        c_type = ctypes.c_uint32 if np.dtype(dtype) == np.uint32 else ctypes.c_float
        raw_ptr = ctypes.cast(ctypes.c_void_p(ptr), ctypes.POINTER(c_type))
        
        arr = np.ctypeslib.as_array(raw_ptr, shape=(count,)).copy()
        self.lib.gs_free(ctypes.c_uint64(ptr))
        return arr.reshape(shape) if shape else arr

    def transform(self, tr: str, n: int, param: float):
        
        c_tr = ctypes.c_char_p(tr.encode("utf-8"))
        tr_addr = ctypes.cast(c_tr, ctypes.c_void_p).value or 0

        faces_ptr = ctypes.c_uint64(0)
        faces_len = ctypes.c_uint32(0)

        verts_ptr = ctypes.c_uint64(0)
        verts_len = ctypes.c_uint32(0)

        colors_ptr = ctypes.c_uint64(0)
        colors_len = ctypes.c_uint32(0)       

        lap = self.lib.transform(
            ctypes.c_uint64(tr_addr),
            ctypes.c_uint32(n),
            ctypes.c_float(param),
            ctypes.byref(faces_ptr),
            ctypes.byref(faces_len),
            ctypes.byref(verts_ptr),
            ctypes.byref(verts_len),
            ctypes.byref(colors_ptr),
            ctypes.byref(colors_len),        
        )

        faces = self._wrap_ptr(faces_ptr.value, faces_len.value, np.uint32)
        vertexes = self._wrap_ptr(verts_ptr.value, verts_len.value, np.float32, shape=(-1, 3))
        colors = self._wrap_ptr(colors_ptr.value, colors_len.value, np.float32, shape=(-1, 3))
       
        return lap, faces, vertexes, colors
    
    def write_ply(self, tr: str, filename: str):
        
        c_tr = ctypes.c_char_p(tr.encode("utf-8"))
        c_filename = ctypes.c_char_p(filename.encode("utf-8"))
        tr_addr = ctypes.cast(c_tr, ctypes.c_void_p).value or 0
        filename_addr = ctypes.cast(c_filename, ctypes.c_void_p).value or 0
        
        self.lib.write_ply(ctypes.c_uint64(tr_addr), ctypes.c_uint64(filename_addr))

def transform(tr: str, n: int, param: float):
    with ConwayLib("./libconway.so") as conway:
        return conway.transform(tr, n, param)
    
def write_ply(tr: str, filename: str):
    with ConwayLib("./libconway.so") as conway:
        return conway.write_ply(tr, filename)
    
if __name__ == "__main__":
    with ConwayLib("./libconway.so") as conway:
        for tr in ("wD", "qakwD"):
            lap, faces, vertexes, colors = conway.transform(tr, 1, 1.0)
            print(f"{tr}: faces={len(faces)} {faces[:4]}, verts={len(vertexes)} {vertexes[:4]}, colors={len(colors)} {colors[:4]}")