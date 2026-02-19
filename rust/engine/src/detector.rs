use crate::input::ValidatedFrame;

#[derive(Debug, Clone, Copy)]
pub struct Detection {
    pub hz: f32,
    pub signal_rms: f32,
    pub periodicity_hint: f32,
}

pub fn detect_pitch(frame: ValidatedFrame<'_>) -> Result<Detection, &'static str> {
    if frame.pcm.len() < 2 {
        return Err("frame_too_short");
    }

    let len = frame.pcm.len() as f32;
    let rms = (frame.pcm.iter().map(|s| s * s).sum::<f32>() / len).sqrt();
    if rms < 1e-4 {
        return Ok(Detection {
            hz: 0.0,
            signal_rms: rms,
            periodicity_hint: 0.0,
        });
    }

    let mut crossings = 0u32;
    let threshold = 1e-3_f32;
    let mut prev = frame.pcm[0];
    for &sample in &frame.pcm[1..] {
        let crossed = (prev >= threshold && sample <= -threshold) || (prev <= -threshold && sample >= threshold);
        if crossed {
            crossings += 1;
        }
        prev = sample;
    }

    if crossings < 2 {
        return Ok(Detection {
            hz: 0.0,
            signal_rms: rms,
            periodicity_hint: 0.1,
        });
    }

    let duration_sec = frame.pcm.len() as f32 / frame.sample_rate as f32;
    let estimated_hz = (crossings as f32 / 2.0) / duration_sec;
    let hz = if (50.0..=1200.0).contains(&estimated_hz) {
        estimated_hz
    } else {
        0.0
    };

    let crossing_density = crossings as f32 / frame.pcm.len() as f32;
    let periodicity_hint = (1.0 - (crossing_density - 0.12).abs() * 4.0).clamp(0.0, 1.0);

    Ok(Detection {
        hz,
        signal_rms: rms,
        periodicity_hint,
    })
}
