extends RefCounted

# Studied words are kept per foreign language (UI Stage 3, user decision 4 Nov 2026):
# LANGUAGE_FILE holds {"es": [keys], ...}. The older single array (PROGRESS_FILE, and the
# v0.20 location) is the Spanish progress: it is copied into LANGUAGE_FILE once and is
# never written again, so it stays as a backup. Bookmarks stay one shared list (below).
# The files live in the active profile's folder (save_store.gd). LANGUAGE_FILE, PROGRESS_FILE
# and BOOKMARKS_FILE are where they are without a profile (what checks read and write).
const SaveStore := preload("res://scripts/core/save_store.gd")
const LANGUAGE_FILE := "user://vocabulary_progress_by_language.json"
const PROGRESS_FILE := "user://vocabulary_apartment_progress.json"
const LEGACY_LANGUAGE := "es"

static func normalize_studied_words(words: Array, valid_vocabulary: Dictionary = {}, aliases: Dictionary = {}) -> Dictionary:
    var result: Dictionary = {}
    for key in words:
        var canonical: String = str(aliases.get(str(key), str(key)))
        if valid_vocabulary.is_empty() or valid_vocabulary.has(canonical):
            result[canonical] = true
    return result

static func _read_languages() -> Dictionary:
    var parsed: Variant = SaveStore.read_json(SaveStore.path(LANGUAGE_FILE.get_file()))
    return parsed if parsed is Dictionary else {}

## The older single-array save (Spanish), or null when there is none.
static func _read_legacy() -> Variant:
    # Godot scopes user:// by project name. Also check the original v0.20
    # location so existing learners retain their progress when upgrading.
    var candidates: Array[String] = [SaveStore.path(PROGRESS_FILE.get_file())]
    var prior_data_dir: String = OS.get_user_data_dir().get_base_dir()
    candidates.append(prior_data_dir.path_join("Vocabulary Town v0.20 - Softer Shapes").path_join("vocabulary_apartment_progress.json"))
    for source_path in candidates:
        if not FileAccess.file_exists(source_path):
            continue
        var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
        if parsed is Array:
            return parsed
    return null

## Words studied in the foreign language `language`.
static func load_studied_words(valid_vocabulary: Dictionary = {}, aliases: Dictionary = {}, language: String = LEGACY_LANGUAGE) -> Dictionary:
    var saved: Dictionary = _read_languages()
    if saved.get(language) is Array:
        var studied: Dictionary = normalize_studied_words(saved[language], valid_vocabulary, aliases)
        # Persist canonical vocabulary keys, including aliases in older saves.
        if studied.keys() != saved[language]:
            save_studied_words(studied, valid_vocabulary, aliases, language)
        return studied
    if language == LEGACY_LANGUAGE:
        var legacy: Variant = _read_legacy()
        if legacy is Array:
            var studied: Dictionary = normalize_studied_words(legacy, valid_vocabulary, aliases)
            save_studied_words(studied, valid_vocabulary, aliases, language)
            return studied
    return {}

static func save_studied_words(studied_words: Dictionary, valid_vocabulary: Dictionary = {}, aliases: Dictionary = {}, language: String = LEGACY_LANGUAGE) -> void:
    var saved: Dictionary = _read_languages()
    saved[language] = normalize_studied_words(studied_words.keys(), valid_vocabulary, aliases).keys()
    SaveStore.write_json(SaveStore.path(LANGUAGE_FILE.get_file()), saved)

# Bookmarked ("saved") words live beside the progress file in their own JSON
# array of canonical word keys, so the progress array format above is unchanged
# and saves from before bookmarks existed simply load with no bookmarks.
const BOOKMARKS_FILE := "user://vocabulary_town_bookmarks.json"

static func load_bookmarked_words(valid_vocabulary: Dictionary = {}, aliases: Dictionary = {}) -> Dictionary:
    var parsed: Variant = SaveStore.read_json(SaveStore.path(BOOKMARKS_FILE.get_file()))
    if not parsed is Array:
        return {}
    return normalize_studied_words(parsed, valid_vocabulary, aliases)

static func save_bookmarked_words(bookmarks: Dictionary, valid_vocabulary: Dictionary = {}, aliases: Dictionary = {}) -> void:
    var keys: Array = normalize_studied_words(bookmarks.keys(), valid_vocabulary, aliases).keys()
    SaveStore.write_json(SaveStore.path(BOOKMARKS_FILE.get_file()), keys)
