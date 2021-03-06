package org.zengrong.display.character
{
import flash.display.BitmapData;
/**
 * Player和Monster的基类。
 * 在运动角色的基础上加入了Label功能，类似于MovieClip
 */
public class LabeledChar extends MovableChar
{

	public function LabeledChar()
	{
		super();
	}

	//当前正在显示的Label
	protected var _label:String;

	//以label为键名保存bmd列表
	protected var _labelsList:Object;

	//----------------------------------------
	// init
	//----------------------------------------
	
	override protected function init():void
	{
		super.init();
		_labelsList = {};
	}

	override public function destroy():void
	{
		super.destroy();
		_label = null;
		_labelsList = null;
	}

	//----------------------------------------		
	// getter/setter
	//----------------------------------------
	

	public function get isRun():Boolean
	{
		return _label == ActionLabel.RUN;
	}

	public function get isStand():Boolean
	{
		return _label == ActionLabel.STAND || _label == ActionLabel.STAND45;
	}
	/**
	 * 当前正在显示的Label
	 */
	public function get label():String
	{
		return _label;
	}

	/**
	 * 根据label的值更新图像列表
	 * @throw RangeError 如果提供的label不存在，抛出此异常
	 */
	public function set label($label:String):void
	{
		if($label == _label)
			return;
		_label = $label;
		//根据label更新图像列表
		if($label in _labelsList)
		{
			_bmds = getListByLabel($label);
			goto(0);
		}
		//else
		//	throw new RangeError('没有名为'+$label+'的label！');
	}	

	public function getListByLabel($label:String):Vector.<BitmapData>
	{
		return _labelsList[$label];
	}

	//----------------------------------------		
	// public
	//----------------------------------------
	
	public function addLabel($label:String, $bmds:Vector.<BitmapData>):void
	{
		_bmds = $bmds;
		_labelsList[$label] = _bmds;
		_bmds = null;
	}

	public function removeLabel($label:String):void
	{
		delete _labelsList[$label];
	}

	/**
	 * 清除所有的Label以及它们占用的内存
	 */
	public function removeAllLabel():void
	{
		for each(var __bmds:Vector.<BitmapData> in _labelsList)
		{
			_bmds = __bmds;
			this.removeAllFrame();
		}
		_labelsList = {};
	}

	/**
	 * 切换到奔跑状态
	 */
	override public function run():void
	{
		if(ActionLabel.RUN in _labelsList)
			this.label = ActionLabel.RUN;
		super.run();
	}

	/**
	 * 切换到站立状态
	 */
	override public function stand():void
	{
		if(isStand) return;
		if(ActionLabel.STAND in _labelsList)
			this.label = ActionLabel.STAND;
		super.stand();
	}

	/**
	 * 切换到45度站立状态
	 */
	public function stand45():void
	{
		if(isStand) return;
		if(ActionLabel.STAND45 in _labelsList)
			this.label = ActionLabel.STAND45;
		super.stand();
	}
}
}
