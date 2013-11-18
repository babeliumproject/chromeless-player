package
{
	
	import api.JavascriptAPI;
	
	import events.VideoPlayerEvent;
	
	import flash.display.GradientType;
	import flash.display.GraphicsPathCommand;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.System;
	
	import media.RTMPMediaManager;
	
	import model.SharedData;
	
	import mx.resources.ResourceManager;
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.LOGGER_FACTORY;
	import org.as3commons.logging.setup.LevelTargetSetup;
	import org.as3commons.logging.setup.LogSetupLevel;
	import org.as3commons.logging.setup.target.FirebugTarget;
	import org.as3commons.logging.setup.target.TraceTarget;
	
	import player.VideoRecorder;
	
	import utils.Helpers;
	
	[SWF(width="640", height="480")]
	public class babeliumPlayer extends Sprite
	{
		//LOGGER_FACTORY.setup = new LevelTargetSetup( new TraceTarget, LogSetupLevel.DEBUG );
		LOGGER_FACTORY.setup = new LevelTargetSetup(new FirebugTarget, LogSetupLevel.DEBUG );
		
		private var video_id:String=null;
		private var video_url:String=null;
		private var language_file:String=null;
		
		private var mediarecorder:VideoRecorder;
		
		private var appWidth:uint;
		private var appHeight:uint;
		
		public function babeliumPlayer()
		{
			this.root.loaderInfo.addEventListener(Event.COMPLETE, complete);
		}
		
		private function complete(event:Event):void{
			
			stage.color=0x00ff00;
			
			Security.allowDomain("*");
			
			appWidth=this.root.loaderInfo.width;
			appHeight=this.root.loaderInfo.height;
			
			video_url=this.root.loaderInfo.parameters.video_url;
			video_id=this.root.loaderInfo.parameters.video_id;
			language_file=this.root.loaderInfo.parameters.language_file;
			
			loadLocalizationBundle(language_file);
			
			mediarecorder = new VideoRecorder();
			//mediaplayer.addEventListener(VideoPlayerEvent.CREATION_COMPLETE, onVideoPlayerLoaded);
			
			addChild(mediarecorder);
			
			// Setups javascripts external controls
			
			JavascriptAPI.getInstance().setup(mediarecorder);
			onVideoPlayerLoaded(null);
		}
		
		private function loadLocalizationBundle(url:String):void{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, parseLocalizationBundle);
			loader.addEventListener(IOErrorEvent.IO_ERROR, urlNotAvailable);
			loader.load(new URLRequest(url));
		}
		
		private function urlNotAvailable(e:IOErrorEvent):void{
			trace("Couldn't load the specified resource from the url. "+e.text);
		}
		
		private function parseLocalizationBundle(e:Event):void{
			XML.ignoreWhitespace = true;
			var bundle:XML = new XML(e.target.data);
			//XML attributes are referenced using @
			var locale:String = bundle.@locale; 
			var messages:Object = new Object();
			for each(var msg:XML in bundle.messages.msg){
				messages[msg.@name] = msg.text();
			}
			SharedData.getInstance().localizationBundle = messages;
		}
		
	
		
		private function onVideoPlayerLoaded(e:Event):void
		{
			trace("VideoRecorded loaded");
			mediarecorder.unscaledWidth=appWidth;
			mediarecorder.unscaledHeight=appHeight;
			
			JavascriptAPI.getInstance().onBabeliumPlayerReady();
			
			if (video_id != null){
				mediarecorder.loadVideoById(video_id);
			}
		}
		
		private function set onUpdateVPHeight(height:int):void
		{
			trace("VP Height: "+mediarecorder.height);
			//Extern.getInstance().resizeHeight(height);
		}
		
		private function set onUpdateVPWidth(width:int):void
		{
			trace("VP Width: "+mediarecorder.width);
			//Extern.getInstance().resizeWidth(width);
		}
		
	}
}