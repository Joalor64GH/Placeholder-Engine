package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display.StageScaleMode;
import flixel.addons.transition.FlxTransitionableState;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.

	public static var fpsVar:FPS;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		final stageWidth:Int = Lib.current.stage.stageWidth;
		final stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			final ratioX:Float = stageWidth / gameWidth;
			final ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
	
		ClientPrefs.loadDefaultKeys();
		addChild(new FlxGame(gameWidth, gameHeight, TitleState, #if (flixel < "5.0.0") zoom, #end 60, 60, true, false));

		fpsVar = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
		}

		#if html5
		FlxG.autoPause = FlxG.mouse.visible = false;
		#end
	}

	public static function switchState(nextState:FlxState)
	{
		var callback = function()
		{
			if (nextState == FlxG.state)
				FlxG.resetState();
			else
				FlxG.switchState(nextState);
		};
		if (!FlxTransitionableState.skipNextTransIn)
		{
			var state = FlxG.state;
			@:privateAccess
			if (Std.isOfType(state, FlxTransitionableState))
				cast(state, FlxTransitionableState)._exiting = true;
			while (state.subState != null)
				state = state.subState;
			state.openSubState(new FadeSubstate(0.5, false, callback));
		}
		else
		{
			FlxTransitionableState.skipNextTransIn = false;
			callback();
		}
	}
}