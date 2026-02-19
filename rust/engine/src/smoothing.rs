use crate::detector::Detection;

#[derive(Debug, Clone, Copy)]
pub struct SmoothedPitch {
    pub hz: f32,
    pub confidence: f32,
}

#[derive(Debug, Clone)]
pub struct Smoother {
    alpha: f32,
    last_hz: Option<f32>,
}

impl Default for Smoother {
    fn default() -> Self {
        Self {
            alpha: 0.2,
            last_hz: None,
        }
    }
}

impl Smoother {
    pub fn apply(&mut self, detection: Detection) -> SmoothedPitch {
        let smoothed_hz = if detection.hz <= 0.0 {
            self.last_hz.unwrap_or(0.0)
        } else if let Some(last) = self.last_hz {
            self.alpha * detection.hz + (1.0 - self.alpha) * last
        } else {
            detection.hz
        };

        let stability = if let Some(last) = self.last_hz {
            if last > 0.0 && smoothed_hz > 0.0 {
                let cents_delta = 1200.0 * (smoothed_hz / last).log2().abs();
                (1.0 - cents_delta / 50.0).clamp(0.0, 1.0)
            } else {
                0.0
            }
        } else {
            0.5
        };

        let energy = (detection.signal_rms * 8.0).clamp(0.0, 1.0);
        let validity = if detection.hz > 0.0 { 1.0 } else { 0.0 };
        let confidence = (0.45 * energy + 0.35 * detection.periodicity_hint + 0.20 * stability) * validity;

        self.last_hz = if smoothed_hz > 0.0 { Some(smoothed_hz) } else { self.last_hz };

        SmoothedPitch {
            hz: smoothed_hz,
            confidence: confidence.clamp(0.0, 1.0),
        }
    }
}

pub fn smooth_detection(detection: Detection) -> SmoothedPitch {
    let mut smoother = Smoother::default();
    smoother.apply(detection)
}
