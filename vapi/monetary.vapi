[CCode (cheader_filename = "monetary.h")]
public class Monetary {
     [CCode(cname = "strfmon")]
      public static ssize_t strfmon(char[] s, string format, double data);
}
