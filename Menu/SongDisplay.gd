extends CenterContainer


func set_song_data(sd:SongData)->void :
	$SongDisplay / NameLabel.text = sd.song_name
	$SongDisplay / SubData / AuthorLabel.text = sd.song_author
	$SongDisplay / SubData / BPMLabel.text = "%s BPM" % sd.bpm
	$SongDisplay / TextureRect / EditableLabel.visible = not sd.editable
	$SongDisplay / SubData / DifficultyLabel.text = SongData.get_difficulty_name(sd.difficulty)


func set_play_data(pd)->void :
	if pd.is_empty():
		$SongDisplay / HighscoreLabel.text = "Unplayed!"
		return 
	$SongDisplay / HighscoreLabel.text = "%s | x%s" % [pd.score, pd.combo]
	
