package view
{
	import assets.DefaultStyle;
	
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
		private var defWidth:uint=60;
		private var defHeight:uint=20;

		private var btn:SimpleButton=new SimpleButton();

		private var upTxt:TextField=new TextField();
		private var overTxt:TextField=new TextField();
		private var downTxt:TextField=new TextField();
		private var tf:TextFormat=new TextFormat();

		private var upBg:Sprite=new Sprite();
		private var overBg:Sprite=new Sprite();
		private var downBg:Sprite=new Sprite();

		public function PrivacyButton()
		{
			super();

			tf.color=DefaultStyle.PRIVACY_BUTTON_FONT_COLOR_UPSTATE;
			tf.font=DefaultStyle.FONT_FAMILY;
			tf.size=DefaultStyle.FONT_SIZE;
			tf.align=DefaultStyle.FONT_ALIGN;
			upTxt.defaultTextFormat=tf;
			overTxt.defaultTextFormat=tf;
			downTxt.defaultTextFormat=tf;
			updateChildren(defWidth, defHeight);
		}

		public function updateChildren(newWidth:uint, newHeight:uint):void
		{
			removeChildren();
			
			var matr:Matrix=new Matrix();
			matr.createGradientBox(newHeight, newHeight, 90 * Math.PI / DefaultStyle.BGR_GRADIENT_ANGLE_DEC, 0, 0);

			upBg.graphics.clear();
			upBg.graphics.lineStyle(DefaultStyle.PRIVACY_BUTTON_LINE_THICKNESS, DefaultStyle.PRIVACY_BUTTON_LINE_COLOR_UPSTATE, DefaultStyle.PRIVACY_BUTTON_LINE_ALPHA);
			upBg.graphics.beginGradientFill(DefaultStyle.BGR_GRADIENT_TYPE, DefaultStyle.PRIVACY_BUTTON_BGR_GRADIENT_COLORS_UPSTATE, DefaultStyle.PRIVACY_BUTTON_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, matr);
			upBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS);
			upBg.graphics.endFill();

			overBg.graphics.clear();
			overBg.graphics.lineStyle(DefaultStyle.PRIVACY_BUTTON_LINE_THICKNESS, DefaultStyle.PRIVACY_BUTTON_LINE_COLOR_OVERSTATE, DefaultStyle.PRIVACY_BUTTON_LINE_ALPHA);
			overBg.graphics.beginGradientFill(DefaultStyle.BGR_GRADIENT_TYPE, DefaultStyle.PRIVACY_BUTTON_BGR_GRADIENT_COLORS_OVERSTATE, DefaultStyle.PRIVACY_BUTTON_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, matr);
			overBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS);
			overBg.graphics.endFill();

			downBg.graphics.clear();
			downBg.graphics.lineStyle(DefaultStyle.PRIVACY_BUTTON_LINE_THICKNESS, DefaultStyle.PRIVACY_BUTTON_LINE_COLOR_DOWNSTATE, DefaultStyle.PRIVACY_BUTTON_LINE_ALPHA);
			downBg.graphics.beginGradientFill(DefaultStyle.BGR_GRADIENT_TYPE, DefaultStyle.PRIVACY_BUTTON_BGR_GRADIENT_COLORS_DOWNSTATE, DefaultStyle.PRIVACY_BUTTON_ALPHAS, DefaultStyle.PRIVACY_BUTTON_RATIOS, matr);
			downBg.graphics.drawRoundRect(0, 0, newWidth, newHeight, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS, DefaultStyle.PRIVACY_BUTTON_CORNER_RADIUS);
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
