////////////////////////////////////////////////////////////////////////////////
//  zengrong.net
//  创建者:	zrong
//  创建时间：2011-04-23
////////////////////////////////////////////////////////////////////////////////
package org.zengrong.assets
{
import org.zengrong.display.spritesheet.SpriteSheet;
import org.zengrong.net.SpriteSheetLoader;
import org.zengrong.net.VisualLoader;
import org.zengrong.events.InfoEvent;

import flash.display.BitmapData;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;
import flash.events.EventDispatcher;

/**
 * 单例类，负责载入和解析外部资源。这些资源按zrong的习惯一般位于assets文件夹。
 * @author zrong
 */
[Event(name="complete",type="InfoEvent")]
[Event(name="info",type="InfoEvent")]
[Event(name="progress",type="InfoEvent")]

public class Assets extends EventDispatcher
{
	
	/**
	 * 载入全部完成
	 */
	public static const COMPLETE:String = 'complete';

	/**
	 * 载入过程中的信息，一般是错误信息
	 */
	public static const INFO:String = 'info';

	/**
	 * 载入进度
	 */
	public static const PROGRESS:String = 'progress';

	private static var _instance:Assets;
	
	private static var _fun_loadDone:Function;
	private static var _fun_loadInfo:Function;
	private static var _fun_loadProgress:Function;
	
	/**
	 * Assets是否已经初始化
	 */
	public static function get isInit():Boolean
	{
		return Boolean(_instance);
	}

	/**
	 * 获取instance的get方法，只是简单的调用getAssets，看你喜欢用哪种
	 */
	public static function get instance():Assets
	{
		return getAssets();
	}

	/**
	 * 获取instance的方法
	 */
	public static function getAssets():Assets
	{
		if(!_instance)
			_instance = new Assets(new Singlton);
		return _instance;
	}
	
	/**
	 * 设置Assets在载入外部资源的过程中的处理程序，第一个处理程序必须设定。
	 * @param $done 处理载入全部完毕的处理器，不需要参数
	 * @param $info 处理显示信息的处理器（载入过程中的任何错误和信息均通过这个处理器发送，参数为字符串）
	 * @param $progress 处理载入过程的处理器，参数为AssetsProgressVO
	 * 这个事件处理器，可以表示单个资源的载入流程，也可以表示整个列表的载入流程。
	 * 需要注意的是，代表列表的载入流程的事件，是从该资源开始载入的时候发出的。
	 * @see org.zengrong.assets.AssetsProgressVO
	 * */
	public static function setListener($done:Function, $info:Function=null, $progress:Function=null):void
	{
		_fun_loadDone = $done;
		_fun_loadInfo = $info;
		_fun_loadProgress = $progress;
	}
	
	public static function clear():void
	{
		_fun_loadDone = null;
		_fun_loadInfo = null;
		_fun_loadProgress = null;
		if(_instance)
		{
			_instance.destroy();
			_instance = null;
		}
	}
	
	public function Assets($sig:Singlton)
	{
		init();
	}
	
	private var _visualLoader:VisualLoader;	//载入可视文件的loader，对应FILE_VISUAL
	private var _ssLoader:SpriteSheetLoader; 	//载入SpriteSheet
	
	private var _urls:Array;			//保存所有需要载入的文件的路径
	private var _loadingCount:int;		//所有需要载入的外部资源的总数量
	private var _curFile:Object;		//保存正在载入的文件的相关信息
	private var _assets:Object;		//保存解析后的资源信息
	
	//----------------------------------
	//  init
	//----------------------------------
	private function init():void
	{
		_assets = {};
		_urls = [];
		_loadingCount = -1;
		
		_visualLoader = new VisualLoader();
		_visualLoader.addEventListener(Event.COMPLETE, handler_loaded);
		_visualLoader.addEventListener(IOErrorEvent.IO_ERROR, handler_ioError);
		_visualLoader.addEventListener(ProgressEvent.PROGRESS, handler_progress);
		
		_ssLoader = new SpriteSheetLoader();
		_ssLoader.addEventListener(Event.COMPLETE, handler_loaded);
		_ssLoader.addEventListener(IOErrorEvent.IO_ERROR, handler_ioError);
		_ssLoader.addEventListener(ProgressEvent.PROGRESS, handler_progress);
	}
	
	//----------------------------------
	//  getter/setter
	//----------------------------------
	/**
	 * 是否正在载入资源
	 */	
	public function get isLoading():Boolean
	{
		return _urls && (_urls.length > 0);
	}
	
	//----------------------------------
	//  public
	//----------------------------------
	/**
	 * 开始载入外部资源
	 * 外部素材的配置文件是一个Object数组，每个Object有5个值：
	 * <ul>
	 * 	<li>url（必须）：待载入文件的URL</li>
	 * 	<li>ftype（必须）：待载入文件的类型，可用值见AssetsType。</li>
	 * 	<li>symbols（可选/必选）：若载入的文件为AssetsType.SWF，则必须提供，否则不必提供。以字符串数组的方式提供所有需要的FLA库中的Symbol（CLASS）名称。</li>
	 * 	<li>fname（可选）：待载入的文件的键名，如果不提供，则使用文件的主文件名。fname的命名规则与变量命名规则相同。fname相同的文件不会被重复载入。
	 * 	<li>pic（可选）:若ftype值为AssetsType.SPRITE_SHEET时可用，若文件为标准图像文件（jpg、png），则传递true；若文件是ss文件，则传递false或不传递值。</li>
	 * 	<li>meta（可选）：若ftype值为AssetsType.SPRITE_SHEET，且pic值为true的时候提供，值为SpriteSheetPacker生成的XML格式元数据。如果不提供，且pic为true，就自动载入url同目录下的同名xml文件。</li>
	 * </ul>
	 * @param $urls 待载入的外部资源素材配置文件
	 * @see org.zengrong.display.assets.AssetsType
	 * @see org.zengrong.display.spritesheet.SpriteSheetType
	 * @see org.zengrong.display.net.SpriteSheetLoader
	 * */
	public function load($urls:Array):void
	{
		if(!_urls)
			throw new ReferenceError('请先初始化调用init方法初始化!');
		//如果正在载入，将要载入的数据压入数组，并更新数组总量
		if(isLoading)
		{
			_urls = _urls.concat($urls);
			//更新数组总量
			_loadingCount += $urls.length;
		}
		else
		{
			_urls = $urls;
			_loadingCount = _urls.length;
			loadAssets();
		}
	}
	
	public function destroy():void
	{
		if(_visualLoader)
		{
			_visualLoader.removeEventListener(Event.COMPLETE, handler_loaded);
			_visualLoader.removeEventListener(IOErrorEvent.IO_ERROR, handler_ioError);
			_visualLoader.removeEventListener(ProgressEvent.PROGRESS, handler_progress);
			_visualLoader = null;
		}
		if(_ssLoader)
		{
			_ssLoader.removeEventListener(Event.COMPLETE, handler_loaded);
			_ssLoader.removeEventListener(IOErrorEvent.IO_ERROR, handler_ioError);
			_ssLoader.removeEventListener(ProgressEvent.PROGRESS, handler_progress);
			_ssLoader = null;
		}
		//移除所有的资源
		for(var __key:String in _assets)
		{
			removeAssets(__key);
		}
		_assets = null;
		_urls = null;
		_curFile = null;
		_loadingCount = -1;
	}
	
	/**
	 * 从载入的资源中获取Class。只有SWF资源才能获取到Class。
	 * @param $name 资源的名称。如果在载入的时候没有明确指定，就是资源swf的主文件名部分
	 * @param $symbol 类名，即FLA库中绑定的类的名称
	 * @return FLA库中对应的类定义，如果没有找到或者类型错误，返回null。
	 */	
	public function getClass($name:String, $symbol:String):Class
	{
		if(_assets[$name])
			return _assets[$name][$symbol] as Class;
		return  null;
	}
	
	/**
	 * 从载入的资源中获取BitmapData。只有图像资源才能获取到BitmapData。
	 * @param $mame 资源的名称。如果在载入的时候没有明确指定，就是图像文件的主文件名部分
	 * @return 该图像文件的bitmapData数据。如果没有找到或者类型错误，返回null。
	 */	
	public function getBitmapData($name:String):BitmapData
	{
		return _assets[$name] as BitmapData;
	}
	
	/**
	 * 从载入的资源中获取SpriteSheet。只有SpriteSheet类型的资源才能获取到BitmapData。
	 * @param $mame 资源的名称。如果在载入的时候没有明确指定，就是图像文件的主文件名部分
	 * @return SpriteSheet对象。如果没有找到或者类型错误，返回null。
	 */	
	public function getSpriteSheet($name:String):SpriteSheet
	{
		return _assets[$name] as SpriteSheet;
	}

	/**
	 * 从资源库中移除对应的资源
	 */
	public function removeAssets($name:String):void
	{
		if($name in _assets)
		{
			var __ass:* = _assets[$name];
			if(__ass is SpriteSheet)
				SpriteSheet(__ass).destroy();
			else if(__ass is BitmapData)
				BitmapData(__ass).dispose();
			delete _assets[$name];
		}
	}

	/**
	 * 返回所有资源的名称数组
	 */
	public function getAssetsNames():Array
	{
		var __names:Array = [];
		for(var __name:String in _assets)
		{
			__names.push(__name);
		}
		return __names;
	}
	//--------------------------------------------------------------------------
	//  handler
	//--------------------------------------------------------------------------
	
	private function handler_ioError(evt:IOErrorEvent):void
	{
		info(evt.text);
		//碰到载入错误，继续载入
		loadAssets();
	}
	
	private function handler_loaded(evt:Event):void
	{
		saveAssets();
		loadAssets();
	}
	
	private function handler_progress(evt:ProgressEvent):void
	{
		var __vo:AssetsProgressVO = getProgressVO(ProgressEvent(evt).bytesLoaded,ProgressEvent(evt).bytesTotal);
		dispatchProgress(__vo);
	}
	
	//----------------------------------
	//  private
	//----------------------------------
	//发送载入进度的vo
	private function dispatchProgress($vo:AssetsProgressVO):void
	{
		this.dispatchEvent(new InfoEvent(PROGRESS, $vo));
		if(_fun_loadProgress is Function)
			_fun_loadProgress.call(null, $vo);
	}

	private function getProgressVO($loaded:int, $total:int, $whole:Boolean=false):AssetsProgressVO
	{
		var __vo:AssetsProgressVO = new AssetsProgressVO(_curFile);
		__vo.loaded = $loaded;
		__vo.total = $total;
		__vo.whole = $whole;
		return __vo;
	}
	
	private function loadAssets():void
	{
		if(_urls == null)
			throw new Error('找不到资源文件路径！');
		if(_urls.length > 0)
		{
			_curFile = _urls.shift();
			//如果没有提供fname，需要指定一个name
			if(!_curFile.fname)
			{
				//若没有提供fname，使用主文件名作为fname
				_curFile.fname = getMainFileName(_curFile.url);
			}
			//发送载入列表的百分比
			var __vo:AssetsProgressVO = getProgressVO(_loadingCount-_urls.length, _loadingCount, true);
			dispatchProgress(__vo);
			//如果要载入的资源已经存在于保存的资源中了，就跳过这个资源的载入，载入下一个资源
			//因为在分析要载入的资源阶段，可能有些资源是重复的（例如某些技能可能共享效果资源文件）
			if(_assets[_curFile.fname])
			{
				loadAssets();
				return;
			}
			info('正在载入:'+_curFile.url);
			//载入的外部资源是可视化资源
			if(	AssetsType.isVisual(_curFile.ftype) )
			{
				if(_curFile.ftype == AssetsType.SWF && !_curFile.symbols)
					throw new ReferenceError('对于SWF素材，必须提供symbols数组！');
				_visualLoader.load(_curFile.url, _curFile.ftype);
			}
			//载入的资源是SpriteSheet类型
			else if(_curFile.ftype == AssetsType.SPRITE_SHEET)
			{
				_ssLoader.load(_curFile.url, _curFile.pic, _curFile.meta);
			}
			else
				throw new RangeError('要载入的资源类型不符合要求！类型：'+_curFile.ftype+',URL:'+_curFile.url);
		}
		else
		{
			this.dispatchEvent(new InfoEvent(COMPLETE));
			if(_fun_loadDone is Function)
				_fun_loadDone.call();
			}
		}
		
		/**
		 * 将从外部获取到的可视对象保存在对象中备用
		 * */
		private function saveAssets():void
		{
		//如果载入的是swf，就获取symbol对象。将symbol的Class存在变量中
		if(_curFile.ftype == AssetsType.SWF)
		{
			var __swfSymbols:Object = new Object();
			for each(var __symbol:String in _curFile.symbols)
			{
				__swfSymbols[__symbol] = _visualLoader.getClass(__symbol);
			}
			_assets[_curFile.name] = __swfSymbols; 
		}
		//普通图片，直接保存BitmapData
		else if(AssetsType.isPic(_curFile.ftype))
		{
			_assets[_curFile.fname] = _visualLoader.getBitmapData();
		}
		else if(_curFile.ftype == AssetsType.SPRITE_SHEET)
		{
			_assets[_curFile.fname] = _ssLoader.getSpriteSheet();
		}
		else
		{
			throw new Error('载入完成的文件类型不被支持！类型：'+_curFile.ftype,',URL:'+_curFile.url);
		}
	}
	
	//获取URL中的主文件名
	private function getMainFileName($url:String):String
	{
		var __fileName:String = '';
		var __slashIndex:int = $url.lastIndexOf('/');
		var __dotIndex:int = $url.lastIndexOf('.');
		if(__slashIndex > -1)
		{
			if(__dotIndex>-1)
				__fileName = $url.slice(__slashIndex+1, __dotIndex);
			else
				__fileName =  $url.slice(__slashIndex+1);
		}
		else
		{
			if(__dotIndex>-1)
				__fileName =  $url.slice(0, __dotIndex);
			else
				__fileName =  $url;
		}
		return __fileName;
	}
	
	private function info($msg:String):void
	{
		this.dispatchEvent(new InfoEvent(INFO, $msg));
		if(_fun_loadInfo is Function)
			_fun_loadInfo.call(null, $msg);
	}
}
}
class Singlton{}
