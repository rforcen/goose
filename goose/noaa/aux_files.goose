// NOAA aux files reader
// creates struct with dictionaries

import os;
import dictionary;

const NOAA_PATH = "/home/asd/code/noaa/data/";

type AuxDict = dictionary<const u8[:], const u8[:]>;
type StationDict = dictionary<const u8[:], Station>;

root struct AuxTable {
    buff: u8[>..] = [], // must keep the whole file here for life time reasons as the dict contains refs to it
    dct:  AuxDict = AuxDict {},
}

root struct StationTable {
    buff: u8[>..]     = [], // must keep the whole file here for life time reasons as the dict contains refs to it
    dct:  StationDict = StationDict {},
}

struct Station {
    id:           const u8[:],
    latitude:     f64,
    longitude:    f64,
    elevation:    f64,
    state:        const u8[:],
    name:         const u8[:],
    gsn_flag:     const u8[:],
    hcn_crn_flag: const u8[:],
    wmo_id:       const u8[:],
}

// Global aux tables
var countries = AuxTable {};
var states = AuxTable {};
var elements = AuxTable {};
var stations: StationTable = StationTable {};

// read aux file & populate dictionary
fn read_aux(axt: AuxTable&, filename: const u8[:], code_len: i32 = 2, gap: i32 = 1) {
    if read_file(filename, axt.buff) {
        each_split(axt.buff, '\n') {
            if it.trim().len > 0 {
                axt.dct.insert(it[..code_len], it[code_len + gap..].trim());
            }
        }
    }
}

// read stations file & populate dictionary
fn read_stations(stations: StationTable&, filename: const u8[:]) {
    if read_file(filename, stations.buff) {
        each_split(stations.buff, '\n') {
            if it.trim().len > 0 {
                stations.dct.insert(it[..11], Station {
                    id:           it[..11],
                    latitude:     parse_flt(it[12..20].trim()),
                    longitude:    parse_flt(it[21..30].trim()),
                    elevation:    parse_flt(it[31..37].trim()),
                    state:        it[38..40].trim(),
                    name:         it[41..71].trim(),
                    gsn_flag:     it[72..75].trim(),
                    hcn_crn_flag: it[76..79].trim(),
                    wmo_id:       it[80..85].trim(),
                });
            }
        }
    }
}

fn print_dict(axt: AuxTable&) {
    axt.dct.each() { k, v => { print("|", k, "|", v, "|");  } };
}

fn print_stations(stations: StationTable&) {
    stations.dct.each() { k, v => {
        print("|", k, "|", v.id, "|", v.latitude, "|", v.longitude, "|", v.elevation, "|", v.state, "|", v.name, "|", v.gsn_flag, "|", v.hcn_crn_flag, "|", v.wmo_id, "|");
    } };
}

fn print_all() {
    countries.print_dict();
    states.print_dict();
    elements.print_dict();
    stations.print_stations();
}

fn read_aux() {
    countries.read_aux(str(NOAA_PATH, "ghcnd-countries.txt"), 2, 1);
    states.read_aux(str(NOAA_PATH, "ghcnd-states.txt"), 2, 1);
    elements.read_aux(str(NOAA_PATH, "ghcnd-elements.txt"), 4, 0);
    stations.read_stations(str(NOAA_PATH, "ghcnd-stations.txt"));
}

fn _find_dct(dct: AuxDict&, code: const u8[:]) -> const u8[:]? { dct.get(code) }

fn find_country(code: const u8[:]) -> const u8[:]? { _find_dct(countries.dct, code) }
fn find_state(code: const u8[:]) -> const u8[:]? { _find_dct(states.dct, code) }
fn find_element(code: const u8[:]) -> const u8[:]? { _find_dct(elements.dct, code) }
fn find_station(id: const u8[:]) -> Station? { stations.dct.get(id) }

// test

fn main() {
    var t0 = clock();
    read_aux();
    var t1 = clock();
    print("aux load time: ", (1000.0 * (t1 - t0)) as i32, "  ms");
}
