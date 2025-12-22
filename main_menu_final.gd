# MainMenu.gd
extends Control

# References to UI elements
@onready var main_panel = $MainPanel
@onready var settings_panel = $SettingsPanel
@onready var video_settings = $SettingsPanel/VideoSettings
@onready var audio_settings = $SettingsPanel/AudioSettings
@onready var controls_info = $SettingsPanel/ControlsInfo
@onready var about_info = $SettingsPanel/AboutInfo

# Audio settings values
var master_volume = 0.8
var music_volume = 0.7
var sfx_volume = 0.8

# Video settings values
var fullscreen = false
var vsync = true
var resolution_index = 0
var resolutions = ["1920x1080", "1280x720", "1024x768"]

func _ready():
	# Setup initial state
	main_panel.show()
	settings_panel.hide()
	
	# Connect button signals
	connect_main_menu_buttons()
	connect_settings_buttons()
	
	# Apply horror theme styling
	apply_horror_theme()

func connect_main_menu_buttons():
	$MainPanel/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MainPanel/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$MainPanel/SettingsButton.pressed.connect(_on_settings_pressed)
	$MainPanel/QuitButton.pressed.connect(_on_quit_pressed)

func connect_settings_buttons():
	$SettingsPanel/BackButton.pressed.connect(_on_back_to_main_pressed)
	$SettingsPanel/VideoButton.pressed.connect(_on_video_tab_pressed)
	$SettingsPanel/AudioButton.pressed.connect(_on_audio_tab_pressed)
	$SettingsPanel/ControlsButton.pressed.connect(_on_controls_tab_pressed)
	$SettingsPanel/AboutButton.pressed.connect(_on_about_tab_pressed)

# Main Menu Button Handlers
func _on_new_game_pressed():
	print("Starting new game...")
	# Add your scene transition here
	# get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_game_pressed():
	print("Loading game...")
	# Add your load game logic here
	# load_game()

func _on_settings_pressed():
	main_panel.hide()
	settings_panel.show()
	# Show video settings by default
	show_video_settings()

func _on_quit_pressed():
	get_tree().quit()

# Settings Navigation
func _on_back_to_main_pressed():
	settings_panel.hide()
	main_panel.show()

func _on_video_tab_pressed():
	show_video_settings()

func _on_audio_tab_pressed():
	show_audio_settings()

func _on_controls_tab_pressed():
	show_controls_info()

func _on_about_tab_pressed():
	show_about_info()

# Settings Display Functions
func show_video_settings():
	video_settings.show()
	audio_settings.hide()
	controls_info.hide()
	about_info.hide()

func show_audio_settings():
	video_settings.hide()
	audio_settings.show()
	controls_info.hide()
	about_info.hide()

func show_controls_info():
	video_settings.hide()
	audio_settings.hide()
	controls_info.show()
	about_info.hide()

func show_about_info():
	video_settings.hide()
	audio_settings.hide()
	controls_info.hide()
	about_info.show()

# Horror Theme Styling
func apply_horror_theme():
	# You can customize these colors to match your horror aesthetic
	var bg_color = Color(0.05, 0.05, 0.08, 0.95)  # Dark background
	var text_color = Color(0.9, 0.85, 0.8, 1.0)    # Off-white text
	var accent_color = Color(0.6, 0.1, 0.1, 1.0)   # Blood red accent
	
	# Apply theme to panels
	if main_panel.has_theme_stylebox_override("panel"):
		var style = main_panel.get_theme_stylebox("panel").duplicate()
		style.bg_color = bg_color

# Audio Settings Handlers
func _on_master_volume_changed(value):
	master_volume = value / 100.0
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func _on_music_volume_changed(value):
	music_volume = value / 100.0
	# Set music bus volume
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))

func _on_sfx_volume_changed(value):
	sfx_volume = value / 100.0
	# Set SFX bus volume
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))

# Video Settings Handlers
func _on_fullscreen_toggled(button_pressed):
	fullscreen = button_pressed
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(button_pressed):
	vsync = button_pressed
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_resolution_changed(index):
	resolution_index = index
	var res = resolutions[index].split("x")
	var width = int(res[0])
	var height = int(res[1])
	DisplayServer.window_set_size(Vector2i(width, height))
	# Center window
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - window_size) / 2)

# Save/Load Settings (optional but recommended)
func save_settings():
	var config = ConfigFile.new()
	
	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	
	# Video
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "vsync", vsync)
	config.set_value("video", "resolution_index", resolution_index)
	
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		return
	
	# Audio
	master_volume = config.get_value("audio", "master_volume", 0.8)
	music_volume = config.get_value("audio", "music_volume", 0.7)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
	
	# Video
	fullscreen = config.get_value("video", "fullscreen", false)
	vsync = config.get_value("video", "vsync", true)
	resolution_index = config.get_value("video", "resolution_index", 0)
	
	# Apply loaded settings
	apply_loaded_settings()

func apply_loaded_settings():
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	_on_fullscreen_toggled(fullscreen)
	_on_vsync_toggled(vsync)
	_on_resolution_changed(resolution_index)
