package view
{
	import assets.DefaultStyle;
	import assets.EncircledShape;
	import assets.MicImage;
	import assets.UnlockImage;
	import assets.VectorShape;
	
	import events.PrivacyEvent;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import media.RTMPMediaManager;
	import media.UserDeviceManager;
	
	import model.SharedData;
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;

	public class PrivacyPanel extends Sprite
	{
		protected static const logger:ILogger=getLogger(PrivacyPanel);
		
		public static const IGNORE:uint = 0x0001;
		public static const RETRY:uint = 0x0002;
		
		private var container:Sprite;
		private var container_width:uint = 320;
		private var container_height:uint = 240;
		private var container_border:Shape;
		private var container_icon:EncircledShape;
		
		private var explayer:Sprite;
		private var explayer_width:uint;
		private var explayer_height:uint;
		private var explayer_textfield:TextField;
		private var explayer_textformat:TextFormat;

		private var layer:Sprite;
		private var layer_textfield:TextField;
		private var layer_textformat:TextFormat;
		private var layer_padding:uint=8;
		private var layer_icon:VectorShape;

		private var acceptButton:PrivacyButton=new PrivacyButton();
		private var cancelButton:PrivacyButton=new PrivacyButton();

		private var userDeviceManagerInstance:UserDeviceManager;

		public function PrivacyPanel(unscaledWidth:uint, unscaledHeight:uint)
		{
			super();
			
			userDeviceManagerInstance=SharedData.getInstance().userDeviceManager;
			userDeviceManagerInstance.addEventListener(PrivacyEvent.DEVICE_STATE_CHANGE, deviceStateChangeHandler);
			
			acceptButton.label=SharedData.getInstance().getText('BUTTON_RETRY');
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			cancelButton.label=SharedData.getInstance().getText('BUTTON_CANCEL');
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);
			
			addEventListener(MouseEvent.MOUSE_OVER, onMouseEvent);
			
			updateDisplayList(unscaledWidth,unscaledHeight);
			drawBackground();
		}
	
		private function onMouseEvent(event:MouseEvent):void{
			//logger.debug(event.type);
			if (SharedData.getInstance().userDeviceManager.deviceAccessGranted)
				dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE_ACCEPT));
		}

		public function updateDisplayList(unscaledWidth:uint, unscaledHeight:uint):void{
			container_width  = !unscaledWidth  ? container_width  : unscaledWidth;
			container_height = !unscaledHeight ? container_height : unscaledHeight;
			
			this.graphics.clear();
			this.graphics.beginFill(0,0);
			this.graphics.drawRect(0,0,container_width,container_height);
			this.graphics.endFill();
			
			if(container) updateBackground();
			if(explayer) updateExplanationLayer();
			if(layer) updateErrorLayer();
		}
		
		private function drawBackground():void{
			if(!container){
				container = new Sprite();
				this.addChild(container);
			}
			
			if(!container_icon){
				container_icon=new EncircledShape();
				container_icon.draw(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
					DefaultStyle.ASSET_LOCK_VECCMD, DefaultStyle.ASSET_LOCK_VECDATA,
					DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.ASSET_LOCK_GRADIENT_COLORS, 
					DefaultStyle.ASSET_LOCK_GRADIENT_ALPHAS, DefaultStyle.ASSET_GRADIENT_RATIOS, 
					DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
				container.addChild(container_icon);
			}
			
			if(!container_border){
				container_border = new Shape();
				container.addChild(container_border);
			}
			
			updateBackground();
		}
		
		private function updateBackground():void{
			var m:Matrix = new Matrix();
			m.createGradientBox(container_width, container_height, 
				90*Math.PI/DefaultStyle.BGR_GRADIENT_ANGLE_DEC, 0, 0);
			
			container.graphics.clear();
			container.graphics.beginGradientFill(DefaultStyle.BGR_GRADIENT_TYPE, 
				DefaultStyle.PRIVACY_BGR_GRADIENT_COLORS,
				DefaultStyle.BGR_GRADIENT_ALPHAS,
				DefaultStyle.BGR_GRADIENT_RATIOS, m);
			container.graphics.drawRect(0, 0, container_width, container_height);
			container.graphics.endFill();
			
			scaleDisplayObject(container_icon,container_width,container_height);
			container_icon.x=-container_icon.width*0.25;
			container_icon.y=+container_icon.height*0.25;
			
			container_border.graphics.clear();
			container_border.graphics.lineStyle(1,DefaultStyle.BGR_SOLID_COLOR,0.6);
			container_border.graphics.drawRect(0, 0, container_width-1, container_height-1);
			container_border.graphics.endFill();	
		}
		
		private function drawExplanationLayer(msg:String):void{
			if(!explayer){
				explayer = new Sprite();
				this.addChild(explayer);
			}
			
			if(!explayer_textfield){
				explayer_textformat = new TextFormat();
				explayer_textformat.align = DefaultStyle.FONT_ALIGN;
				explayer_textformat.font = DefaultStyle.FONT_FAMILY;
				explayer_textformat.color= DefaultStyle.PRIVACY_FONT_COLOR;
				explayer_textfield = new TextField();
				explayer_textfield.autoSize = TextFieldAutoSize.CENTER;
				explayer_textfield.wordWrap = true;
				explayer.addChild(explayer_textfield);
			}
			explayer_textfield.text=msg;

			updateExplanationLayer();
			userDeviceManagerInstance.showPrivacySettings();		
		}
		
		private function updateExplanationLayer():void{
			explayer_width = container_width * .85;
			explayer_height = container_height * .80;
			explayer.graphics.clear();
			explayer.graphics.beginFill(DefaultStyle.BGR_SOLID_COLOR,0);
			explayer.graphics.drawRect(0,0,explayer_width, explayer_height);
			explayer.graphics.endFill();
			explayer.x = container_width/2-(explayer_width/2);
			explayer.y = container_height/2-(explayer_height/2);
			
			explayer_textformat.size = Math.floor(container_height * .06);
			explayer_textfield.setTextFormat(explayer_textformat);
			explayer_textfield.width = explayer_width;
			explayer_textfield.x = explayer_width/2 - explayer_textfield.width/2;
		}
		
		protected function drawErrorLayer(text:String, flags:uint=0x0003, iconClass:DisplayObject=null):void{	
			if(!layer){
				layer=new Sprite();
				layer.graphics.clear();
				layer.graphics.beginFill(DefaultStyle.PRIVACY_RETRY_BGR_SOLID_COLOR,DefaultStyle.BGR_SOLID_ALPHA);
				layer.graphics.lineStyle(DefaultStyle.PRIVACY_RETRY_LINE_WEIGHT,DefaultStyle.PRIVACY_RETRY_LINE_COLOR,DefaultStyle.PRIVACY_RETRY_LINE_ALPHA);
				layer.graphics.drawRect(0,0,DefaultStyle.PRIVACY_RETRY_WIDTH,DefaultStyle.PRIVACY_RETRY_HEIGHT);
				layer.graphics.endFill();
				
				var layerShadow:DropShadowFilter = new DropShadowFilter();
				layerShadow.color=DefaultStyle.PRIVACY_RETRY_SHADOW_COLOR;
				layerShadow.blurX=DefaultStyle.PRIVACY_RETRY_SHADOW_BLURX;
				layerShadow.blurY=DefaultStyle.PRIVACY_RETRY_SHADOW_BLURY;
				layerShadow.alpha=DefaultStyle.PRIVACY_RETRY_SHADOW_ALPHA;
				layerShadow.strength=DefaultStyle.PRIVACY_RETRY_SHADOW_STRENGTH;
				layerShadow.distance=DefaultStyle.PRIVACY_RETRY_SHADOW_DISTANCE;
				layerShadow.angle=DefaultStyle.PRIVACY_RETRY_SHADOW_ANGLE;
				
				layer.filters = [layerShadow];	
			} 
			if(!this.contains(layer)) this.addChild(layer);	
			
			//Add icon (if any)
			if(layer_icon && layer.contains(layer_icon)) layer.removeChild(layer_icon);
			if(iconClass){
				layer_icon=null;
				layer_icon=iconClass as VectorShape;
				scaleDisplayObject(layer_icon, layer.width*0.3, layer.height*0.3);
				iconClass.x = (-layer_icon.offsetX) + (layer.width - layer_icon.width) / 2;
				iconClass.y = (-layer_icon.offsetY) + layer_padding;
				layer.addChild(layer_icon);
			}
			
			//Add message
			if(!layer_textfield){
			
				layer_textformat=new TextFormat();
				layer_textformat.font=DefaultStyle.FONT_FAMILY;
				layer_textformat.size=DefaultStyle.FONT_SIZE;
				layer_textformat.align=DefaultStyle.FONT_ALIGN;
				layer_textformat.color=DefaultStyle.PRIVACY_BUTTON_FONT_COLOR_UPSTATE;
				
				layer_textfield=new TextField();
				layer_textfield.autoSize = TextFieldAutoSize.CENTER;
				layer_textfield.defaultTextFormat=layer_textformat;
				//Don't use the width property of the sprite, it might be wrong because adding text changes the size of the container to fit the text
				layer_textfield.width=DefaultStyle.PRIVACY_RETRY_WIDTH;
				layer_textfield.wordWrap=true;
				
				layer.addChild(layer_textfield);
			}	
			layer_textfield.text=text;
			layer_textfield.y=layer.height*0.3+layer_padding;
			layer_textfield.x=(DefaultStyle.PRIVACY_RETRY_WIDTH-layer_textfield.width)/2;
			
			//Add buttons
			if(layer.contains(cancelButton)) layer.removeChild(cancelButton);
			if(layer.contains(acceptButton)) layer.removeChild(acceptButton);
			switch (flags){
				case IGNORE:
					layer.addChild(cancelButton);
					cancelButton.x = (layer.width - cancelButton.width) - layer_padding;
					cancelButton.y = (layer.height - cancelButton.height) - layer_padding;
					break;
				case RETRY:
					layer.addChild(cancelButton);
					acceptButton.x = (layer.width - acceptButton.width) - layer_padding;
					acceptButton.y = (layer.height - acceptButton.height) - layer_padding;
					break;
				case RETRY | IGNORE:
					layer.addChild(cancelButton);
					layer.addChild(acceptButton);
					cancelButton.x = (layer.width - cancelButton.width) - layer_padding;
					
					cancelButton.y = (layer.height - cancelButton.height) - layer_padding;
					acceptButton.x = (cancelButton.x - acceptButton.width) - layer_padding;
					acceptButton.y = (layer.height - acceptButton.height) - layer_padding;
					break;
				default:
					break;
			}
			updateErrorLayer();
		}
		
		private function updateErrorLayer():void{
			layer.x=-1+(container_width-layer.width)/2;
			layer.y=-1+(container_height-layer.height)/2;
		}
		
		protected function scaleDisplayObject(target:DisplayObject, scaled_width:uint, scaled_height:uint):void{
			
			//Get the scale factor of each dimension, pick the smaller one to maintain the aspect ratio of the DisplayObject
			var scaleX:Number=scaled_width / target.width;
			var scaleY:Number=scaled_height / target.height;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
			logger.debug("Scaling object. Current size: {0}x{1}, Target size: {2}x{3}, Current scale: [{4}, {5}] ", 
						 [target.width, target.height, scaled_width, scaled_height, target.scaleX, target.scaleY]);
			//Scale the DisplayObject
			//target.width=Math.ceil(target.width * scaleC);
			//target.height=Math.ceil(target.height * scaleC);
			target.scaleX=target.scaleY=scaleC;
		}
		
		/*
		 * Methods to deal with user interaction
		 */
		public function displaySettings():void
		{
			userDeviceManagerInstance.initDevices();
		}
		
		private function deviceStateChangeHandler(event:PrivacyEvent):void
		{
			logger.debug("Device state change: {0}", [event.state]);
			var errormsg:String;
			var explainmsg:String;
			var icon:VectorShape;
			switch (event.state)
			{
				case PrivacyEvent.AV_HARDWARE_DISABLED:
				{
					errormsg=SharedData.getInstance().getText('DEVICES_ADM_DISABLED');
					drawErrorLayer(errormsg,IGNORE);
					break;
				}
				case PrivacyEvent.NO_MICROPHONE_FOUND:
				{
					errormsg=SharedData.getInstance().getText('MIC_NOT_FOUND') + '\n' + SharedData.getInstance().getText('TRY_AGAIN');
					icon=new VectorShape(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
										 DefaultStyle.ASSET_MIC_VECCMD, DefaultStyle.ASSET_MIC_VECDATA,
										 DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.BGR_GRADIENT_COLORS, 
										 DefaultStyle.ASSET_GRADIENT_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, 
										 DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
					drawErrorLayer(errormsg, RETRY|IGNORE, icon);
					break;
				}
				case PrivacyEvent.NO_CAMERA_FOUND:
				{
					errormsg=SharedData.getInstance().getText('WEBCAM_NOT_FOUND') + '\n' + SharedData.getInstance().getText('TRY_AGAIN');
					icon=new VectorShape(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
										 DefaultStyle.ASSET_WEBCAM_VECCMD, DefaultStyle.ASSET_WEBCAM_VECDATA,
										 DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.BGR_GRADIENT_COLORS, 
										 DefaultStyle.ASSET_GRADIENT_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, 
										 DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
					drawErrorLayer(errormsg, RETRY|IGNORE, icon);
					break;
				}
				case PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED:
				{
					explainmsg=SharedData.getInstance().getText('SELECT_ALLOW');
					drawExplanationLayer(explainmsg);
					
					errormsg=SharedData.getInstance().getText('DEVICES_NOT_ACTIVATED') + '\n' + SharedData.getInstance().getText('TRY_AGAIN');
					icon=new VectorShape(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
										 DefaultStyle.ASSET_WARNING_VECCMD, DefaultStyle.ASSET_WARNING_VECDATA,
										 DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.ASSET_LOCK_GRADIENT_COLORS, 
										 DefaultStyle.ASSET_GRADIENT_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, 
										 DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
					drawErrorLayer(errormsg, RETRY|IGNORE, icon);
					break;
				}
				case PrivacyEvent.DEVICE_ACCESS_GRANTED:
				{
					explainmsg=SharedData.getInstance().getText('NOW_CLICK_REMEMBER');
					drawExplanationLayer(explainmsg);

					if(layer) this.removeChild(layer);
					break;
				}
				default:
				{
					break;
				}
			}
		}
		
		private function retryClickHandler(event:MouseEvent):void
		{
			userDeviceManagerInstance.initDevices();
		}
		
		private function cancelClickHandler(event:MouseEvent):void
		{
			dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE_CANCEL));
		}
	}
}
