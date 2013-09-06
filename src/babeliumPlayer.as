package
{
	
	import api.JavascriptAPI;
	
	import events.VideoPlayerEvent;
	
	import flash.display.GradientType;
	import flash.display.GraphicsPathCommand;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.System;
	
	import media.MediaManager;
	
	import model.SharedData;
	
	import mx.resources.ResourceManager;
	
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
		LOGGER_FACTORY.setup = new LevelTargetSetup( new TraceTarget, LogSetupLevel.DEBUG );
		//LOGGER_FACTORY.setup = new LevelTargetSetup(new FirebugTarget(), LogSetupLevel.DEBUG );
		
		private var videoId:String=null;
		private var explicit_locale:String=null;
		
		private var VP:VideoRecorder;
		
		private var appWidth:uint;
		private var appHeight:uint;
		
		public function babeliumPlayer()
		{
			this.root.loaderInfo.addEventListener(Event.COMPLETE, complete);
		}
		
		private function complete(event:Event):void{
			Security.allowDomain("*");
			
			appWidth=this.root.loaderInfo.width;
			appHeight=this.root.loaderInfo.height;
			
			videoId=this.root.loaderInfo.parameters.video_id;
			explicit_locale=this.root.loaderInfo.parameters.language_file;
			
			loadLocalizationBundle(explicit_locale);
			
			VP = new VideoRecorder();
			VP.addEventListener(VideoPlayerEvent.CONNECTED, onConnect);
			addChild(VP);
			
			//parseUrl("rtmp://babelium/exercises/567b5464v");
			//parseUrl("rtmpt://babeliumproject.com/sdflkjsdf/sdflkjsdf/sdfkdfk444");
			//parseUrl("rtmpe://babelium/exeffi001.flv");
			//parseUrl("rtmps://babbelum:19234/sdfeif.flv");
			//parseUrl("rtp://babeliumproject.com/sdfoisjef/sfei.fvl");

		
			if (videoId != null)
				VP.videoSource=SharedData.getInstance().streamingManager.exerciseStreamsFolder + "/" + videoId;
			stage.color=0x00ff00;
			// Setups javascripts external controls
			JavascriptAPI.getInstance().setup(VP);
			//addChild(VP);
			VP.width=appWidth;
			VP.height=appHeight;
			//stage.addEventListener(KeyboardEvent.KEY_DOWN, kdown);
		}
		
		private function kdown(event:KeyboardEvent):void{
			trace(String.fromCharCode(event.charCode));
			if(String.fromCharCode(event.charCode) == 'a'){
				trace("a presed");
				VP.loadVideo();
			}
		}
		
		private function loadLocalizationBundle(url:String):void{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, parseLocalizationBundle);
			loader.load(new URLRequest(url));
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
		
		/**
		 * Parse the given parameter to check whether it is an acceptable URL for either progressive download
		 * or streaming, retrieving the domain name along the process. 
		 * 
		 * @param url 
		 */		
		public function parseUrl(url:String):void{
			if (url.length >=4096) return;
			
			//var prRegExp:RegExp=new RegExp("(^http[s]?\:\\/\\/+)([^\\/]+$)");
			//var stRegExp:RegExp=new RegExp("^rtmp[t|e|s]?\:\\/\\/([^\\/]+)");
			var stRegExp:RegExp=new RegExp("(^rtmp[t|e|s]?\:\\/\\/.+)\\/(.+)");
			//var resultPr:Object=prRegExp.exec(url);
			var resultSt:Object=stRegExp.exec(url);
			//trace(""+resultPr.toString());
			if(resultSt)
			trace("Parse: "+resultSt[0]+"\t"+resultSt[1]+"\t"+resultSt[2]);
			//if (!resultPr && !resultSt){
			//
			//}
		}
		
		private function onConnect(e:Event):void
		{
			//Extern.getInstance().onConnectionReady();
			JavascriptAPI.getInstance().onBabeliumPlayerReady();
		}
		
		private function set onUpdateVPHeight(height:int):void
		{
			trace("VP Height: "+VP.height);
			//Extern.getInstance().resizeHeight(height);
		}
		
		private function set onUpdateVPWidth(width:int):void
		{
			trace("VP Width: "+VP.width);
			//Extern.getInstance().resizeWidth(width);
		}
		
	}
}