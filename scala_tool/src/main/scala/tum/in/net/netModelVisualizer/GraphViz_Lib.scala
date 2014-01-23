package tum.in.net.netModelVisualizer

import tum.in.net.psn.log_topo.NetworkModels.{NetGraph}
import tum.in.net.StringNode._


/**
 * Base class for GraphViz related stuff
 * 
 * Always extend from this!
 */
protected abstract class GraphVizBase(val graph: NetGraph){
  final protected def goodNodeName(node: Node): Boolean = {
    val goodChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    node.forall(goodChars.contains(_))
  }
  
  private def warnOnNodeNames(): Unit = {
    for (n <- graph.nodes){
      if(!goodNodeName(n))
        println("Warning: This node name may crash the Graphviz backend: `"+n+"'")
    }
  }
  warnOnNodeNames()
  
  
  /** write warnings to here. extend this string! **/
  protected var global_warnings = ""
  
  /**
   * generate the label to add a node
   * returns: (header, footer)
   */
  final protected def addNode_generateLabel(name: Node): (String, String) = {
    val hdr = name+"""[label=<<TABLE BORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD CELLPADDING="2">"""+
      """<FONT face="Verdana Bold">"""+name+"""</FONT></TD></TR>"""
    val footer = ("""</TABLE>>]"""+"\n\n")
    
    (hdr, footer)
  }
  
  /**
   * generate the string of a node definition
   * override this to add additional parameters to the node
   */
  protected def addNode(name: Node): String = {
    val (hdr, footer) = addNode_generateLabel(name)
    hdr+footer
  }
  
  /**
   * list all nodes
   */
  protected def listNodes(nodes: List[Node]): String = {
    nodes.foldRight(""){(n, ns) => addNode(n) + ns }
  }
  
  /**
   * generate the label for an edge
   * override candidate
   * List(a,b,c) will be used as [a, b, c]
   * List() will be used as empty string
   */
  protected def addEdge_generateLabel(e1: Node, e2: Node): List[String] = {
    List()
  }
  
  /**
   * generate the string describing an edge
   */
  final protected def addEdge(e1: Node, e2: Node): String = {
    val edgeLabel = addEdge_generateLabel(e1, e2) match {
      case Nil => ""
      case l => "["+l.mkString(", ")+"]"
    }
    
    e1+" -> "+e2+edgeLabel+"\n"
  }
  
  /**
   * list all edges
   */
  final protected def listEdges(edges: List[(Node,Node)]): String = {
    if (edges.isEmpty) "" else addEdge(edges.head._1, edges.head._2) + listEdges(edges.tail)
  }
  
}

/**
 * the GraphViz render backends
 */
protected object RenderBackends {
  abstract sealed class GraphVizRenderBackend {val cmd: String}
  case object Dot extends GraphVizRenderBackend{override val cmd = "dot"}
  case object Neato extends GraphVizRenderBackend{override val cmd = "neato"}
  case object Circo extends GraphVizRenderBackend{override val cmd = "circo"}
}


/**
 * write the .dot file to file
 * render by graphviz in $PATH
 * start pdf viewer
 */
trait GraphViz_RenderView{
  import util.PDFviewer

  
  /** temp file header magic **/
  private val magic = "/* tmpfile magic 82dsa32Udh2NetworkSecurityModelling autogenerated */"
  
  /** the temp-file we write to **/
  private final val tmpfile = if (System.getProperty("os.name").toLowerCase.contains("windows"))
      "tmp\\mygraph"
    else
      "/tmp/mygraph"
    
  /**
   * write to file, add magic header
   */
  private def toFileMagic(fileName: String, content: String):Unit = {
    val file = new java.io.File(fileName)
    if (file.exists) {
      def firstLine(f: java.io.File): Option[String] = {
        val src = io.Source.fromFile(f)
        try {
          src.getLines.find(_ => true)
        } finally {
          src.close()
        }
      }
      println("File "+fileName+" already exists")
      if (firstLine(file) == Some(magic)) {
        println("known file")
      } else {
        println("unknown file, do not dare to overwrite it")
        throw new RuntimeException
      }
    }
    val writer = try{
      new java.io.PrintWriter(file)
    } catch {
      case e: java.io.FileNotFoundException => println(e)
        println("If you're in windows, 'mkdir tmp' in your cdw")
        throw e
    }
    writer.write(magic+"\n"+content)
    writer.close()
    
    println("Output written to "+fileName)
  }
  
