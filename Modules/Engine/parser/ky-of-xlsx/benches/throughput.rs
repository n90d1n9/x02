//! Throughput benchmark: open + iterate an XLSX file.
//!
//! Place a representative .xlsx at `benches/fixture.xlsx`, then run:
//!   cargo bench --bench throughput

use criterion::{black_box, criterion_group, criterion_main, Criterion, Throughput};
use ky-of-xlsx::{OpenOptions, Workbook, WorkbookReader};

fn bench_open_and_iterate(c: &mut Criterion) {
    let fixture = std::path::Path::new("benches/fixture.xlsx");
    if !fixture.exists() {
        eprintln!("Benchmark fixture not found at benches/fixture.xlsx — skipping");
        return;
    }

    // Warm-up: count cells so we can set throughput
    let wb = Workbook::open(fixture).expect("open fixture");
    let total_cells: usize = wb.sheets().map(|s| s.meta().cell_count).sum();

    let mut group = c.benchmark_group("workbook");
    group.throughput(Throughput::Elements(total_cells as u64));

    group.bench_function("open_and_count_cells", |b| {
        b.iter(|| {
            let wb = Workbook::open(black_box(fixture)).unwrap();
            let n: usize = wb.sheets().map(|s| s.meta().cell_count).sum();
            black_box(n)
        })
    });

    group.bench_function("open_with_max_rows_1000", |b| {
        let opts = OpenOptions::new().max_rows(1_000);
        b.iter(|| {
            let wb = Workbook::open_with(black_box(fixture), &opts).unwrap();
            let n: usize = wb.sheets().map(|s| s.meta().cell_count).sum();
            black_box(n)
        })
    });

    group.finish();
}

criterion_group!(benches, bench_open_and_iterate);
criterion_main!(benches);
