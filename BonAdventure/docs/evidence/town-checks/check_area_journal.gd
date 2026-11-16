extends SceneTree
## Writes only isolated fixture saves. Refuses to run in a learner profile.
const Progress = preload("res://scripts/learning/vocabulary_progress.gd")
var checks := 0
var failures := 0
var previous: Dictionary = {}
func _initialize(): run.call_deferred()
func check(ok: bool, message: String):
    checks += 1
    if not ok:
        failures += 1
        print("FAIL: ",message)
func write_fixture(path: String, value: Variant):
    previous[path] = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else null
    var file := FileAccess.open(path,FileAccess.WRITE)
    file.store_string(JSON.stringify(value))
func fixture(town: Node3D, title: String, point: Vector3, key: String) -> Node3D:
    var object := Node3D.new()
    object.name = title
    object.position = point
    object.set_meta("word_key",key)
    town.add_child(object)
    var body := StaticBody3D.new()
    object.add_child(body)
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.shape.size = Vector3.ONE*0.01
    body.add_child(shape)
    return object
func run():
    if not OS.get_user_data_dir().ends_with("VocabularyTownChecks/journal-20261028"):
        push_error("Use an isolated test copy with custom_user_dir_name=VocabularyTownChecks/journal-20261028")
        quit(1)
        return
    write_fixture(Progress.PROGRESS_FILE,["sofa","tap"])
    var game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.player.set_physics_process(false)
    game.interaction.set_physics_process(false)
    var index=game.area_vocabulary
    check(game.studied_words.has("sofa") and game.studied_words.has("faucet") and not game.studied_words.has("tap"),"old progress and aliases load")
    check(index.unknown_keys.is_empty(),"all actual picking targets have canonical keys")
    check(index.groups.size()==25,"all approved zones represented")
    var total := 0
    for area in index.groups:
        var unique: Dictionary={}
        for key in index.groups[area]: unique[key]=true
        check(unique.size()==index.groups[area].size(),"unique area entries "+area)
        total += index.groups[area].size()
    var sofa_zones: Dictionary={}
    for target in index.assignments:
        var a: Dictionary=index.assignments[target]
        if a.key=="sofa": sofa_zones[a.zone]=true
        if "Buildings/Hospital/" in str(target.get_path()): check(a.zone=="hospital","hospital target "+str(target.name))
    for area in ["home","hospital","furniture"]:
        check(sofa_zones.has(area),"actual sofa in "+area)
        check(index.discovered_count(area,{"sofa":true})==1,"one shared sofa discovery in "+area)
    check(game.vocabulary_categories.sofa=="Furniture","sofa type independent of area")
    var car=game.apartment.get_node("Vehicles/Car")
    var original: Vector3=car.global_position
    car.global_position=game.apartment.to_global(Vector3(-78,0,105))
    check(game.zones.resolve_global(car.global_position)=="zoo","vehicle physically enters another area")
    check(index.zone_for(car)=="home" and car.get_meta("assigned_zone")=="home","moving vehicle keeps home area")
    check(index.groups.home.has("car") and not index.groups.zoo.has("car"),"vehicle does not move area vocabulary")
    car.global_position=original
    var before_progress := FileAccess.get_file_as_string(Progress.PROGRESS_FILE)
    game.toggle_study_journal()
    check(game.hud.is_journal_open() and not game.player.controls_enabled,"journal blocks gameplay")
    game.hud.journal_area_button.pressed.emit()
    check(game.hud.journal_by_area and game.hud.journal_list.text.contains("Shared words")==false,"area button switches view")
    check(game.hud.journal_hint.text.contains("Shared words count as discovered in every area"),"shared discovery explanation")
    check(game.hud.journal_list.text.contains("el sofá") and game.hud.journal_list.text.contains("discovered"),"Spanish first and area counts")
    check(game.hud.journal_list.text.find("Airport") < game.hud.journal_list.text.find("Bank"),"area names alphabetized")
    game.hud.journal_category_button.pressed.emit()
    check(not game.hud.journal_by_area and game.hud.journal_list.text.contains("Furniture"),"category switch")
    check(before_progress==FileAccess.get_file_as_string(Progress.PROGRESS_FILE),"journal views never write save state")
    # Exercise English-display sorting independently of canonical-key spelling/case.
    game.hud.journal_studied = {"zebra":true,"MRI scanner":true,"apple_tree":true}
    game.hud.journal_dictionary = {"zebra":"la cebra","MRI scanner":"el escáner","apple_tree":"el manzano","hidden":"oculto"}
    game.hud.journal_categories = {"zebra":"Test","MRI scanner":"Test","apple_tree":"Test","hidden":"Test"}
    game.hud.render_journal()
    var rendered: String = game.hud.journal_list.get_parsed_text()
    check(rendered.find("Apple Tree") < rendered.find("Mri Scanner") and rendered.find("Mri Scanner") < rendered.find("Zebra"),"sort by displayed English name")
    check(rendered.find("el manzano") < rendered.find("Apple Tree") and not rendered.contains("oculto"),"Spanish first; undiscovered entries stay hidden")
    game.toggle_study_journal()
    check(game.player.controls_enabled,"closing journal restores controls")
    check(Progress.load_studied_words(game.vocabulary,game.vocabulary_aliases)==game.studied_words,"save roundtrip")
    # Tiny fixtures exercise both sides of a real fence and a documented metadata override.
    var inside=fixture(game.apartment,"ZoneFixtureInside",Vector3(42.02,0,95),"sofa")
    var outside=fixture(game.apartment,"ZoneFixtureOutside",Vector3(41.98,0,95),"sofa")
    var override=fixture(game.apartment,"ZoneFixtureOverride",Vector3(41.98,0,95),"tap")
    override.set_meta("zone_override","farm")
    var decorative := Node3D.new()
    decorative.set_meta("word_key","sofa")
    game.apartment.add_child(decorative)
    index.build(game.apartment,game.zones,game.vocabulary,game.vocabulary_aliases)
    check(index.zone_for(inside)=="farm" and index.zone_for(outside)=="central_park","objects either side of fence")
    check(index.zone_for(override)=="farm" and index.assignments[override].key=="faucet","explicit override and canonical alias")
    check(not index.assignments.has(decorative),"metadata without picking geometry does not create area vocabulary")
    decorative.free()
    inside.free()
    outside.free()
    override.free()
    for path in previous:
        if previous[path]==null: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        else:
            var file=FileAccess.open(path,FileAccess.WRITE)
            file.store_string(previous[path])
    print("AREA JOURNAL: ",checks," checks; ",failures," failures; ",total," area-word memberships")
    quit(1 if failures else 0)
