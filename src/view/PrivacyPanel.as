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
		
		private var localizationBundle:Object;
		
		private var container_width:uint = 320;
		private var container_height:uint = 240;
		
		private var frame:Sprite;
		private var instrText:TextField;
		private var instrMsg:String;
		private var bgrShape:VectorShape;

		private var title:TextField=new TextField();
		private var titleFmt:TextFormat=new TextFormat();

		private var container:Sprite=new Sprite();
		private var containerBgImg:UnlockImage=new UnlockImage();

		private var layer:Sprite=new Sprite();
		//private var layerImg:MicImage=new MicImage();
		private var message:TextField=new TextField();

		private var acceptButton:PrivacyButton=new PrivacyButton();
		private var cancelButton:PrivacyButton=new PrivacyButton();

		private var privacyManager:UserDeviceManager;

		public function PrivacyPanel(unscaledWidth:uint, unscaledHeight:uint)
		{
			super();
			localizationBundle=SharedData.getInstance().localizationBundle;
			addEventListener(FocusEvent.FOCUS_IN, onFocusEvent);
			addEventListener(FocusEvent.FOCUS_OUT, onFocusEvent);
			addEventListener(FocusEvent.KEY_FOCUS_CHANGE, onFocusEvent);
			addEventListener(FocusEvent.MOUSE_FOCUS_CHANGE, onFocusEvent);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseEvent);
			updateDisplayList(unscaledWidth, unscaledHeight);
			
		}
		
		private function onFocusEvent(event:FocusEvent):void{
			logger.debug(event.type);
		}
		
		private function onMouseEvent(event:MouseEvent):void{
			logger.debug(event.type);
			if (SharedData.getInstance().privacyManager.deviceAccessGranted)
				dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE_ACCEPT));
		}

		private function getChildenHeigth():uint
		{
			var occupiedHeigth:uint=0;
			for (var i:uint; i < this.numChildren; i++)
			{
				occupiedHeigth+=this.getChildAt(i).height;
			}
			return occupiedHeigth;
		}

		public function updateDisplayList(unscaledWidth:uint, unscaledHeight:uint):void{
			
			container_width  = !unscaledWidth  ? container_width  : unscaledWidth;
			container_height = !unscaledHeight ? container_height : unscaledHeight;
		
			//drawBackground(container_width, container_height);
			drawBackground2();
		}
		
		private function drawBackground2():void{
			var m:Matrix = new Matrix();
			m.createGradientBox(container_width, container_height, 
								90*Math.PI/DefaultStyle.BGR_GRADIENT_ANGLE_DEC, 0, 0);
			this.graphics.clear();
			this.graphics.beginGradientFill(DefaultStyle.BGR_GRADIENT_TYPE, 
											DefaultStyle.PRIVACY_BGR_GRADIENT_COLORS,
											DefaultStyle.BGR_GRADIENT_ALPHAS,
											DefaultStyle.BGR_GRADIENT_RATIOS, m);
			this.graphics.drawRect(0, 0, container_width, container_height);
			this.graphics.endFill();
			
			//TODO
			//Add some nice graphic at the lower-left part of the background
			/*
			bgrShape=new VectorShape(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
									 DefaultStyle.ASSET_LOCK_VECCMD, DefaultStyle.ASSET_LOCK_VECDATA,
									 DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.ASSET_LOCK_GRADIENT_COLORS, 
									 DefaultStyle.ASSET_LOCK_GRADIENT_ALPHAS, DefaultStyle.ASSET_GRADIENT_RATIOS, 
									 DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
			scaleDisplayObject(bgrShape,container_width*0.7,container_height*0.7);
			bgrShape.x = (-bgrShape.offsetX) - bgrShape.width*.25;
			bgrShape.y = (-bgrShape.offsetY) - bgrShape.height*.25;
			*/
			var es:EncircledShape=new EncircledShape();
			es.draw(DefaultStyle.ASSET_DEFAULT_WIDTH, DefaultStyle.ASSET_DEFAULT_HEIGHT,
				DefaultStyle.ASSET_LOCK_VECCMD, DefaultStyle.ASSET_LOCK_VECDATA,
				DefaultStyle.ASSET_GRADIENT_TYPE, DefaultStyle.ASSET_LOCK_GRADIENT_COLORS, 
				DefaultStyle.ASSET_LOCK_GRADIENT_ALPHAS, DefaultStyle.ASSET_GRADIENT_RATIOS, 
				DefaultStyle.ASSET_GRADIENT_ANGLE_DEC);
			scaleDisplayObject(es,container_width,container_height);
			es.x=-es.width*0.25;
			es.y=+es.height*0.25;
			this.addChild(es);
			
			var frame_decoration:Shape = new Shape();
			frame_decoration.graphics.clear();
			frame_decoration.graphics.lineStyle(1,DefaultStyle.BGR_SOLID_COLOR,0.6);
			frame_decoration.graphics.drawRect(0, 0, container_width-1, container_height-1);
			frame_decoration.graphics.endFill();
			this.addChild(frame_decoration);
		}
		
		private function drawPrivacyNotice2(msg:String):void{
			
			// Remove previous 'frame' from background
			if(frame != null && this.contains(frame)) this.removeChild(frame);
			
			var frame_width:uint = container_width * .85;
			var frame_height:uint = container_height * .80;
			frame = new Sprite();
			frame.graphics.clear();
			frame.graphics.beginFill(DefaultStyle.BGR_SOLID_COLOR,0);
			frame.graphics.drawRect(0,0,frame_width, frame_height);
			frame.graphics.endFill();
			frame.x = container_width/2-(frame_width/2);
			frame.y = container_height/2-(frame_height/2);
			
			var _textFormat:TextFormat = new TextFormat();
			_textFormat.align = DefaultStyle.FONT_ALIGN;
			_textFormat.font = DefaultStyle.FONT_FAMILY;
			_textFormat.color= DefaultStyle.PRIVACY_FONT_COLOR;
			//_textFormat.bold = true;
			_textFormat.size = Math.floor(container_height * .06); //Make the text's height proportional to the frame height
			
			instrText = new TextField();
			instrText.text = localizationBundle[msg] ? localizationBundle[msg] : '';
			instrText.setTextFormat(_textFormat);
			instrText.width = frame_width;
			instrText.autoSize = TextFieldAutoSize.CENTER;
			instrText.wordWrap = true;
			instrText.x = frame_width/2 - instrText.width/2;
			//instrText.y = container_height/2 - instrText.height/2;
			instrText.setTextFormat(_textFormat);
			
			frame.addChild(instrText);
			addChild(frame);
			
			//TODO
			//Add a little panel (218x138) centered in the frame with a "No mic" or "No cam" notice text and the buttons "Try again"/"Ignore" 
			layer=new Sprite();
			layer.graphics.clear();
			layer.graphics.beginFill(0xffffff,1);
			layer.graphics.lineStyle(1,0,1);
			layer.graphics.drawRect(0,0,218,138);
			layer.graphics.endFill();
			
			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();
			
			message.text=localizationBundle['TEXT_MIC_NOT_FOUND'];
			
			acceptButton.label=localizationBundle['BUTTON_RETRY'];
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			cancelButton.label=localizationBundle['BUTTON_CANCEL'];
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);
			

			acceptButton.y=layer.height * 0.9;
			cancelButton.x=acceptButton.width + 20;
			cancelButton.y=layer.height * 0.9;
			
			layer.addChild(message);
			//layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
			
			addChild(layer);
			layer.x=(container_width-layer.width)/2;
			layer.y=(container_height-layer.height)/2;
			
			privacyManager.showPrivacySettings();		
		}
		
		protected function scaleDisplayObject(target:DisplayObject, scaled_width:uint, scaled_height:uint):void{
			
			//Get the scale factor of each dimension, pick the smaller one to maintain the aspect ratio of the DisplayObject
			var scaleX:Number=scaled_width / target.width;
			var scaleY:Number=scaled_height / target.height;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
			
			//Scale the DisplayObject
			//target.width=Math.ceil(target.width * scaleC);
			//target.height=Math.ceil(target.height * scaleC);
			target.scaleX=target.scaleY=scaleC;
		}
		
		private function drawBackground(nWidth:uint, nHeight:uint, padding:uint=30, gap:uint=2):void
		{
			this.graphics.clear();
			this.graphics.beginFill(0x000000, 0.75);
			this.graphics.drawRect(0, 0, nWidth, nHeight);
			this.graphics.endFill();

			titleFmt.font="Arial";
			titleFmt.color=0xffffff;
			titleFmt.size=18;
			titleFmt.bold=true;
			title.defaultTextFormat=titleFmt;
			title.text=localizationBundle['TITLE_PRIVACY_SETTINGS'] ? localizationBundle['TITLE_PRIVACY_SETTINGS'].toUpperCase() : '';
			title.width=nWidth - 2 * padding;
			title.x=padding;
			title.y=padding;

			container.graphics.clear();
			container.graphics.lineStyle(1, 0xA7A7A7);
			container.graphics.beginFill(0x000000, 0.0);
			container.graphics.drawRect(0, 0, nWidth - (2 * padding), nHeight - (2 * padding) - title.textHeight - gap);
			container.graphics.endFill();
			container.x=padding;
			container.y=padding + title.textHeight + gap;

			containerBgImg.x=width - padding - containerBgImg.width; //rightmost, top
			containerBgImg.y=0;

			layer.graphics.clear();
			layer.graphics.beginFill(0x000000, 0.0);
			layer.graphics.drawRect(0, 0, container.width - (2 * padding), container.height - (2 * padding));
			layer.graphics.endFill();
			layer.x=layer.y=padding;

			container.addChild(containerBgImg);
			container.addChild(layer);

			addChild(title);
			addChild(container);
		}

		private function drawMicNotFound():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();
			
			message.text=SharedData.getInstance().getText('TEXT_MIC_NOT_FOUND');

			acceptButton.label=SharedData.getInstance().getText('BUTTON_RETRY');
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			cancelButton.label=SharedData.getInstance().getText('BUTTON_CANCEL');
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			//layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}

		private function drawCamNotFound():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();

			message.text=SharedData.getInstance().getText('TEXT_CAMERA_NOT_FOUND');

			acceptButton.label=SharedData.getInstance().getText('BUTTON_RETRY');
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			cancelButton.label=SharedData.getInstance().getText('BUTTON_CANCEL');
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			//layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}

		private function drawAdmForbid():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();

			message.text=SharedData.getInstance().getText('TEXT_ADMINISTRATIVELY_DISABLED');

			cancelButton.label=SharedData.getInstance().getText('BUTTON_CANCEL');
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			//layer.addChild(layerImg);
			layer.addChild(cancelButton);
			container.addChild(layer);
		}

		private function drawPrivacyNotice():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();

			messageFmt.font="Arial";
			messageFmt.size=14;
			messageFmt.color=0xffffff;
			messageFmt.bold=false;
			message.defaultTextFormat=messageFmt;

			message.text=localizationBundle['TEXT_PRIVACY_RIGHTS_EXPLAIN'];
			message.width=layer.width * 0.65;
			message.y=(layer.height-message.height)/2;
			message.wordWrap=true;
			
			var layerImg:MicImage = new MicImage();

			var scaleY:Number=(layer.width * 0.3) / layerImg.height;
			var scaleX:Number=(layer.width * 0.3) / layerImg.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

			layerImg.width*=scaleC;
			layerImg.height*=scaleC;	

			//Shapes can have offsets in their local coordinate system. We use get getRect() against themselves to get the offset and then we scale it accordingly.
			//Doing this we put the shape in the (0,0) point of its parent container.
			var layerImgOffsetX:Number = (scaleC*layerImg.getRect(layerImg).x);
			var layerImgOffsetY:Number = (scaleC*layerImg.getRect(layerImg).y);
			
			layerImg.x = -layerImgOffsetX + (layer.width - layerImg.width) - (layer.width * 0.3 - layerImg.width) / 2;
			layerImg.y = -layerImgOffsetY + (layer.height - layerImg.height) / 2;

			acceptButton.label=SharedData.getInstance().getText('BUTTON_SHOW_PRIVACY_SETTINGS');
			acceptButton.addEventListener(MouseEvent.CLICK, acceptClickHandler);
			acceptButton.y=layer.height * 0.9;
			cancelButton.label=SharedData.getInstance().getText('BUTTON_CANCEL');
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);
			cancelButton.x=acceptButton.width + 20;
			cancelButton.y=layer.height * 0.9;

			layer.addChild(message);
			layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}
		
		/*
		 * Methods to deal with user interaction
		 */
		public function displaySettings():void
		{
			privacyManager=SharedData.getInstance().privacyManager;
			privacyManager.addEventListener(PrivacyEvent.DEVICE_STATE_CHANGE, deviceStateChangeHandler);
			privacyManager.initDevices();
		}
		
		private function deviceStateChangeHandler(event:PrivacyEvent):void
		{
			switch (event.state)
			{
				case PrivacyEvent.AV_HARDWARE_DISABLED:
				{
					drawAdmForbid();
					break;
				}
				case PrivacyEvent.NO_MICROPHONE_FOUND:
				{
					drawMicNotFound();
					break;
				}
				case PrivacyEvent.NO_CAMERA_FOUND:
				{
					drawCamNotFound();
					break;
				}
				case PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED:
				{
					drawPrivacyNotice2("SELECT_ALLOW");
					//drawPrivacyNotice();
					//acceptClickHandler(null);
					break;
				}
				case PrivacyEvent.DEVICE_ACCESS_GRANTED:
				{
					drawPrivacyNotice2("NOW_CLICK_REMEMBER");
					//acceptButton.label=ResourceManager.getInstance().getString('messages', 'BUTTON_RECORD');
					//drawPrivacyNotice();
					//acceptButton.label=SharedData.getInstance().getText('BUTTON_RECORD');
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
			privacyManager.initDevices();
		}
		
		private function cancelClickHandler(event:MouseEvent):void
		{
			dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE_CANCEL));
		}
		
		private function acceptClickHandler(event:MouseEvent):void
		{
			if (!SharedData.getInstance().privacyManager.deviceAccessGranted)
				privacyManager.showPrivacySettings();
			else
				dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE_ACCEPT));
		}
	}
}
