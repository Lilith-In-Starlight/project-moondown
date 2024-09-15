use std::str::FromStr;

use godot::{
    builtin::{Dictionary, GString, Vector2},
    classes::RefCounted,
    obj::{Base, Gd},
    register::{godot_api, GodotClass},
};

#[derive(GodotClass)]
#[class(init, base=RefCounted)]
pub struct NoteData {
    base: Base<RefCounted>,
    #[var]
    start_beat_number: f64,
    #[var]
    end_beat_number: f64,
    #[var]
    lane: i8,
}

#[godot_api]
impl NoteData {
    #[func]
    pub fn get_type() -> GString {
        GString::from_str("note").unwrap()
    }

    #[func]
    pub fn is_sustain(&self) -> bool {
        self.end_beat_number > self.start_beat_number
    }

    #[func]
    pub fn get_duration_beats(&self) -> f64 {
        if self.is_sustain() {
            self.end_beat_number - self.start_beat_number
        } else {
            0.0
        }
    }

    #[func]
    pub fn get_as_dict(&self) -> Dictionary {
        let mut dict = Dictionary::new();
        let _ = dict.insert("type", Self::get_type());
        let _ = dict.insert("start", self.start_beat_number);
        let _ = dict.insert("lane", self.lane);
        if self.is_sustain() {
            let _ = dict.insert("end", self.end_beat_number);
        }
        dict
    }

    #[func]
    pub fn duplicate(&self) -> Gd<Self> {
        Gd::from_init_fn(|base| Self {
            base,
            start_beat_number: self.start_beat_number,
            end_beat_number: self.end_beat_number,
            lane: self.lane,
        })
    }

    #[func]
    pub fn from_dict(dict: Dictionary) -> Gd<Self> {
        let start_beat_number = dict.get("start").expect("start").to::<f32>() as f64;
        let end_beat_number = if dict.contains_key("end") {
            dict.get("end").expect("end").to::<f32>() as f64
        } else {
            -1.0
        };
        let lane = dict.get("lane").expect("lane").to::<f64>() as i8;
        Gd::from_init_fn(|base| Self {
            base,
            start_beat_number,
            end_beat_number,
            lane,
        })
    }

    #[func]
    pub fn get_vector(&self) -> Vector2 {
        Vector2::new(self.lane as f32, self.start_beat_number as f32)
    }
}
