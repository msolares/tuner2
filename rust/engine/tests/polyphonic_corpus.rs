use afinador_engine::polyphonic::{PolyphonicChordAnalyzer, PolyphonicConfig};
use std::collections::BTreeSet;
use std::fs;
use std::path::{Component, Path, PathBuf};

const SAMPLE_RATE: u32 = 48_000;
const CHUNK_SAMPLES: usize = 2_048;
const MAX_VERDICT_MS: u32 = 750;
const REQUIRED_STRENGTH: f32 = 0.45;
const REQUIRED_MEAN: f32 = 0.60;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Expected {
    Positive,
    Negative,
}

#[derive(Debug)]
struct CorpusCase {
    file: PathBuf,
    expected: Expected,
    target_label: String,
    target_pitch_classes: Vec<usize>,
    guitar: String,
    intensity: String,
    attack_ms: u32,
    category: String,
}

#[derive(Debug, Default)]
struct Metrics {
    positives: usize,
    positive_hits: usize,
    negatives: usize,
    false_accepts: usize,
    latencies_ms: Vec<u32>,
}

#[test]
#[ignore = "requires the official versioned PCM corpus"]
fn official_polyphonic_corpus_meets_quality_gates() {
    let corpus_root = Path::new(env!("CARGO_MANIFEST_DIR")).join("testdata/polyphonic");
    let manifest_path = corpus_root.join("manifest.csv");
    let manifest = fs::read_to_string(&manifest_path).unwrap_or_else(|error| {
        panic!(
            "official corpus manifest is required at {}: {error}",
            manifest_path.display()
        )
    });
    let cases = parse_manifest(&manifest).expect("valid official corpus manifest");
    validate_coverage(&cases).expect("official corpus coverage");

    let mut metrics = Metrics::default();
    for case in &cases {
        let path = corpus_root.join(&case.file);
        let bytes = fs::read(&path)
            .unwrap_or_else(|error| panic!("cannot read corpus file {}: {error}", path.display()));
        let pcm = decode_pcm_f32le(&bytes)
            .unwrap_or_else(|error| panic!("invalid corpus file {}: {error}", path.display()));
        let latency = first_acceptance_latency(&pcm, case);
        match case.expected {
            Expected::Positive => {
                metrics.positives += 1;
                if let Some(latency_ms) = latency {
                    metrics.positive_hits += 1;
                    metrics.latencies_ms.push(latency_ms);
                }
            }
            Expected::Negative => {
                metrics.negatives += 1;
                if latency.is_some() {
                    metrics.false_accepts += 1;
                }
            }
        }
    }

    let recall = metrics.positive_hits as f32 / metrics.positives as f32;
    let false_acceptance = metrics.false_accepts as f32 / metrics.negatives as f32;
    let p95 = percentile_95(&mut metrics.latencies_ms).expect("at least one positive hit");
    println!(
        "polyphonic corpus: recall={recall:.3}, false_acceptance={false_acceptance:.3}, p95={p95}ms"
    );

    assert!(recall >= 0.90, "recall {recall:.3} is below 0.90");
    assert!(
        false_acceptance <= 0.05,
        "false acceptance {false_acceptance:.3} exceeds 0.05"
    );
    assert!(p95 <= MAX_VERDICT_MS, "p95 {p95}ms exceeds 750ms");
}

fn first_acceptance_latency(pcm: &[f32], case: &CorpusCase) -> Option<u32> {
    let attack_sample = case.attack_ms as usize * SAMPLE_RATE as usize / 1_000;
    let deadline_sample = attack_sample
        .saturating_add(MAX_VERDICT_MS as usize * SAMPLE_RATE as usize / 1_000)
        .min(pcm.len());
    let mut analyzer = PolyphonicChordAnalyzer::new(PolyphonicConfig::default());
    let mut offset = 0;

    while offset < deadline_sample {
        let end = offset.saturating_add(CHUNK_SAMPLES).min(deadline_sample);
        if end - offset < 256 {
            break;
        }
        let evidence = analyzer
            .process(&pcm[offset..end], SAMPLE_RATE)
            .expect("validated corpus frame");
        if end >= attack_sample
            && accepts_target(&evidence.pitch_class_strengths, &case.target_pitch_classes)
            && evidence.onset_sequence > 0
        {
            return Some(((end - attack_sample) as u64 * 1_000 / SAMPLE_RATE as u64) as u32);
        }
        offset = end;
    }
    None
}

fn accepts_target(strengths: &[f32; 12], required: &[usize]) -> bool {
    if required.is_empty() {
        return false;
    }
    let values = required.iter().map(|pitch_class| strengths[*pitch_class]);
    let mean = values.clone().sum::<f32>() / required.len() as f32;
    values.fold(f32::INFINITY, f32::min) >= REQUIRED_STRENGTH && mean >= REQUIRED_MEAN
}

