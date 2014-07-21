theory ML_GraphViz_Config
imports Main
begin

ML{*

signature GRAPHVIZ_PLATFORM_CONFIG =
sig
  val executable_dot: string;
  val executable_pdf_viewer: string;
end

structure Graphviz_Platform_Config: GRAPHVIZ_PLATFORM_CONFIG =
struct

  datatype platform = Linux | MacOs | Windows;
  local
    val platform_str = getenv "ML_PLATFORM";
  in
    val platform = if (String.isSuffix "linux" platform_str)
      then
        Linux
      else if String.isSuffix "darwin" platform_str
      then
        MacOs
      else if String.isSuffix "cygwin" platform_str
      then
        (warning "GRAPHVIZ_PLATFORM_CONFIG: never tested on windows"; Windows)
      else
        raise Fail "cannot determine operating system";
  end;
  
  (*Change your system config here*)
  val (executable_dot: string, executable_pdf_viewer: string) = (case platform of 
                   Linux => ("dot", getenv "PDF_VIEWER")
                 | MacOs => ("dot", getenv "PDF_VIEWER")
                 | Windows => ("dot", getenv "PDF_VIEWER"));
  
  local
    fun check_executable e =
      if Isabelle_System.bash ("which "^e) = 0 then (*TODO does `which` work on windows?*)
        () (* `which` already printed the path *)
      else 
       warning ("Command not available or not in $PATH: "^e);
  in
    val _ = check_executable executable_pdf_viewer;
    val _ = check_executable executable_dot;
  end

end
*}

end
