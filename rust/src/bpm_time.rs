use godot::{
    classes::RefCounted,
    obj::{Base, Gd},
    register::{godot_api, GodotClass},
};

#[derive(GodotClass)]
#[class(init, base=RefCounted)]
pub struct BpmTime {
    base: Base<RefCounted>,
    amount: f64,
    bpm: f64,
}

#[godot_api]
impl BpmTime {
    #[func]
    pub fn new_from_seconds(bpm: f64, seconds: f64) -> Gd<Self> {
        let amount = seconds * (bpm / 60.0);
        Gd::from_init_fn(|base| Self { base, amount, bpm })
    }

    #[func]
    pub fn get_time_in_seconds(&self) -> f64 {
        (60.0 / self.bpm) * self.amount
    }

    #[func]
    pub fn get_time_in_minutes(&self) -> f64 {
        self.bpm * self.amount
    }

    #[func]
    pub fn get_time_in_beats(&self) -> f64 {
        self.amount
    }

    #[func]
    pub fn is_greater_than(&self, other: Gd<BpmTime>) -> bool {
        self.get_time_in_seconds() > other.bind().get_time_in_seconds()
    }

    #[func]
    pub fn is_equal_to(&self, other: Gd<BpmTime>) -> bool {
        self.get_time_in_seconds() == other.bind().get_time_in_seconds()
    }

    #[func]
    pub fn is_lesser_than(&self, other: Gd<BpmTime>) -> bool {
        self.get_time_in_seconds() < other.bind().get_time_in_seconds()
    }
}

impl PartialEq for BpmTime {
    fn eq(&self, other: &Self) -> bool {
        if self.bpm == other.bpm {
            self.amount == other.amount
        } else {
            false
        }
    }
}

impl PartialOrd for BpmTime {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        if self.bpm == other.bpm {
            self.bpm.partial_cmp(&other.bpm)
        } else {
            None
        }
    }
}
