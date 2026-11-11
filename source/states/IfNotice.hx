package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import backend.ClientPrefs;
import backend.Paths;
import backend.MusicBeatState;
import states.MainMenuState;
import states.IfMenu;

/**
 * Estado de aviso para IF
 */
class IfNotice extends MusicBeatState
{
    var moveTween:FlxTween;
    var textTween:FlxTween;
    var curInfo:Int = 0;
    var infoCard:FlxSpriteGroup;
    var canSelect:Bool = false;

    var camFollow:FlxSprite;
    var camFollowPos:FlxSprite;
    
    override function create()
    {
        try {
            // Configuración básica
            Paths.clearStoredMemory();
            if(FlxG.sound.music != null)
                FlxG.sound.music.stop();

            persistentUpdate = true;
            persistentDraw = true;

            // Inicializar super.create() primero (que configura PsychCamera)
            super.create();

            // Configuración de cámara DESPUÉS de super.create() (igual que SideStoryMenuNotices)
            camFollow = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
            camFollow.alpha = 0;
            camFollow.setPosition(951, 570);
            
            camFollowPos = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
            camFollowPos.setPosition(951, -270);
            add(camFollow);
            add(camFollowPos);

            FlxG.camera.zoom = 0.593;
            FlxG.camera.follow(camFollowPos, LOCKON, 1);

            // Configuración visual
            FlxG.mouse.visible = false;
            FlxG.camera.bgColor = FlxColor.BLACK;

            // Iniciar las tarjetas de información
            nextCard();

            #if android // Soporte para Android
            addVirtualPad(NONE, A_B);
            #end
        } catch(e) {
            trace('[ERROR] Error en create de IfNotice: ' + e);
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        #if android // Control de entrada táctil
        if (FlxG.android.justReleased.BACK)
        {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            // Transición de zoom acercándose al salir
            FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.5, {ease: FlxEase.backIn});
            MusicBeatState.switchState(new SoftCodeMenuState());
        }
        #end

        inputCheck();
    }

    function inputCheck()
    {
        if (!canSelect)
            return;

        // Skip con ESC - volver al menú
        if (FlxG.keys.justPressed.ESCAPE)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            leaveScene();
            return;
        }

        var accept = controls.ACCEPT;
        
        if (accept)
        {
            canSelect = false;
            FlxG.sound.play(Paths.sound('confirmMenu'));
            
            if (curInfo == 2)
                removeCardAndLeave();
            else
                removeInfoCard();
        }
    }

    function createInfoCard(infoText:String, subInfoText:String)
    {
        try {
            if (infoCard != null)
            {
                remove(infoCard);
                infoCard.destroy();
            }

            infoCard = new FlxSpriteGroup();
            add(infoCard);
            
            if (moveTween != null)
                moveTween.cancel();
            if (textTween != null)
                textTween.cancel();

            // Fondo de la tarjeta - con validación
            try {
                var infoSprite = new FlxSprite(290, -630);
                var graphic = Paths.image('menus/if/infoCard');
                if (graphic != null) {
                    infoSprite.loadGraphic(graphic);
                    infoSprite.scrollFactor.set();
                    infoSprite.alpha = 0.8;
                    infoCard.add(infoSprite);
                } else {
                    trace('[WARNING] infoCard image no encontrada, usando fondo sólido');
                    infoSprite.makeGraphic(800, 400, FlxColor.BLACK);
                    infoSprite.alpha = 0.8;
                    infoCard.add(infoSprite);
                }
            } catch(e) {
                trace('[ERROR] Error cargando infoCard sprite: ' + e);
                var fallbackSprite = new FlxSprite(290, -630);
                fallbackSprite.makeGraphic(800, 400, FlxColor.BLACK);
                fallbackSprite.alpha = 0.8;
                infoCard.add(fallbackSprite);
            }

            // Texto principal
            try {
                var mainText = new FlxText(441, -460, 1000, infoText, 16);
                var font = Paths.font("VollkornRegular-ZVJEZ.ttf");
                if (font != null) {
                    mainText.setFormat(font, 48, FlxColor.WHITE, CENTER);
                } else {
                    mainText.setFormat(null, 48, FlxColor.WHITE, CENTER);
                }
                mainText.antialiasing = ClientPrefs != null && ClientPrefs.data != null ? ClientPrefs.data.antialiasing : false;
                infoCard.add(mainText);
            } catch(e) {
                trace('[ERROR] Error creando mainText: ' + e);
            }

            // Subtexto
            try {
                var subText = new FlxText(441, -140, 1000, subInfoText, 16);
                var font = Paths.font("VollkornRegular-ZVJEZ.ttf");
                if (font != null) {
                    subText.setFormat(font, 52, 0xCC5363, CENTER);
                } else {
                    subText.setFormat(null, 52, 0xCC5363, CENTER);
                }
                subText.antialiasing = ClientPrefs != null && ClientPrefs.data != null ? ClientPrefs.data.antialiasing : false;
                subText.alpha = 0;
                infoCard.add(subText);
            } catch(e) {
                trace('[ERROR] Error creando subText: ' + e);
            }

            // Posición inicial y animación
            if (infoCard != null) {
                infoCard.x = -1610;
                infoCard.alpha = 0;
                
                if (moveTween != null) moveTween.cancel();
                moveTween = FlxTween.tween(infoCard, {x: 0, alpha: 1}, 0.2, {ease: FlxEase.sineOut});
                
                // Animar subtexto
                var subSprites = infoCard.members;
                if (subSprites != null && subSprites.length > 2) {
                    var subText = subSprites[2];
                    if (subText != null && textTween != null) textTween.cancel();
                    textTween = FlxTween.tween(subText, {alpha: 1}, 1, {ease: FlxEase.sineOut});
                }
            }
        } catch(e) {
            trace('[ERROR] Error general en createInfoCard: ' + e);
        }
    }

    function removeInfoCard()
    {
        try {
            if (moveTween != null)
                moveTween.cancel();
            if (textTween != null)
                textTween.cancel();

            if (infoCard != null) {
                moveTween = FlxTween.tween(infoCard, {x: 1710, alpha: 0}, 0.2, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        nextCard();
                    }
                });
            }
        } catch(e) {
            trace('[ERROR] Error en removeInfoCard: ' + e);
        }
    }

    function nextCard()
    {
        new FlxTimer().start(1, function(tmr:FlxTimer)
        {
            canSelect = true;
        });

        switch (curInfo)
        {
            case 0:
                createInfoCard('Corruption:IF\nacts as non-canonical\n"What if?"\nscenarios for moments in the mod.', "I understand. →");
            case 1:
                createInfoCard("\nCorruption:IF\nis directed by:\nPincerProd", "I understand. →");
        }   

        curInfo++;
    }

    function removeCardAndLeave()
    {
        try {
            if (moveTween != null)
                moveTween.cancel();
            if (textTween != null)
                textTween.cancel();

            if (infoCard != null) {
                moveTween = FlxTween.tween(infoCard, {x: 1710, alpha: 0}, 0.2, {
                    ease: FlxEase.sineOut,
                    onComplete: function(twn:FlxTween) {
                        leaveScene();
                    }
                });
            } else {
                leaveScene();
            }
        } catch(e) {
            trace('[ERROR] Error en removeCardAndLeave: ' + e);
            leaveScene();
        }
    }

    function leaveScene()
    {
        MusicBeatState.switchState(new IfMenu());
    }
}


