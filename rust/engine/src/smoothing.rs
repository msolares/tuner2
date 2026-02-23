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
        Self::new(0.2)
    }
}

impl Smoother {
    pub fn new(smoothing: f32) -> Self {
        Self {
            alpha: blend_alpha(smoothing),
            last_hz: None,
        }
    }

    pub fn set_smoothing(&mut self, smoothing: f32) {
        self.alpha = blend_alpha(smoothing);
    }

    pub fn apply(&mut self, detection: Detection) -> SmoothedPitch {
        if detection.hz <= 0.0 {
            return SmoothedPitch {
                hz: 0.0,
                confidence: 0.0,
            };
        }

        let smoothed_hz = if let Some(last) = self.last_hz {
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
        let confidence = 0.45 * energy + 0.35 * detection.periodicity_hint + 0.20 * stability;
        self.last_hz = Some(smoothed_hz);

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

fn blend_alpha(smoothing: f32) -> f32 {
    (smoothing.clamp(0.0, 1.0) * 0.45).clamp(0.05, 0.20)
}

#[cfg(test)]
mod tests {
    use super::Smoother;
    use crate::detector::Detection;

    #[test]
    fn keeps_confidence_in_unit_range() {
        let mut smoother = Smoother::new(0.8);
        let sample = Detection {
            hz: 440.0,
            signal_rms: 0.6,
            periodicity_hint: 0.9,
        };
        let result = smoother.apply(sample);
        assert!((0.0..=1.0).contains(&result.confidence));
    }

    #[test]
    fn returns_zero_for_invalid_detection() {
        let mut smoother = Smoother::default();
        let result = smoother.apply(Detection {
            hz: 0.0,
            signal_rms: 0.02,
            periodicity_hint: 0.1,
        });
        assert_eq!(result.hz, 0.0);
        assert_eq!(result.confidence, 0.0);
    }
}
