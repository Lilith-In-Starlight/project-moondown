use godot::{
    builtin::GString,
    classes::{ConfigFile, FileAccess, Object},
    global::{godot_print, Error},
    meta::ToGodot,
    obj::{Base, Gd, NewGd},
    register::{godot_api, GodotClass},
};

use crate::song_data::SongData;

#[derive(GodotClass)]
#[class(init, base=Object)]
pub struct Global {
    base: Base<Object>,
    #[var]
    #[init(val = 300.0)]
    scroll_speed: f64,
    #[var]
    song_data: Option<Gd<SongData>>,
    #[var]
    using_editor: bool,
    #[var]
    #[init(val = ConfigFile::new_gd())]
    game_data: Gd<ConfigFile>,
    #[var]
    #[init(val = "main".to_godot())]
    to_menu: GString,
}

#[godot_api]
impl Global {
    const PASS: &'static str = "asdjfow98fnqHJNPOhwlpfnaopvnQPOIHGVEAGNFQL�jf9iw";

    #[func]
    fn get_perfect_timing() -> f64 {
        0.06
    }

    #[func]
    fn get_inexact_perfect_timing() -> f64 {
        0.1
    }

    #[func]
    fn get_okay_timing() -> f64 {
        0.2
    }

    #[func]
    fn save_data(&mut self) {
        self.game_data
            .save_encrypted_pass("user://heart.soul".into_godot(), Self::PASS.into_godot());
    }

    #[func]
    fn load_data(&mut self) {
        let error = self
            .game_data
            .load_encrypted_pass("user://heart.soul".to_godot(), Self::PASS.into_godot());

        if error != Error::OK {
            godot_print!("Failed to load heart.soul. Writing a new one.");
            self.game_data
                .save_encrypted_pass("user://heart.soul".to_godot(), Self::PASS.into_godot());
        }
    }

    #[func]
    fn get_song_access_hash(song_path: GString) -> GString {
        let level_data = FileAccess::get_sha256(format!("{song_path}/level.txt").to_godot());
        let data_data = FileAccess::get_sha256(format!("{song_path}/data.txt").to_godot());
        let song_data = FileAccess::get_sha256(format!("{song_path}/song.mp3").to_godot());
        format!("{level_data}{data_data}{song_data}").into_godot()
    }
}