  /**
   * write .dot file 
   */
  private def graphToDOT(fileName: String, graphvizString: String) = {
    toFileMagic(fileName+".dot", graphvizString)
  }
  

  /**
   * invoke the graphiz renderer as separate process
   */
  private def rendererToPDF(renderer: RenderBackends.GraphVizRenderBackend)(fileName: String) = {
    import scala.sys.process._
    val command = Seq(renderer.cmd, fileName+".dot", "-Tpdf", "-o", fileName+".pdf")
  val dotReturn = command.!
  if(dotReturn != 0) {
    println("Error running "+renderer+"!")
    println("Command was `"+command+"'")
    println(""+renderer+" returned :"+dotReturn)
    throw new RuntimeException
  }
  }
  
  

  
  /**
   * Write .dot file at `tmpfile`
   * Run graphviz rendering backend
   * Start PDFviewer
   * 
   * @params graph_descr graph description in Graph File language
   * See `man dot`
   */
  protected def displayGraphFromDescr(graph_descr: String, 
      renderer: RenderBackends.GraphVizRenderBackend = RenderBackends.Dot): Unit = 
  {  
    graphToDOT(tmpfile, graph_descr)
    
    val display = try{
      rendererToPDF(renderer)(tmpfile)
      true
    } catch {
      case e: java.io.IOException => println(e);println("Is graphviz installed and in $PATH ?"); false
    }
    if (display)
      PDFviewer.viewPDF(tmpfile)
  }
  
  
}



trait GraphViz_visualExtra extends GraphVizBase{
  
  private def verify_visual_extra(__visual_extra_in: Map[String, List[Node]]): Map[String, List[Node]] = {
    var valid = true
    val groupnodes = __visual_extra_in.values.flatten.toList
    if(groupnodes != groupnodes.distinct){
      val warning = "ERROR visual_extra: some nodes appear in multiple groups "+"\n"+
          (groupnodes diff groupnodes.distinct).toString+"\n"
      global_warnings += warning+"\n"
      println(warning)
      valid = false
    }
    for (groupnodes <- __visual_extra_in.values; groupnode <- groupnodes){
      if (!graph.nodes.contains(groupnode)){
        val warning = "ERROR visual_extra: node not in graph " + groupnode + "\n"
        global_warnings += warning+"\n"
        println(warning)
        valid = false
      }
    }
    if(!valid){
      println("visual extra: "+__visual_extra_in)
      Map()
    }else
      __visual_extra_in
  }
  
  private var visual_extra: Map[String, List[Node]] = null
  
  protected def visualExtra_initialize(__visual_extra_in: Map[String, List[Node]]): Unit = {
    visual_extra = verify_visual_extra(__visual_extra_in)
  }
  
  /**
   * list a node group, specified in visual extra
   */
  private def listNodesGroup(nodes: List[Node], groupname: String): String = {
    def iter(ns: List[Node]):String = if (ns.isEmpty) "" else "  "+addNode(ns.head) + iter(ns.tail)
    
    if (nodes.isEmpty) "" else "subgraph cluster_"+groupname+" {" + "\n" + 
      iter(nodes) + """label=""""+groupname+"""";"""+"\n}\n\n"
  }
  
  /**
   * list node groups first
   * list the rest as usual
   */
  override protected def listNodes(nodes: List[Node]): String = {
    
    if(visual_extra eq null){
      println("you need to call initialize if you mix in visual_extra)")
      throw new UninitializedError
    }
    
    val groups = for (group <- visual_extra.keys) yield listNodesGroup(visual_extra(group), group)
    val rest = nodes.diff(visual_extra.values.flatten.toList)
    groups.mkString("\n\n") + super.listNodes(rest)
  }
  
}
