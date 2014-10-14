package
{
	
	import api.JavascriptAPI;
	
	import events.VideoPlayerEvent;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.GraphicsPathCommand;
	import flash.display.LoaderInfo;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.EventPhase;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.System;
	
	import flashx.textLayout.formats.WhiteSpaceCollapse;
	
	import media.RTMPMediaManager;
	
	import model.SharedData;
	
	import mx.resources.ResourceManager;
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.LOGGER_FACTORY;
	import org.as3commons.logging.setup.HierarchicalSetup;
	import org.as3commons.logging.setup.LevelTargetSetup;
	import org.as3commons.logging.setup.LogSetupLevel;
	import org.as3commons.logging.setup.log4j.Log4JStyleSetup;
	import org.as3commons.logging.setup.log4j.log4jPropertiesToSetup;
	import org.osmf.layout.ScaleMode;
	
	import player.VideoRecorder;
	
	import util.Helpers;
	import util.StageProxy;
	
	public class BabeliumPlayer extends Sprite
	{
		//LOGGER_FACTORY.setup = new LevelTargetSetup( new TraceTarget, LogSetupLevel.DEBUG );
		//LOGGER_FACTORY.setup = new LevelTargetSetup(new FirebugTarget, LogSetupLevel.DEBUG );
		
		private var video_id:String=null;
		private var video_url:String=null;
		private var language_file:String=null;
		
		private var mediarecorder:VideoRecorder;
		
		private var appWidth:Number=640;;
		private var appHeight:Number=480;
		
		private var stageProxy:StageProxy;
		
		public function BabeliumPlayer()
		{
			loaderInfo.addEventListener(Event.INIT, onLoaderInfoInit);
		}
		
		protected function onLoaderInfoInit(event:Event):void{
			stageProxy = new StageProxy(this);
			stageProxy.align=StageAlign.TOP_LEFT;
			stageProxy.scaleMode=StageScaleMode.NO_SCALE;
			init();
		}
		
		private function init():void{
			stageProxy.addEventListener(Event.RESIZE, onResize);
			afterInit();
		}
		
		private function afterInit():void{
			//super.afterInit();
			this.onResize();
			this.startApplication();
			this.addCallbacks();
		}
		
		public function startApplication():void{
			//Check the state of the video player
			//if the user provided some videoid try to play it,
			//otherwise show empty player
			complete(null);
		}
		
		/**
		 * Add the functions available through the API
		 **/
		public function addCallbacks():void{
			//Add the
		}
		
		public function onResize(event:Event = null):void{
			//Only resize if the event is in the target node
			if (event && event.eventPhase != EventPhase.AT_TARGET)
			{
				trace("Stageproxy called resize");
				return;
			}
			var embeddedInSwf:Boolean=false;
			
			if(stageProxy.stageAvailable && !embeddedInSwf){
				trace("Stage dimensions: "+stageProxy.stageWidth+"x"+stageProxy.stageHeight);
				//this.resizeApplication(stageProxy.stageWidth, stageProxy.stageHeight);
			}
			else
				updateDisplayList();
		}
		
		public function resizeApplication(width:Number, height:Number):void{
			this.appWidth = width;
			this.appHeight = height;
			updateDisplayList();
		}
		
		/** update all children element sizes **/
		private function updateDisplayList():void{
			var i:int = numChildren - 1;
			while(i >= 0){
				var child:DisplayObject = getChildAt(i);
				//update child size
				i--;
			}
		}
		
		private function complete(event:Event):void{	
			Security.allowDomain("*");
			
			//appWidth=this.root.loaderInfo.width;
			//appHeight=this.root.loaderInfo.height;
			
			video_url=this.root.loaderInfo.parameters.video_url;
			video_id=this.root.loaderInfo.parameters.video_id;
			language_file=this.root.loaderInfo.parameters.language_file;
			
			loadLoggingConfig('/chromeless_player/logging.properties');
			loadLocalizationBundle(language_file);
		}
		
		private function loadLoggingConfig(url:String):void{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, parseLoggingConfig);
			loader.addEventListener(IOErrorEvent.IO_ERROR, urlNotAvailable);
			loader.load(new URLRequest(url));
		}
		
		private function parseLoggingConfig(event:Event):void{
			LOGGER_FACTORY.setup = log4jPropertiesToSetup(event.target.data);
		}
		
		private function loadMediaRecorder():void{
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
			loadMediaRecorder();
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
			trace("Everything loaded, Stage dimensions: "+stage.stageWidth+"x"+stage.stageHeight);
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