extends SceneTree
## Parse every active scene and script, including props missed by gameplay checks.
var checked := 0
var failures: Array[String] = []

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    scan("res://scenes")
    scan("res://scripts")
    print("Runtime resources: ", checked, " checked; ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)

func scan(folder: String) -> void:
    for directory in DirAccess.get_directories_at(folder):
        scan(folder.path_join(directory))
    for filename in DirAccess.get_files_at(folder):
        if filename.get_extension() not in ["tscn", "gd"]:
            continue
        var path := folder.path_join(filename)
        var resource := load(path)
        checked += 1
        if resource == null or (resource is GDScript and not resource.can_instantiate()):
            failures.append(path)
            push_error("Cannot load " + path)
