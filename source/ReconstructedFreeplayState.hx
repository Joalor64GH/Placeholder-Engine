package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;

/*
 * Mostly copied from MinigamesState.hx
 * @see https://github.com/Joalor64GH/Joalor64-Engine-Rewrite/blob/main/source/meta/state/MinigamesState.hx
 */

class ReconstructedFreeplayState extends MusicBeatState 
{
    private var grpControls:FlxTypedGroup<Alphabet>;

        private var iconArray:Array<HealthIcon> = [];

	var controlStrings:Array<CoolSong> = [
		new CoolSong('bopeebo', 'example description', 'dad'),
		new CoolSong('fresh', 'idk', 'dad'),
		new CoolSong('dad-battle', 'what', 'dad')
	];
	
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var scoreText:FlxText;
	var descTxt:FlxText;

	var bottomPanel:FlxSprite;

	var menuBG:FlxSprite;

    	var curSelected:Int = 0;

    override function create()
	{
		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        	menuBG.antialiasing = ClientPrefs.globalAntialiasing;
        menuBG.color = 0xFFffffff;
		add(menuBG);

        var thisThing:FlxSprite = new FlxSprite();
		thisThing.frames = Paths.getSparrowAtlas('mainmenu/thisidk');
		thisThing.antialiasing = ClientPrefs.globalAntialiasing;
		thisThing.animation.addByPrefix('idle', 'thingidk', 24, false);
		thisThing.animation.play('idle');
		thisThing.updateHitbox();
		add(thisThing);

        	grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlStrings.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, 0, controlStrings[i].name, true, false);
			controlLabel.isMenuItem = true;
            controlLabel.isMenuItemCentered = false;
            controlLabel.itemType = 'Vertical';
			controlLabel.targetY = i;
			grpControls.add(controlLabel);

            		var icon:HealthIcon = new HealthIcon(controlStrings[i].icon);
			icon.sprTracker = controlLabel;
			icon.updateHitbox();
			iconArray.push(icon);
			add(icon);
		}
        
        	var bottomPanel:FlxSprite = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, 0xFF000000);
		bottomPanel.alpha = 0.5;
		add(bottomPanel);

        scoreText = new FlxText(20, FlxG.height - 80, 1000, "", 22);
		scoreText.setFormat("VCR OSD Mono", 26, 0xFFffffff, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
        scoreText.screenCenter(X);
        add(scoreText);

        	descTxt = new FlxText(scoreText.x, scoreText.y - 25, 1000, "", 22);
        	descTxt.screenCenter(X);
		descTxt.scrollFactor.set();
		descTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(descTxt);

        	changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

        lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

        	if (controls.UI_UP_P || controls.UI_DOWN_P)
			changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.BACK) 
        	{
                FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
        	}
            
		if (controls.ACCEPT)
		{
            FlxG.sound.music.volume = 0;
            FlxG.sound.play(Paths.sound('confirmMenu'));
            LoadingState.loadAndSwitchState(new PlayState());
			switch (curSelected)
            		{
				case 0:
					PlayState.SONG = Song.loadFromJson('bopeebo-hard', 'bopeebo');
				case 1:
					PlayState.SONG = Song.loadFromJson('fresh-hard', 'fresh');
                case 2:
					PlayState.SONG = Song.loadFromJson('dad-battle-hard', 'dad-battle');
			}
		}

        if (FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = grpControls.length - 1;
		if (curSelected >= grpControls.length)
			curSelected = 0;

		descTxt.text = controlStrings[curSelected].description;

		var bullShit:Int = 0;

        intendedScore = Highscore.scoreGet(controlStrings[curSelected].name);
		intendedRating = Highscore.ratingGet(controlStrings[curSelected].name);

		for (i in 0...iconArray.length)
			iconArray[i].alpha = 0.6;

		iconArray[curSelected].alpha = 1;

		for (item in grpControls.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}
	}

    private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		bottomPanel.scale.x = FlxG.width - scoreText.x + 6;
		bottomPanel.x = FlxG.width - (bottomPanel.scale.x / 2);
	}
}

class CoolSong
{
	public var name:String;
	public var description:String;
	public var icon:String;

	public function new(Name:String, dsc:String, img:String)
	{
		name = Name;
        	description = dsc;
        	icon = img;
	}
}