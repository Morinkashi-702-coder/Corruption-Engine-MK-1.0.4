package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxAxes;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.text.FlxText.FlxTextAlign;

class SideStoryMenuNotices extends MusicBeatState
{
    var moveTween:FlxTween;
    var textTween:FlxTween;
    var curInfo:Int = 0;
var infoCard:FlxSpriteGroup;
var canSelect:Bool = false;

var camFollow:FlxSprite;
var camFollowPos:FlxSprite;

override function create() {
    super.create();
    persistentUpdate = true;
    persistentDraw = true;

    if (FlxG.sound.music != null)
        FlxG.sound.music.stop();

    FlxG.mouse.visible = false;
    FlxG.camera.bgColor = FlxColor.BLACK;

    camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
    camFollow.alpha = 0;
    camFollow.setPosition(951, 570);

    camFollowPos = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
    camFollowPos.setPosition(951, -270);

    add(camFollow);
    add(camFollowPos);

    FlxG.camera.zoom = 0.593;
    FlxG.camera.follow(camFollowPos, LOCKON, 1);

    nextCard();
}

override function update(elapsed:Float) {
    super.update(elapsed);
    inputShit();
}

function inputShit() {
    if (!canSelect) return;

    if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.Z) {
        canSelect = false;
        FlxG.sound.play(Paths.sound('confirmMenu'));

        if (curInfo == 1) {
            removeCardAndLeave();
        } else {
            removeInfoCard();
        }
    }
}

function createInfoCard(infoText:String, subInfoText:String) {
    if (infoCard != null) remove(infoCard);

    infoCard = new FlxSpriteGroup();
    add(infoCard);

    if (moveTween != null) moveTween.cancel();
    if (textTween != null) textTween.cancel();

    var infoSprite = new FlxSprite(290, -630, Paths.image('infoCard'));
    infoSprite.scrollFactor.set(0, 0);
    infoSprite.scale.set(1, 1);
    infoSprite.alpha = 0.8;
    infoCard.add(infoSprite);

    var mainText = new FlxText(441, -460, 1000, infoText, 16);
    mainText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 48, 0xFFFFFFFF, FlxTextAlign.CENTER);
    infoCard.add(mainText);

    var subText = new FlxText(441, -140, 1000, subInfoText, 16);
    subText.setFormat(Paths.font("VollkornRegular-ZVJEZ.ttf"), 52, 0xCC5363, FlxTextAlign.CENTER);
    subText.alpha = 0;
    infoCard.add(subText);

    infoCard.x = -1610;
    infoCard.alpha = 0;

    moveTween = FlxTween.tween(infoCard, {x: 0, alpha: 1}, 0.2, {ease: FlxEase.sineOut});
    textTween = FlxTween.tween(subText, {alpha: 1}, 1, {ease: FlxEase.sineOut});
}

function removeInfoCard() {
    if (moveTween != null) moveTween.cancel();
    if (textTween != null) textTween.cancel();

    moveTween = FlxTween.tween(infoCard, {x: 1710, alpha: 0}, 0.2, {ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) { nextCard(); }});
}

function nextCard() {
    new FlxTimer().start(1, function(tmr) {
        canSelect = true;
        tmr.destroy();
    });

    switch (curInfo) {
        case 0:
            createInfoCard(
                '\nCorruption: Side Story\nIs written and illustrated by:\nYukizakura1126',
                "I understand. →"
            );
    }

    curInfo++;
}

function removeCardAndLeave() {
    if (moveTween != null) moveTween.cancel();
    if (textTween != null) textTween.cancel();

    moveTween = FlxTween.tween(infoCard, {x: 1710, alpha: 0}, 0.2, {ease: FlxEase.sineOut, onComplete: function(twn:FlxTween) { leaveScene(); }});
}

function leaveScene() {
    if(moveTween != null) moveTween.cancel();
    if(textTween != null) textTween.cancel();

    MusicBeatState.switchState(new SideStoryMenuState());
}
}

