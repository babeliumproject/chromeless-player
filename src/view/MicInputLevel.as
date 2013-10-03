package view
{
	import assets.MicImage;
	
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.media.Microphone;
	import flash.utils.Timer;
	
	public class MicInputLevel extends Sprite
	{
		private var passiveIcon:Sprite;
		private var activeIcon:Sprite;
		private var maskIcon:Sprite;
		
		private var mic:Microphone;
		private var micTimer:Timer;
		
		private var dHeight:uint = 512;
		private var dWidth:uint = 512;
		
		public function MicInputLevel()
		{
			passiveIcon = new MicImage();
			activeIcon = new MicImage();
			
			this.addChild(passiveIcon);	
			colorizeGroup(passiveIcon, 0xb0b0b0);
			
			this.addChild(activeIcon);
			colorizeGroup(activeIcon, 0x7ea80c);
			
			maskIcon = new Sprite();
			// Draw a gradient for the mask
			var colors:Array = [0x000000, 0x000000]; 
			var alphas:Array = [1, 0]; 
			var ratios:Array = [0, 255];
			var angleDegrees:int = 270;
			var matrix:Matrix = new Matrix(); 
			matrix.createGradientBox(dWidth, dHeight, angleDegrees*Math.PI/180, 0, 0);
			maskIcon.graphics.clear();
			//maskIcon.graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, matrix);
			maskIcon.graphics.beginFill(0x000000,1);
			var level:uint = drawLevel();
			maskIcon.graphics.drawRect(0, dHeight-level, dWidth, level); 
			maskIcon.graphics.endFill(); 
			
			this.addChild(maskIcon); 
			
			activeIcon.mask = maskIcon;
			
			passiveIcon.cacheAsBitmap = true;
			activeIcon.cacheAsBitmap = true;
			maskIcon.cacheAsBitmap=true;
			

			this.addEventListener(Event.ENTER_FRAME, timerTick);
		}
		private function updateMask():void{
			
			// Draw a gradient for the mask
			var colors:Array = [0x000000, 0x000000]; 
			var alphas:Array = [1, 0]; 
			var ratios:Array = [0, 255];
			var angleDegrees:int = 270;
			var matrix:Matrix = new Matrix(); 
			matrix.createGradientBox(dWidth * 1.15, dHeight * 1.15, 0, 0, 0);
			maskIcon.graphics.clear();
			//maskIcon.graphics.beginGradientFill(GradientType.RADIAL, colors, alphas, ratios, matrix);
			maskIcon.graphics.beginFill(0x000000,1);
			var level:uint = drawLevel();
			maskIcon.graphics.drawRect(0, dHeight-level, dWidth, level); 
			maskIcon.graphics.endFill();
			maskIcon.cacheAsBitmap = true;
		}
		
		private function drawLevel():Number{
			if(mic && !mic.muted && mic.activityLevel){
				return dHeight * (mic.activityLevel/100);
			}else{
				return 0;
			}
		}
		
		private function colorizeGroup(instance:DisplayObject, color:uint):void {
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = color;
			instance.transform.colorTransform = colorTransform;
		}
		
		private function timerTick(event:Event):void {
			updateMask();
		}	
	}
}