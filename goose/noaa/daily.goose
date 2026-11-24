import targz;
import aux_files;

const DailyFile = "/home/asd/code/noaa/data/ghcnd_all.tar.gz";
const DAILY_LINE_SIZE = 270; // including \n

struct DailyValue {
    value: i16 = 0,
    mflag: u8  = 0,
    qflag: u8  = 0,
    sflag: u8  = 0,
}

struct Daily {
    id:      u8[11]         = [0; 11],
    year:    u16            = 0,
    month:   u8             = 0,
    element: u8[4]          = [0; 4],
    values:  DailyValue[31] = [DailyValue {}; 31],
}

fn parse(daily: Daily&, buffer: u8[:]) -> Daily& {
    daily.id[..].move_from(buffer[..11]);
    daily.year = parse_int(buffer[11..15]) as u16;
    daily.month = parse_int(buffer[15..17]) as u8;
    daily.element[..].move_from(buffer[17..21]);

    // 31 values
    for day in 31 {
        daily.values[day].value = parse_int(buffer[21 + day * 8..21 + day * 8 + 5].trim()) as i16;
        daily.values[day].mflag = buffer[26 + day * 8];
        daily.values[day].qflag = buffer[27 + day * 8];
        daily.values[day].sflag = buffer[28 + day * 8];
    }
    daily
}

fn getCountry(daily: Daily&) -> const u8[:]? { find_country(daily.id[..2]) }
fn getStation(daily: Daily&) -> Station? { find_station(daily.id) }
fn getElement(daily: Daily&) -> const u8[:]? { find_element(daily.element) }

fn all_values_ok(daily: Daily&) -> bool {
    for day in 31 {
        if daily.values[day].value == -9999 {
            return false;
        }
    }
    return true;
}

fn max_value(daily: Daily&) -> i16 {
    var max: i16 = -9999;
    for day in 31 {
        if daily.values[day].value > max {
            max = daily.values[day].value;
        }
    }
    return max;
}

fn daily_traverse<F>(dailys: Daily[>..]&, max_found: i32 = 0, max_files: i32 = 0) { // traverse condition
    var tar = targz::TarGz {};
    tar.open(DailyFile);

    var n_files: i32 = 0;
    while tar.next() {
        if tar.filename.find(".dly") != -1 {
            tar.read(); // read & process file

            var daily = Daily {};

            each_split(tar.buffer, '\n') { data_file =>
                if data_file.len == DAILY_LINE_SIZE - 1 {
                    daily.parse(data_file);

                    if F(daily) { // test condition
                        dailys.push(daily);
                        if max_found > 0 && dailys.len >= max_found {
                            return;
                        }
                    }
                }
            }
            n_files += 1;
            if max_files > 0 && n_files >= max_files {
                return;
            }
        }
    }

    tar.close();
    tar.free();
}

fn main() {
    read_aux();

    print("traversing daily");

    var t0 = clock();

    var dailys: Daily[>..] = [];
    dailys.daily_traverse(30) { daily => // filter condition
        daily.element == "TMIN" &&
        daily.year == 2025 &&
        max_value(daily) / 10.0 > 35.0
    }

    t0 = clock() - t0;

    var mx = -1;
    for d in dailys {
        print("|", d.id, "|", getCountry(d), "|", d.year, "|", d.month, "|", d.element, "|", max_value(d) / 10.0);
        mx = max(mx, max_value(d));
    }
    print("items:", dailys.len, " max:", mx / 10.0, ", lap:", t0 as i32, " secs");
}
