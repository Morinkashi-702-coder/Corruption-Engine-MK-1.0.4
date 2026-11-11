package states.editors.content;

import backend.ui.PsychUIButton;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import openfl.utils.Assets;

/**
 * Adapts the original Funkin chart editor XML to Psych's controls.
 */
class VSlicePlaybar extends FlxSpriteGroup
{
	public static inline final HEIGHT = 48;
	public static inline final MENU_HEIGHT = 28;
	static inline final ROOT = 'assets/data/editors/vslice/';

	final labels:Map<String, FlxText> = [];
	var playButton:PsychUIButton;

	public static function readLayout(file:String):Xml
	{
		return Xml.parse(Assets.getText(ROOT + file + '.xml')).firstElement();
	}

	public function new(camera:FlxCamera, actions:Map<String, Void->Void>)
	{
		super(0, FlxG.height - HEIGHT);
		scrollFactor.set();
		cameras = [camera];
		add(new FlxSprite().makeGraphic(FlxG.width, HEIGHT, 0xFF28292E));

		var positions = [
			'playbarSongPos' => 16, 'playbarBeatNum' => 102, 'playbarStepNum' => 210,
			'playbarDifficulty' => FlxG.width - 348, 'playbarBPM' => FlxG.width - 242,
			'playbarNoteSnap' => FlxG.width - 145, 'playbarSongRemaining' => FlxG.width - 76
		];

		var buttonX = Math.round(FlxG.width / 2 - 144);
		for (row in readLayout('playbar').elementsNamed('hbox'))
			for (control in row.elements())
			{
				var id = control.get('id');
				if (id == null) continue;
				if (control.nodeName == 'button' && actions.exists(id))
				{
					var button = new PsychUIButton(buttonX, 10, control.get('text'), actions[id], 52, 28);
					button.normalStyle.bgColor = 0xFF44464F;
					button.normalStyle.textColor = 0xFFF1F1F4;
					add(button);
					if (id == 'playbarPlay') playButton = button;
					buttonX += 59;
				}
				else if (control.nodeName == 'label' && positions.exists(id))
				{
					var label = new FlxText(positions[id], 14, 0, '', 15);
					label.color = 0xFFF1F1F4;
					labels[id] = label;
					add(label);
				}
			}
	}

	public function setReadout(id:String, text:String):Void
	{
		var label = labels[id];
		if (label != null) label.text = text;
	}

	public function setPlaying(playing:Bool):Void
	{
		var label = playing ? '||' : '>';
		if (playButton != null && playButton.label != label) playButton.label = label;
	}
}
