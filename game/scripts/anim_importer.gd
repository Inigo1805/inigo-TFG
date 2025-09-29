@tool
extends EditorScript

const BASE_PATH := "res://sprites/animaciones/"
const DEFAULT_FPS := 24  # cambia este valor a la velocidad que quieras

func _run():
	var root := DirAccess.open(BASE_PATH)
	if root == null:
		push_error("No se pudo abrir el directorio: %s" % BASE_PATH)
		return

	for character in root.get_directories():
		var char_path := BASE_PATH + character + "/"
		var char_dir := DirAccess.open(char_path)
		if char_dir == null:
			continue

		var sprite_frames := SpriteFrames.new()

		for anim in char_dir.get_directories():
			var anim_path := char_path + anim + "/"
			var anim_dir := DirAccess.open(anim_path)
			if anim_dir == null:
				continue

			var files := anim_dir.get_files()
			files.sort()

			sprite_frames.add_animation(anim)
			sprite_frames.set_animation_loop(anim, true)
			sprite_frames.set_animation_speed(anim, DEFAULT_FPS)

			for f in files:
				if f.ends_with(".png"):
					var tex := load(anim_path + f)
					if tex:
						sprite_frames.add_frame(anim, tex)

		var save_path := char_path + character + ".tres"
		var err := ResourceSaver.save(sprite_frames, save_path)
		if err == OK:
			print("Generado:", save_path)
		else:
			push_error("Error al guardar: %s" % save_path)
