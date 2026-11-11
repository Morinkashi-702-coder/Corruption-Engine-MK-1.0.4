package options;

import objects.Character;
import objects.Note;
import flixel.graphics.frames.FlxAtlasFrames;

/** Isolated fixtures: no PlayState notes, charts, events or global RGB shader state. */
class GraphicsBenchmarkScene extends FlxTypedGroup<FlxSprite>
{
	public var representative:Bool = true;
	var characters:Array<Character> = [];
	var receptors:Array<FlxSprite> = [];
	var notes:Array<FlxSprite> = [];
	var particles:Array<FlxSprite> = [];
	var layers:Array<FlxSprite> = [];
	var lastBeat:Int = -1;

	public function new()
	{
		super();
		for (i in 0...2)
		{
			try
			{
				var character = new Character(0, 0, i == 0 ? 'bf' : 'dad', i == 0);
				if (character.missingCharacter || character.frames == null || character.width <= 0) { character.destroy(); representative = false; continue; }
				var ratio = Math.min(280 / character.width, 260 / character.height);
				character.scale.set(character.scale.x * ratio, character.scale.y * ratio);
				character.updateHitbox();
				character.setPosition(i == 0 ? FlxG.width - 340 : 65, 510 - character.height);
				characters.push(character);
				add(character);
			}
			catch (_:Dynamic) { representative = false; }
		}
		var atlas:FlxAtlasFrames = null;
		try { atlas = Paths.getSparrowAtlas(Note.defaultNoteSkin); } catch (_:Dynamic) {}
		if (atlas == null || atlas.frames.length == 0) representative = false;
		for (i in 0...8)
		{
			var receptor = makeNote(atlas, i % 4, false, true);
			receptor.setPosition(FlxG.width / 2 - 280 + i * 75, 225);
			receptors.push(receptor);
			add(receptor);
		}
		for (i in 0...48)
		{
			var note = makeNote(atlas, i % 4, i % 3 == 0, false);
			notes.push(note);
			add(note);
		}
		for (i in 0...160)
		{
			var particle = new FlxSprite().makeGraphic(16, 16, FlxColor.WHITE);
			particle.color = i % 2 == 0 ? 0xFFCC5363 : 0xFF6898C9;
			particle.alpha = 0.2;
			particles.push(particle);
			add(particle);
		}
		for (i in 0...2)
		{
			var layer = new FlxSprite(0, 210).makeGraphic(2, 2, 0xFF405C79);
			layer.setGraphicSize(FlxG.width, 330);
			layer.updateHitbox();
			layer.alpha = 0.08;
			layers.push(layer);
			add(layer);
		}
	}

	function makeNote(atlas:FlxAtlasFrames, direction:Int, sustain:Bool, receptor:Bool):FlxSprite
	{
		var sprite = new FlxSprite();
		if (atlas != null)
		{
			sprite.frames = atlas;
			var colors = ['purple', 'blue', 'green', 'red'];
			var arrows = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];
			var prefix = receptor ? arrows[direction] : colors[direction] + (sustain ? ' hold piece' : '0');
			sprite.animation.addByPrefix('preview', prefix, 24, true);
			if (sprite.animation.exists('preview')) sprite.animation.play('preview');
			else representative = false;
		}
		else sprite.makeGraphic(40, 40, FlxColor.WHITE);
		if (sprite.width > 0)
		{
			sprite.setGraphicSize(sustain ? 24 : 42, sustain ? 100 : 42);
			sprite.updateHitbox();
		}
		return sprite;
	}

	public function configure(lowQuality:Bool, antialiasing:Bool):Void
	{
		for (sprite in members) sprite.antialiasing = antialiasing;
		for (i in 0...particles.length) particles[i].visible = !lowQuality || i < 32;
		for (layer in layers) layer.visible = !lowQuality;
	}

	public function animate(time:Float):Void
	{
		var beat = Std.int(time * 2);
		if (beat != lastBeat)
		{
			lastBeat = beat;
			for (character in characters) character.dance();
		}
		for (i in 0...notes.length)
		{
			var note = notes[i];
			note.x = FlxG.width / 2 - 280 + (i % 8) * 75;
			note.y = 520 - ((time * 240 + Std.int(i / 8) * 47) % 290);
		}
		for (i in 0...particles.length)
		{
			var sprite = particles[i];
			sprite.x = (i * 71 + time * (40 + i % 9 * 12)) % (FlxG.width - 30);
			sprite.y = 220 + (i * 37 + time * 45) % 290;
			sprite.angle = time * 35 + i * 17;
		}
	}
}
