#[derive(Debug, Clone, Copy)]
pub struct ValidatedFrame<'a> {
    pub pcm: &'a [f32],
    pub sample_rate: u32,
}

pub fn validate_frame<'a>(pcm: &'a [f32], sample_rate: u32) -> Result<ValidatedFrame<'a>, &'static str> {
    if pcm.is_empty() {
        return Err("invalid_frame");
    }
    if sample_rate == 0 {
        return Err("invalid_sample_rate");
    }
    Ok(ValidatedFrame { pcm, sample_rate })
}
