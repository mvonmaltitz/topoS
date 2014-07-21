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
  (*Change your system config here*)
  val (executable_dot: string, executable_pdf_viewer: string) = (
            case getenv "ISABELLE_PLATFORM_FAMILY" of 
                   "linux" => ("dot", getenv "PDF_VIEWER")
                 | "macos" => ("dot", getenv "PDF_VIEWER")
                 | "windows" => (warning "GRAPHVIZ_PLATFORM_CONFIG: never tested on windows"; ("dot", getenv "PDF_VIEWER"))
                 | _ => raise Fail "cannot determine operating system"
            );
  
  local
    fun check_executable e =
      if Isabelle_System.bash ("which "^e) = 0 then
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
