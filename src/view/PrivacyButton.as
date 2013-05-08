package view
{
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;

	public class PrivacyButton extends Sprite
	{
		private var defWidth:uint=100;
		private var defHeight:uint=30;

		private var btn:SimpleButton=new SimpleButton();

		private var upTxt:TextField=new TextField();
		private var overTxt:TextField=new TextField();
		private var downTxt:TextField=new TextField();
		private var tf:TextFormat=new TextFormat();

		private var upBg:Sprite=new Sprite();
		private var overBg:Sprite=new Sprite();
		private var downBg:Sprite=new Sprite();

		private const BG_FILL_UPSTATE:Array=[0xFFFFFF, 0xD8D8D8];
		private const BG_FILL_OVERSTATE:Array=[0xBBBDBD, 0x9FA0A1];
		private const BG_FILL_DOWNSTATE:Array=[0xAAAAAA, 0x929496];

		private const LABEL_FILL_UPSTATE:uint=0xFFFFFF;
		private const LABEL_FILL_OVERSTATE:uint=0x000000;
		private const LABEL_FILL_DOWNSTATE:uint=0x000000;

		//private const ALPHAS:Array=[0.85, 0.85];
		private const ALPHAS:Array=[0,0];
		private const RATIOS:Array=[127, 255];
		
		private const LINE_COLOR:uint = 0xFFFFFF;
		private const LINE_THICKNESS:uint = 1;
		private const LINE_ALPHA:Number = 1.0;

		public function PrivacyButton()
		{
			super();

			tf.color=LABEL_FILL_UPSTATE;
			tf.font="Arial";
			tf.size=20;
			tf.align="center";
			upTxt.defaultTextFormat=tf;
			overTxt.defaultTextFormat=tf;
			downTxt.defaultTextFormat=tf;
			updateChildren(defWidth, defHeight);
		}

		public function updateChildren(newWidth:uint, newHeight:uint):void
		{
			var matr:Matrix=new Matrix();
			matr.createGradientBox(newHeight, newHeight, 90 * Math.PI / 180, 0, 0);

			upBg.graphics.clear();
			upBg.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
			upBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_UPSTATE, ALPHAS, RATIOS, matr);
			upBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, 8, 8);
			upBg.graphics.endFill();

			overBg.graphics.clear();
			overBg.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
			overBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_OVERSTATE, ALPHAS, RATIOS, matr);
			overBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, 8, 8);
			overBg.graphics.endFill();

			downBg.graphics.clear();
			downBg.graphics.lineStyle(LINE_THICKNESS, LINE_COLOR, LINE_ALPHA);
			downBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_DOWNSTATE, ALPHAS, RATIOS, matr);
			downBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, 8, 8);
			downBg.graphics.endFill();

			upBg.addChild(upTxt);
			overBg.addChild(overTxt);
			downBg.addChild(downTxt);

			btn.upState=upBg;
			btn.overState=overBg;
			btn.downState=downBg;
			btn.useHandCursor=true;
			btn.hitTestState=overBg;

			addChild(btn);
		}

		public function get label():String
		{
			return upTxt.text;
		}

		public function set label(text:String):void
		{
			upTxt.text=overTxt.text=downTxt.text=text;
			var nWidth:uint=upTxt.textWidth < (defWidth - 20) ? defWidth : upTxt.textWidth + 20;
			upTxt.width=overTxt.width=downTxt.width=nWidth;
			upTxt.height=overTxt.height=downTxt.height=defHeight;
			updateChildren(nWidth, defHeight);
		}
	}
}
