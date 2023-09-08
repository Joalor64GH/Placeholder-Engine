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

	public var controlStrings:Array<CoolSong> = [
		new CoolSong('Tutorial', 'tutorial', 'woah', 'gf'),
		new CoolSong('Bopeebo', 'bopeebo', 'example description', 'dad'),
		new CoolSong('Fresh', 'fresh', 'idk', 'dad'),
		new CoolSong('Dad-battle', 'dad-battle', 'what', 'dad')
	];
	
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	var scoreText:FlxText;
	var descTxt:FlxText;

	var bottomPanel:FlxSprite;

    	var curSelected:Int = 0;

    	override function create()
	{
		controlStrings.push(new CoolSong('test', 'test', 'omg real??', 'bf-pixel')); // test function

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
        	menuBG.antialiasing = ClientPrefs.globalAntialiasing;
		add(menuBG);

        	var slash:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/slash'));
		slash.antialiasing = ClientPrefs.globalAntialiasing;
		slash.screenCenter();
		add(slash);

        	grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlStrings.length)
		{
			var controlLabel:Alphabet = new Alphabet(0, (70 * i) + 30, controlStrings[i].name, true, false);
			controlLabel.isMenuItem = true;
			controlLabel.targetY = i;
			grpControls.add(controlLabel);

            		var icon:HealthIcon = new HealthIcon(controlStrings[i].icon);
			icon.sprTracker = controlLabel;
			icon.updateHitbox();
			iconArray.push(icon);
			add(icon);
		}
        
        	bottomPanel = new FlxSprite(0, FlxG.height - 100).makeGraphic(FlxG.width, 100, 0xFF000000);
		bottomPanel.alpha = 0.5;
		add(bottomPanel);

        	scoreText = new FlxText(20, FlxG.height - 80, 1000, "", 22);
		scoreText.setFormat("VCR OSD Mono", 30, 0xFFffffff, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
        	scoreText.screenCenter(X);
        	add(scoreText);

        	descTxt = new FlxText(scoreText.x, scoreText.y + 32, 1000, "", 22);
        	descTxt.screenCenter(X);
		descTxt.scrollFactor.set();
		descTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(descTxt);

		if(curSelected >= controlStrings.length) 
			curSelected = 0;

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
		
		if(ratingSplit.length < 2)
			ratingSplit.push('');
		while(ratingSplit[1].length < 2)
			ratingSplit[1] += '0';

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';

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
			PlayState.SONG = Song.loadFromJson(controlStrings[curSelected].name.toLowerCase(), controlStrings[curSelected].directory);
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

        	intendedScore = Highscore.getScore(controlStrings[curSelected].name);
		intendedRating = Highscore.getRating(controlStrings[curSelected].name);

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
}

class CoolSong
{
	public var name:String;
	public var directory:String;
	public var description:String;
	public var icon:String;

	public function new(Name:String, folder:String, dsc:String, img:String)
	{
		name = Name;
		directory = folder;
        	description = dsc;
        	icon = img;
	}
}