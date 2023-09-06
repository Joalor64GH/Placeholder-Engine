package;

#if desktop
import Discord.DiscordClient;
#end
import ui.MenuItem;
import ui.MenuTypedList;
import ui.AtlasMenuItem;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var placeholderVersion:String = '0.0.1'; //This is used for Discord RPC
	public static var psychEngineVersion:String = '0.5.2h';

	public static var menuItems:MainMenuList;

	public static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (menuItems.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new MainMenuList();
		add(menuItems);
		menuItems.onChange.add(onMenuItemChange);
		menuItems.onAcceptPress.add(function(item:MenuItem)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		});
		menuItems.createItem(null, null, "story_mode", function()
		{
			startExitState(new StoryMenuState());
		});
		menuItems.createItem(null, null, "freeplay", function()
		{
			startExitState(new FreeplayState());
		});
		#if MODS_ALLOWED
		menuItems.createItem(null, null, "mods", function()
		{
			startExitState(new ModsMenuState());
		});
		#end
		#if ACHIEVEMENTS_ALLOWED
		menuItems.createItem(null, null, "awards", function()
		{
			startExitState(new AchievementsMenuState());
		});
		#end
		menuItems.createItem(null, null, "credits", function()
		{
			startExitState(new CreditsState());
		});
		#if !switch
		menuItems.createItem(null, null, "donate", function()
		{
			CoolUtil.browserLoad('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game');
		}, true);
		#end
		menuItems.createItem(0, 0, "options", function()
		{
			startExitState(new options.OptionsState());
		});

		var pos:Float = (FlxG.height - 160 * (menuItems.length - 1)) / 2;
		for (i in 0...menuItems.length)
		{
			var item:MainMenuItem = menuItems.members[i];
			item.x = FlxG.width / 2;
			item.y = pos + (160 * i);
			item.antialiasing = ClientPrefs.globalAntialiasing;
			item.updateHitbox();
		}

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Placeholder Engine v" + placeholderVersion + " (PE v" + psychEngineVersion + ")", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	function onMenuItemChange(item:MenuItem)
	{
		FlxG.camera.follow(camFollowPos, null, 1);
	}

	function startExitState(nextState:FlxState)
	{
		menuItems.enabled = false;
		menuItems.forEachAlive(function(item:MainMenuItem)
		{
			if (menuItems.selectedIndex != item.ID)
				FlxTween.tween(item, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
			else
				item.visible = false;
		});
		new FlxTimer().start(0.4, function(tmr:FlxTimer)
		{
			Main.switchState(nextState);
		});
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (_exiting)
			menuItems.enabled = false;

		if (controls.BACK && menuItems.enabled && !menuItems.busy)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new TitleState());
		}

		#if desktop
		if (FlxG.keys.anyJustPressed(debugKeys))
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}
		#end

		super.update(elapsed);
	}
}

class MainMenuItem extends AtlasMenuItem
{
	public function new(?x:Float = 0, ?y:Float = 0, name:String, atlas:FlxAtlasFrames, ?callback:Void->Void)
	{
		super(x, y, name, atlas, callback);
		this.scrollFactor.set();
	}

	override public function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		origin.set(frameWidth * 0.5, frameHeight * 0.5);
		offset.copyFrom(origin);
	}
}

class MainMenuList extends MenuTypedList<MainMenuItem>
{
	var atlas:FlxAtlasFrames;
	var items:MainMenuState.menuItems;

	public function new()
	{
		for (i in 0...items.length)
		{
			atlas = Paths.getSparrowAtlas('mainmenu/menu_' + items[i]);
		}
		super(Vertical);
	}

	public function createItem(?x:Float = 0, ?y:Float = 0, name:String, ?callback:Void->Void, fireInstantly:Bool = false)
	{
		var item:MainMenuItem = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = length;
		addItem(name, item);
		if (length > 4)
		{
			var scr:Float = (length - 4) * 0.135;
			forEachAlive(function(item:MainMenuItem)
			{
				item.scrollFactor.set(0, scr);
			});
		}
		return item;
	}
}