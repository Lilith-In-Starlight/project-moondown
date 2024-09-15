use godot::{
    builtin::{Array, Color, Dictionary, GString},
    classes::{INode, Node},
    meta::ToGodot,
    obj::Base,
    register::{godot_api, GodotClass},
};

#[derive(GodotClass)]
#[class(base=Node)]
pub struct SongData {
    base: Base<Node>,
    #[var]
    song_name: GString,
    #[var]
    song_author: GString,
    #[var]
    bpm: f64,
    #[var]
    path: GString,
    #[var]
    styled: bool,
    #[var]
    bg_color: Color,
    #[var]
    color1: Color,
    #[var]
    color2: Color,
    #[var]
    playfield: Color,
    #[var]
    play_lines: Color,
    #[var]
    play_last_line: Color,
    #[var]
    combo_note_color: Color,
    #[var]
    difficulty: i64,
    #[var]
    editable: bool,
}

#[godot_api]
impl INode for SongData {
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            song_name: GString::new(),
            song_author: GString::new(),
            bpm: 100.0,
            path: GString::new(),
            styled: false,
            bg_color: Color::from_html("4a2025").unwrap(),
            color1: Color::from_html("ff7a1b").unwrap(),
            color2: Color::from_html("ff4879").unwrap(),
            playfield: Color::from_html("28100a").unwrap(),
            play_lines: Color::from_html("d91b4e").unwrap(),
            play_last_line: Color::from_html("ffb300").unwrap(),
            combo_note_color: Color::from_html("ffb300").unwrap(),
            difficulty: -1,
            editable: false,
        }
    }
}

#[godot_api]
impl SongData {
    #[func]
    fn set_from_dict(&mut self, data: Dictionary) {
        self.song_name = data.get("title").unwrap().to();
        self.song_author = data.get("author").unwrap().to();
        self.bpm = data.get("bpm").unwrap().to();
        self.difficulty = data.get("difficulty").map(|x| x.to()).unwrap_or(-1);

        if let Some(style) = data.get("style").map(|x| x.to::<Dictionary>()) {
            self.bg_color = data
                .get("bg_color")
                .map(|x| x.to())
                .unwrap_or(self.bg_color);

            if let Some(note_colors) = style.get("note_colors").map(|x| x.to::<Array<Color>>()) {
                self.color1 = note_colors.get(0).unwrap_or(self.color1);
                self.color2 = note_colors.get(0).unwrap_or(self.color2);
            }

            self.combo_note_color = data
                .get("combo_note_color")
                .map(|x| x.to())
                .unwrap_or(self.combo_note_color);

            if let Some(style) = style.get("playfield").map(|x| x.to::<Dictionary>()) {
                self.playfield = style
                    .get("bg_color")
                    .map(|x| x.to())
                    .unwrap_or(self.playfield);

                self.play_lines = style
                    .get("lines")
                    .map(|x| x.to())
                    .unwrap_or(self.play_lines);

                self.play_last_line = style
                    .get("last_line")
                    .map(|x| x.to())
                    .unwrap_or(self.play_last_line);
            }
        }
    }

    #[func]
    fn get_as_dict(&mut self) -> Dictionary {
        let mut data = Dictionary::new();
        let _ = data.insert("title", self.song_name.clone());
        let _ = data.insert("author", self.song_author.clone());
        let _ = data.insert("bpm", self.bpm);
        let _ = data.insert("difficulty", self.difficulty);

        let mut style = Dictionary::new();
        let _ = style.insert("bg_color", self.bg_color.to_html_without_alpha());
        let _ = style.insert("note_colors", Array::from(&[self.color1, self.color2]));
        let _ = style.insert(
            "combo_note_color",
            self.combo_note_color.to_html_without_alpha(),
        );

        let _ = style.insert("playfield", {
            let mut playfield = Dictionary::new();
            let _ = playfield.insert("bg_color", self.playfield.to_html_without_alpha());
            let _ = playfield.insert("lines", self.play_lines.to_html_without_alpha());
            let _ = playfield.insert("last_line", self.play_last_line.to_html_without_alpha());
            playfield
        });

        let _ = data.insert("style", style);
        data
    }

    #[func]
    fn get_difficulty_name(d: i64) -> GString {
        if d == -1 {
            "Unset!".into_godot()
        } else {
            let mut ret = String::new();
            for _ in 0..(d + 1) {
                ret.push_str("?!");
            }
            ret.into_godot()
        }
    }
}
