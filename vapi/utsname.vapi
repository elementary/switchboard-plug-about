namespace Posix {
	[CCode (cname = "struct utsname", cheader_filename = "sys/utsname.h", has_type_id = false)]
	[SimpleType]
	public struct UtsName {
		public unowned string sysname;
		public unowned string nodename;
		public unowned string release;
		public unowned string version;
		public unowned string machine;
		[CCode (cname = "uname")]
		public static void get_default (out unowned UtsName name);
	}
}
