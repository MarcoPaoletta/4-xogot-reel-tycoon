extends SceneTree
## Headless runner for tests/test_structure.gd with desktop Godot 4.7:
##   godot --headless --path . -s res://tools/run_structure_tests.gd
## Exit code 0 when every check passes. The suites under tests/game need the running game
## and are launched with the Xogot `xo` tool as described in docs/PLAYABLE.md.

func _init() -> void:
	# Autoloads (Economy) are registered after _init, so wait one frame.
	await process_frame
	var suite = load("res://tests/test_structure.gd").new()
	var failures: int = 0
	for method in suite.get_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"): continue
		var result = suite.call(method_name)
		var passed: bool = result is bool and result
		if not passed: failures += 1
		print("%s %s %s" % ["PASS" if passed else "FAIL", method_name, "" if passed else str(result)])
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
