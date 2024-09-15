use godot::{
    builtin::{Array, Variant, VariantArray},
    classes::{AudioServer, AudioStreamPlayer, INode, Node},
    obj::{Base, Gd, WithBaseField},
    register::{godot_api, GodotClass},
};

use crate::bpm_time::BpmTime;

#[derive(GodotClass)]
#[class(base=Node)]
pub struct Conductor {
    base: Base<Node>,
    #[var]
    sound_object: Option<Gd<AudioStreamPlayer>>,
    #[var]
    bpm: f64,
    #[var]
    offset: f64,
    #[var]
    last_beat_seconds: f64,
    #[var]
    beats_passed: i64,
    #[var]
    post_beat_happened: bool,
    #[var]
    notes: Array<VariantArray>,
    #[var]
    time: Option<Gd<BpmTime>>,
}

#[godot_api]
impl INode for Conductor {
    fn init(base: Base<Node>) -> Self {
        let mut notes = Array::new();
        notes.push(Array::new());
        notes.push(Array::new());
        notes.push(Array::new());
        Self {
            base,
            notes,
            sound_object: None,
            bpm: -1.0,
            offset: -1.0,
            last_beat_seconds: -1.0,
            beats_passed: -1,
            post_beat_happened: false,
            time: None,
        }
    }
}

#[godot_api]
impl Conductor {
    #[func]
    fn process(&mut self) {
        if self.sound_object.is_none() {
            return;
        }

        if self.song_position().bind().get_time_in_seconds()
            > self.last_beat_seconds + self.get_crotchet()
        {
            self.last_beat_seconds += self.get_crotchet();
            self.post_beat_happened = false;
            let beats_passed = self.beats_passed;
            self.base_mut()
                .emit_signal("beat_happened".into(), &[Variant::from(beats_passed)]);
            self.beats_passed += 1;
        }

        if self.song_position().bind().get_time_in_seconds() > self.last_beat_seconds + 0.2
            && !self.post_beat_happened
        {
            self.post_beat_happened = true;
            let beats_passed = self.beats_passed;
            let last_beat_seconds = self.last_beat_seconds;
            self.base_mut().emit_signal(
                "beat_plus_offset_happened".into(),
                &[
                    Variant::from(last_beat_seconds),
                    Variant::from(beats_passed - 1),
                ],
            );
        }
    }

    #[func]
    fn get_crotchet(&self) -> f64 {
        60.0 / self.bpm
    }

    #[func]
    fn song_position(&mut self) -> Gd<BpmTime> {
        let audio_server = AudioServer::singleton();
        let calculated_current_time = self
            .sound_object
            .as_mut()
            .map(|x| {
                audio_server.get_time_since_last_mix()
                    + (x.get_playback_position() as f64)
                    + audio_server.get_output_latency()
            })
            .unwrap_or_default();

        let new_time = match &self.time {
            None => BpmTime::new_from_seconds(self.bpm, calculated_current_time),
            Some(x) => {
                if self.sound_object.as_ref().is_some_and(|x| x.is_playing()) {
                    let current_time = self
                        .time
                        .as_ref()
                        .map(|x| x.bind().get_time_in_seconds())
                        .unwrap_or_default();
                    BpmTime::new_from_seconds(self.bpm, calculated_current_time.max(current_time))
                } else {
                    x.clone()
                }
            }
        };

        self.time = Some(new_time.clone());
        new_time
    }

    #[func]
    pub fn set_audio_object(
        &mut self,
        audio_object: Gd<AudioStreamPlayer>,
        song_bpm: f64,
        song_offset: f64,
    ) {
        self.sound_object = Some(audio_object);
        self.bpm = song_bpm;
        self.last_beat_seconds = 0.0;
        self.beats_passed = 0;
        self.offset = song_offset;
    }

    #[signal]
    fn beat_happened(number: i64);

    #[signal]
    fn beat_plus_offset_happened(number: f64);
}
