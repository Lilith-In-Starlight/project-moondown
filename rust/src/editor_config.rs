use godot::{builtin::GString, global::Key};

enum Expectations {
    Integer,
    Number,
    Clipboard,
}

struct RealKeybinds {
    expectations: Expectations,
    key: Key,
}

struct Keybinds {
    expectations: Expectations,
    key: GString,
}
