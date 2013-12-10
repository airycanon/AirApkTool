package
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Sprite;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.IDataInput;
	
	public class ExecutableJar extends Sprite
	{
		private var process:NativeProcess;
		
		private var javaFile:File;
		
		private var _result:Function;
		
		public function ExecutableJar()
		{
			process = new NativeProcess();
		}
		
		/**
		 * 检测Java环境 
		 * @param result
		 */		
		public function check(result:Function):void
		{
			_result = result;
			
			var exeFile:File = File.applicationDirectory.resolvePath("JavaPath");
			execute(exeFile,null,getJavaPathHandler);
		}
		
		private function getJavaPathHandler(message:String):void
		{
			try
			{
				var javaPath:File = new File(message.replace(/\n/g,""));
				if(javaPath.isDirectory)
				{
					javaFile = javaPath.resolvePath("bin/javaw.exe");
					_result.call(null,javaFile.exists);
				}
			}
			catch(error:Error)
			{
				_result.call(null,false);
			}
		}
		
		
		/**
		 * 签名apk 
		 * @param target 目标文件，后缀为apk。
		 */		
		public function sign(target:File):void
		{
			var jarFile:File = File.applicationDirectory.resolvePath("sign/signapk.jar");
			var pemFile:File = File.applicationDirectory.resolvePath("sign/platform.x509.pem");
			var pk8File:File = File.applicationDirectory.resolvePath("sign/platform.pk8");
			
			var arguments:Vector.<String> = new Vector.<String>();
			arguments.push("-jar");
			arguments.push(jarFile.nativePath);
			arguments.push(pemFile.nativePath);
			arguments.push(pk8File.nativePath);
			arguments.push(target.nativePath);
			
			var newFile:File = target.parent.resolvePath(target.name.replace(".apk","_signed.apk"));
			arguments.push(newFile.nativePath);
			
			execute(javaFile,arguments);
		}
		
		/**
		 * 反编译class.dex 
		 * @param target 目标文件。
		 * @param folder 反编译后的文件夹。
		 */		
		public function decode(target:File,folder:File):void
		{
			var jarFile:File = File.applicationDirectory.resolvePath("smali/baksmali.jar");
			
			var arguments:Vector.<String> = new Vector.<String>();
			arguments.push("-jar");
			arguments.push(jarFile.nativePath);
			arguments.push(target.nativePath);
			arguments.push("-o");
			arguments.push(folder.nativePath);
			
			execute(javaFile,arguments);
		}
		
		/**
		 * 编译生成class.dex 
		 * @param target 编译后生成的文件。
		 * @param folder 要编译的目标文件夹。
		 */		
		public function encode(target:File,folder:File):void
		{
			var jarFile:File = File.applicationDirectory.resolvePath("smali/smali.jar");
			
			var arguments:Vector.<String> = new Vector.<String>();
			arguments.push("-jar");
			arguments.push(jarFile.nativePath);
			arguments.push(folder.nativePath);
			arguments.push("-o");
			arguments.push(target.nativePath);
			
			execute(javaFile,arguments);
		}
		
		/**
		 * 执行指定的exe文件 
		 * @param exeFile exe文件。
		 * @param arguments 命令行参数。
		 * @param outPut 返回数据时的回调函数。
		 * @param exit 退出时的回调函数。
		 * @see flash.desktop.NativeProcess
		 */		
		public function execute(exeFile:File,arguments:Vector.<String> = null,outPut:Function = null,exit:Function = null):void
		{
			if(exeFile.exists)
			{
				var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				info.executable = exeFile;
				info.arguments = arguments;
				if(null != outPut)
				{
					process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,function(event:ProgressEvent):void
					{
						var data:IDataInput = event.target.standardOutput as IDataInput;
						if(data)
						{
							outPut.call(null,data.readMultiByte(data.bytesAvailable,"iso-8859-01"));
						}
					});
				}
				if(null != exit)
				{
					process.addEventListener(NativeProcessExitEvent.EXIT,function(event:NativeProcessExitEvent):void
					{
						exit.call();
					});
				}
				process.start(info);
			}
		}
		
	}
}