fn parse_manifest(source: &str) -> Result<Vec<CorpusCase>, String> {
    let mut cases = Vec::new();
    for (index, raw_line) in source.lines().enumerate() {
        let line_number = index + 1;
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with("file,") {
            continue;
        }
        let fields: Vec<_> = line.split(',').map(str::trim).collect();
        if fields.len() != 8 {
            return Err(format!("line {line_number}: expected 8 CSV fields"));
        }
        let file = PathBuf::from(fields[0]);
        if file.as_os_str().is_empty()
            || file.is_absolute()
            || file.components().any(|part| part == Component::ParentDir)
        {
            return Err(format!("line {line_number}: unsafe relative file path"));
        }
        let expected = match fields[1] {
            "positive" => Expected::Positive,
            "negative" => Expected::Negative,
            _ => return Err(format!("line {line_number}: invalid expected value")),
        };
        let target_pitch_classes = parse_pitch_classes(fields[3])
            .map_err(|error| format!("line {line_number}: {error}"))?;
        let attack_ms = fields[6]
            .parse::<u32>()
            .map_err(|_| format!("line {line_number}: invalid attack_ms"))?;
        if fields[2].is_empty()
            || fields[4].is_empty()
            || fields[5].is_empty()
            || fields[7].is_empty()
        {
            return Err(format!("line {line_number}: required field is empty"));
        }
        cases.push(CorpusCase {
            file,
            expected,
            target_label: fields[2].to_owned(),
            target_pitch_classes,
            guitar: fields[4].to_owned(),
            intensity: fields[5].to_owned(),
            attack_ms,
            category: fields[7].to_owned(),
        });
    }
    if cases.is_empty() {
        return Err("manifest has no cases".to_owned());
    }
    Ok(cases)
}

fn parse_pitch_classes(value: &str) -> Result<Vec<usize>, String> {
    let mut result = Vec::new();
    for name in value.split('|').map(str::trim) {
        let pitch_class = match name {
            "C" => 0,
            "C#" | "Db" => 1,
            "D" => 2,
            "D#" | "Eb" => 3,
            "E" => 4,
            "F" => 5,
            "F#" | "Gb" => 6,
            "G" => 7,
            "G#" | "Ab" => 8,
            "A" => 9,
            "A#" | "Bb" => 10,
            "B" => 11,
            _ => return Err(format!("invalid pitch class {name}")),
        };
        if !result.contains(&pitch_class) {
            result.push(pitch_class);
        }
    }
    if result.is_empty() {
        return Err("target_pitch_classes is empty".to_owned());
    }
    Ok(result)
}

fn validate_coverage(cases: &[CorpusCase]) -> Result<(), String> {
    let positives: Vec<_> = cases
        .iter()
        .filter(|case| case.expected == Expected::Positive)
        .collect();
    let negatives: Vec<_> = cases
        .iter()
        .filter(|case| case.expected == Expected::Negative)
        .collect();
    if positives.is_empty() || negatives.is_empty() {
        return Err("positive and negative cases are required".to_owned());
    }

    let labels: BTreeSet<_> = positives
        .iter()
        .map(|case| case.target_label.as_str())
        .collect();
    for required in ["C", "A", "G", "E", "D", "Am", "Em", "Dm"] {
        if !labels.contains(required) {
            return Err(format!("missing positive chord {required}"));
        }
    }
    if labels.iter().filter(|label| label.ends_with('5')).count() < 2 {
        return Err("power chords in at least two roots are required".to_owned());
    }
    let guitars: BTreeSet<_> = positives.iter().map(|case| case.guitar.as_str()).collect();
    let intensities: BTreeSet<_> = positives
        .iter()
        .map(|case| case.intensity.as_str())
        .collect();
    if guitars.len() < 2 || intensities.len() < 3 {
        return Err("positives require at least two guitars and three intensities".to_owned());
    }

    let categories: BTreeSet<_> = negatives
        .iter()
        .map(|case| case.category.as_str())
        .collect();
    for required in [
        "neighboring_chord",
        "missing_required_tone",
        "extra_string_substitution",
        "isolated_note",
        "noise",
        "voice",
    ] {
        if !categories.contains(required) {
            return Err(format!("missing negative category {required}"));
        }
    }
    Ok(())
}

fn decode_pcm_f32le(bytes: &[u8]) -> Result<Vec<f32>, String> {
    if bytes.is_empty() || !bytes.len().is_multiple_of(4) {
        return Err("PCM must contain complete f32le samples".to_owned());
    }
    bytes
        .chunks_exact(4)
        .enumerate()
        .map(|(index, chunk)| {
            let sample = f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
            if sample.is_finite() {
                Ok(sample)
            } else {
                Err(format!("sample {index} is not finite"))
            }
        })
        .collect()
}

fn percentile_95(values: &mut [u32]) -> Option<u32> {
    if values.is_empty() {
        return None;
    }
    values.sort_unstable();
    let index = (values.len() * 95).div_ceil(100).saturating_sub(1);
    Some(values[index])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn manifest_parser_accepts_documented_row() {
        let cases = parse_manifest(
            "file,expected,target_label,target_pitch_classes,guitar,intensity,attack_ms,category\n\
             guitar-a/C-medium-01.pcm,positive,C,C|E|G,guitar-a,medium,100,clean",
        )
        .expect("manifest");
        assert_eq!(cases.len(), 1);
        assert_eq!(cases[0].target_pitch_classes, vec![0, 4, 7]);
    }

    #[test]
    fn manifest_parser_rejects_parent_traversal() {
        let error = parse_manifest("../outside.pcm,positive,C,C|E|G,g1,soft,0,clean")
            .expect_err("unsafe path");
        assert!(error.contains("unsafe"));
    }

    #[test]
    fn pcm_decoder_rejects_partial_and_non_finite_samples() {
        assert!(decode_pcm_f32le(&[0, 1, 2]).is_err());
        assert!(decode_pcm_f32le(&f32::NAN.to_le_bytes()).is_err());
        assert_eq!(decode_pcm_f32le(&0.25_f32.to_le_bytes()), Ok(vec![0.25]));
    }

    #[test]
    fn percentile_uses_nearest_rank() {
        let mut values: Vec<u32> = (1..=20).collect();
        assert_eq!(percentile_95(&mut values), Some(19));
        assert_eq!(percentile_95(&mut []), None);
    }
}
