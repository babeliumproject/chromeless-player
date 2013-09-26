package view
{
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	
	import model.SharedData;
	
	public class ErrorOverlay extends Sprite
	{
		
		private var dWidth:uint = 640;
		private var dHeight:uint = 480;

		private var box:Shape;
		private var message:TextField;
		
		private var backgrImg:Bitmap;
		
		public function ErrorOverlay()
		{
			super();
			//loadAsset(StreamingManager.getInstance().uploadDomain+"resources/images/popup_bgr_wrong.png");
			updateChildren(dWidth,dHeight);
			
		}
		
		public function updateChildren(nWidth:Number, nHeight:Number):void{
			
			var nWidthBox:Number = nWidth*0.85;
			var nHeightBox:Number = nHeight*0.6;
			if(box != null && this.contains(box))
				this.removeChild(box);
			if(backgrImg != null && this.contains(backgrImg))
				this.removeChild(backgrImg);
			if(message != null && this.contains(message))
				this.removeChild(message);
			
			this.graphics.clear();
			this.graphics.beginFill(0x000000,1);
			this.graphics.drawRect(0,0,nWidth,nHeight);
			this.graphics.endFill();		
			
			box = new Shape();
			var matr:Matrix = new Matrix();
			matr.createGradientBox(nWidthBox, nHeightBox, 90*Math.PI/180, 0, 0);
			box.graphics.clear();
			box.graphics.beginGradientFill(GradientType.LINEAR, [0xF5F5F5,0xE6E6E6], [1,1],[120,255],matr);
			box.graphics.lineStyle(1, 0xa7a7a7);
			box.graphics.drawRect(nWidth/2-(nWidthBox/2),nHeight/2-(nHeightBox/2),nWidthBox,nHeightBox);
			
			box.graphics.endFill();
			
			var _textFormat:TextFormat = new TextFormat();
			_textFormat.align = "center";
			_textFormat.font = "Arial";
			_textFormat.bold = true;
			_textFormat.size = 14;
			
			message = new TextField();
			message.text = SharedData.getInstance().localizationBundle["NO_CONNECTION"] ? SharedData.getInstance().localizationBundle["NO_CONNECTION"] : "Communication lost. Trying to reconnect...";
			message.selectable = false;
			message.autoSize = TextFieldAutoSize.CENTER;
			message.x = nWidth/2 - message.textWidth/2;
			message.y = nHeight/2 - message.textHeight/2;
			message.setTextFormat(_textFormat);
			
			this.addChild(box);
			this.addChild(message);
			
			if(backgrImg){
				backgrImg.width=191;
				backgrImg.height=192;
				backgrImg.x = (nWidth/2) + (nWidthBox/2) - backgrImg.width;
				backgrImg.y = (nHeight/2)-(nHeightBox/2);
				this.addChild(backgrImg);
			}
		}
		
		private function loadAsset(url:String):void{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			var request:URLRequest = new URLRequest(url);
			loader.load(request);
		}
		
		private function completeHandler(event:Event):void{
			var loader:Loader = Loader(event.target.loader);
			backgrImg = Bitmap(loader.content);
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void{
			trace("Unable to load image: " + event);
		}
		
		
	}
}