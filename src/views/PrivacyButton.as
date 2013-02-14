package views
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

		private var txt:TextField=new TextField();
		private var tf:TextFormat=new TextFormat();

		private var upBg:Sprite=new Sprite();
		private var overBg:Sprite=new Sprite();
		private var downBg:Sprite=new Sprite();

		private const BG_FILL_UPSTATE:Array=[0xFFFFFF, 0xD8D8D8];
		private const BG_FILL_OVERSTATE:Array=[0xBBBDBD, 0x9FA0A1];
		private const BG_FILL_DOWNSTATE:Array=[0xAAAAAA, 0x929496];

		private const LABEL_FILL_UPSTATE:uint=0x000000;
		private const LABEL_FILL_OVERSTATE:uint=0x000000;
		private const LABEL_FILL_DOWNSTATE:uint=0x000000;

		private const ALPHAS:Array=[0.85, 0.85];
		private const RATIOS:Array=[127, 255];

		public function PrivacyButton()
		{
			super();

			tf.color=LABEL_FILL_UPSTATE;
			tf.font="Arial";
			tf.size=20;
			tf.align="center";
			txt.defaultTextFormat=tf;
			updateChildren(defWidth, defHeight);
		}

		public function updateChildren(newWidth:uint, newHeight:uint):void
		{
			var matr:Matrix=new Matrix();
			matr.createGradientBox(newHeight, newHeight, 90 * Math.PI / 180, 0, 0);

			upBg.graphics.clear();
			upBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_UPSTATE, ALPHAS, RATIOS, matr);
			upBg.graphics.drawRect(0, 0, newWidth, newHeight);
			upBg.graphics.endFill();

			overBg.graphics.clear();
			overBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_OVERSTATE, ALPHAS, RATIOS, matr);
			overBg.graphics.drawRect(0, 0, newWidth, newHeight);
			overBg.graphics.endFill();

			downBg.graphics.clear();
			downBg.graphics.beginGradientFill(GradientType.LINEAR, BG_FILL_DOWNSTATE, ALPHAS, RATIOS, matr);
			downBg.graphics.drawRect(0, 0, newWidth, newHeight);
			downBg.graphics.endFill();

			upBg.addChild(txt);
			//overBg.addChild(txt);
			//downBg.addChild(txt);

			btn.upState=upBg;
			btn.overState=overBg;
			btn.downState=downBg;
			btn.useHandCursor=true;
			btn.hitTestState=overBg;

			addChild(btn);
		}

		public function get label():String
		{
			return txt.text;
		}

		public function set label(text:String):void
		{
			txt.text=text;
			var nWidth:uint=txt.textWidth < (defWidth - 20) ? defWidth : txt.textWidth + 20;
			txt.width=nWidth;
			txt.height=defHeight;
			updateChildren(nWidth, defHeight);
		}
	}
}
