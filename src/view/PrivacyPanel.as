package view
{
	import assets.MicImage;
	import assets.UnlockImage;
	
	import events.PrivacyEvent;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import model.SharedData;
	
	import mx.resources.IResourceManager;
	import mx.resources.ResourceManager;
	
	import media.PrivacyManager;
	import media.NetConnectionClient;

	public class PrivacyPanel extends Sprite
	{
		private var dWidth:uint=640;
		private var dHeight:uint=480;

		private var title:TextField=new TextField();
		private var titleFmt:TextFormat=new TextFormat();

		private var container:Sprite=new Sprite();
		private var containerBgImg:UnlockImage=new UnlockImage();

		private var layer:Sprite=new Sprite();
		private var layerImg:MicImage=new MicImage();
		private var message:TextField=new TextField();

		private var acceptButton:PrivacyButton=new PrivacyButton();
		private var cancelButton:PrivacyButton=new PrivacyButton();

		private var privacyManager:PrivacyManager;

		public function PrivacyPanel()
		{
			super();
			drawBackground(dWidth, dHeight);
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

		public function updateDisplayList(nWidth:uint, nHeight:uint):void
		{
			drawBackground(nWidth, nHeight);
		}

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
					drawPrivacyNotice();
					break;
				}
				case PrivacyEvent.DEVICE_ACCESS_GRANTED:
				{
					//acceptButton.label=ResourceManager.getInstance().getString('messages', 'BUTTON_RECORD');
					drawPrivacyNotice();
					acceptButton.label="Record";
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
			dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE));
		}

		private function acceptClickHandler(event:MouseEvent):void
		{
			if (!SharedData.getInstance().privacyManager.deviceAccessGranted)
				privacyManager.showPrivacySettings();
			else
				dispatchEvent(new PrivacyEvent(PrivacyEvent.CLOSE));
		}

		private function drawBackground(nWidth:uint, nHeight:uint, padding:uint=30, gap:uint=2):void
		{
			this.graphics.clear();
			this.graphics.beginFill(0x000000, 0.75);
			this.graphics.drawRect(0, 0, nWidth, nHeight);
			this.graphics.endFill();

			titleFmt.font="Arial";
			titleFmt.color=0xFFFFFF;
			titleFmt.size=18;
			titleFmt.bold=true;
			title.defaultTextFormat=titleFmt;
			title.text="Privacy Settings";
			//title.text=ResourceManager.getInstance().getString('messages','TITLE_PRIVACY_SETTINGS').toUpperCase();
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
			layer.graphics.beginFill(0, 0);
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
			//message.text=ResourceManager.getInstance().getString('messages', 'TEXT_MIC_NOT_FOUND');
			message.text="Your microphone device couldn't be detected. Please make sure the device is correctly plugged and then click 'Retry' or click 'Cancel' to abort the recording.";

			//acceptButton.label=ResourceManager.getInstance().getString('messages','BUTTON_RETRY');
			acceptButton.label="Retry";
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			//cancelButton.label=ResourceManager.getInstance().getString('messages','BUTTON_CANCEL');
			cancelButton.label="Cancel";
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}

		private function drawCamNotFound():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();

			//message.text=ResourceManager.getInstance().getString('messages', 'TEXT_CAMERA_NOT_FOUND');
			message.text="Your camera device couldn't be detected. Please make sure the device is correctly plugged and then click 'Retry' or click 'Cancel' to abort the recording.";
			//acceptButton=ResourceManager.getInstance().getString('messages','BUTTON_RETRY');
			acceptButton.label="Retry";
			acceptButton.addEventListener(MouseEvent.CLICK, retryClickHandler);
			//cancelButton.label=ResourceManager.getInstance().getString('messages','BUTTON_CANCEL');
			cancelButton.label="Cancel";
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}

		private function drawAdmForbid():void
		{
			layer.removeChildren();

			var message:TextField=new TextField();
			var messageFmt:TextFormat=new TextFormat();

			//message.text=ResourceManager.getInstance().getString('messages', 'TEXT_ADMINISTRATIVELY_DISABLED');
			message.text="An administrative rule forbids the access to camera and microphone. Please contact your system administrator.";

			//cancelButton.label=ResourceManager.getInstance().getString('messages','BUTTON_CANCEL');
			cancelButton.label="Cancel";
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);

			layer.addChild(message);
			layer.addChild(layerImg);
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
			messageFmt.color=0x000000;
			messageFmt.bold=false;
			message.defaultTextFormat=messageFmt;

			//message.text=ResourceManager.getInstance().getString('messages', 'TEXT_PRIVACY_RIGHTS_EXPLAIN');
			message.text="Please click 'Allow' when you see this window. Also click on 'Remember' to skip this step the next time you want to record something.";
			message.width=layer.width * 0.65;
			message.y=(layer.height-message.height)/2;
			message.wordWrap=true;

			var scaleY:Number=(layer.width * 0.3) / layerImg.height;
			var scaleX:Number=(layer.width * 0.3) / layerImg.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

			layerImg.width*=scaleC;
			layerImg.height*=scaleC;

			layerImg.x=layer.width - layerImg.width - (layer.width * 0.3 - layerImg.width) / 2;
			layerImg.y=(layer.height - layerImg.height) / 2;

			//acceptButton.label=ResourceManager.getInstance().getString('messages','BUTTON_SHOW_PRIVACY_SETTINGS');
			acceptButton.label="Show Privacy Settings";
			acceptButton.addEventListener(MouseEvent.CLICK, acceptClickHandler);
			acceptButton.y=layer.height * 0.9;
			//cancelButton.label=ResourceManager.getInstance().getString('messages','BUTTON_CANCEL');
			cancelButton.label="Cancel";
			cancelButton.addEventListener(MouseEvent.CLICK, cancelClickHandler);
			cancelButton.x=acceptButton.width + 20;
			cancelButton.y=layer.height * 0.9;

			layer.addChild(message);
			layer.addChild(layerImg);
			layer.addChild(acceptButton);
			layer.addChild(cancelButton);
		}
	}
}
