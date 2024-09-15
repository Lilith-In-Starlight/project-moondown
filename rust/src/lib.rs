mod bpm_time;
mod conductor;
mod global;
mod note;
mod note_data;
mod song_data;
use global::Global;
use godot::{
    builtin::StringName,
    classes::Engine,
    init::{gdextension, ExtensionLibrary, InitLevel},
    obj::NewAlloc,
};

struct Moondown;

#[gdextension]
unsafe impl ExtensionLibrary for Moondown {
    fn on_level_init(level: InitLevel) {
        if level == InitLevel::Scene {
            Engine::singleton().register_singleton("Global".into(), Global::new_alloc())
        }
    }

    fn on_level_deinit(level: InitLevel) {
        if level == InitLevel::Scene {
            let mut engine = Engine::singleton();
            let singleton_name: StringName = "Global".into();

            let singleton = engine
                .get_singleton(singleton_name.clone())
                .expect("Couldn't retrieve Global singleton");

            engine.unregister_singleton(singleton_name);
            singleton.free()
        }
    }
}
