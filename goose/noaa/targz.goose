// archive wrapper
// wrapper

namespace targz;

import ffi;
import std;

//
type Archive = u64; // archive pointer
type ArchiveEntry = u64;
type c_int = i32; // c int
type pointer = u64;
type char_ptr = u64;

const BUFF_SIZE = 1024 * 16;

// error codes
const ARCHIVE_EOF:    c_int = 1;
const ARCHIVE_OK:     c_int = 0;
const ARCHIVE_RETRY:  c_int = -10;
const ARCHIVE_WARN:   c_int = -20;
const ARCHIVE_FAILED: c_int = -25;
const ARCHIVE_FATAL:  c_int = -30;

// libarchive wrapper
extern "archive" {
    fn archive_zlib_version() -> char_ptr;
    fn archive_liblzma_version() -> char_ptr;
    fn archive_bzlib_version() -> char_ptr;
    fn archive_liblz4_version() -> char_ptr;
    fn archive_libzstd_version() -> char_ptr;
    fn archive_liblzo2_version() -> char_ptr;
    fn archive_libexpat_version() -> char_ptr;
    fn archive_libbsdxml_version() -> char_ptr;
    fn archive_libxml2_version() -> char_ptr;
    fn archive_mbedtls_version() -> char_ptr;
    fn archive_nettle_version() -> char_ptr;
    fn archive_openssl_version() -> char_ptr;
    fn archive_libmd_version() -> char_ptr;
    fn archive_commoncrypto_version() -> char_ptr;
    fn archive_cng_version() -> char_ptr;
    fn archive_wincrypt_version() -> char_ptr;
    fn archive_librichacl_version() -> char_ptr;
    fn archive_libacl_version() -> char_ptr;
    fn archive_libattr_version() -> char_ptr;
    fn archive_libiconv_version() -> char_ptr;
    fn archive_libpcre_version() -> char_ptr;
    fn archive_libpcre2_version() -> char_ptr;
    fn archive_version_details() -> char_ptr;
    fn archive_version_string() -> char_ptr;

    fn archive_read_new() -> Archive;
    fn archive_read_support_format_all(archive: Archive) -> c_int; // ARCHIVE_OK = 0
    fn archive_read_support_filter_all(archive: Archive) -> c_int; // ARCHIVE_OK = 0
    fn archive_read_open_filename(archive: Archive, filename: const u8&) -> c_int; // ARCHIVE_OK = 0
    fn archive_read_close(archive: Archive) -> c_int; // ARCHIVE_OK = 0
    fn archive_read_free(archive: Archive) -> c_int; // ARCHIVE_OK = 0
    fn archive_read_next_header(archive: Archive, entry: ArchiveEntry&) -> c_int; // ARCHIVE_OK = 0
    fn archive_entry_pathname(entry: ArchiveEntry) -> char_ptr;
    fn archive_entry_size(entry: ArchiveEntry) -> u64;
    fn archive_read_data(entry: ArchiveEntry, buffer: const u8&, size: u64) -> i64;
}

root struct TarGz {
    archive:  Archive      = 0,
    result:   i32          = 0,
    entry:    ArchiveEntry = 0,
    buffer:   u8[>..]      = [],
    filename: u8[>..]      = [],
}

fn open(tar: TarGz&, filename: u8[:]) {
    var archive = archive_read_new();

    var result = archive_read_support_format_all(archive);
    result |= archive_read_support_filter_all(archive);
    var fn0: u8[>..] = "";
    format(fn0, filename, "\0");
    result |= archive_read_open_filename(archive, fn0[0]);

    tar.archive = archive;
    tar.result = result;
    tar.entry = 0;
    tar.buffer = [];
    tar.filename = [];
}

fn ok(tar: TarGz&) -> bool {
    return tar.result == ARCHIVE_OK;
}

fn next(tar: TarGz&) -> bool {
    tar.result = archive_read_next_header(tar.archive, tar.entry);
    tar.filename = ffi::cstr(archive_entry_pathname(tar.entry));
    return tar.result == ARCHIVE_OK;
}
fn read(tar: TarGz&) -> i64 {
    tar.buffer.clear();

    loop {
        var buffer: u8[BUFF_SIZE + 1] = [0; BUFF_SIZE + 1];
        var br = archive_read_data(tar.archive, buffer[0], BUFF_SIZE);
        if br <= 0 { break; }

        format(tar.buffer, buffer[..br]);
    }
    return tar.buffer.len;
}
fn close(tar: TarGz&) {
    archive_read_close(tar.archive);
}
fn free(tar: TarGz&) {
    archive_read_free(tar.archive);
}

// test

fn test_targz() {
    var tar = TarGz {};
    tar.open("/home/asd/code/noaa/data/ghcnd_all.tar.gz");
    while tar.next() {
        if tar.filename.find(".dly") != -1 {
            tar.read();
            print(tar.filename, ", ", tar.buffer.len, " -> ", tar.buffer[..min(40, tar.buffer.len)]);

            let from = tar.filename.find("/");
            let to = tar.filename.find(".dly");
            assert(tar.buffer[..11] == tar.filename[from + 1..to]);
        }
    }
    tar.close();
    tar.free();
}

// fn main() { test_targz(); }
