package tum.in.net.psn.log_topo

import NetworkModels.{NetGraph, NetworkModelAbstract}
import NetworkModels.NetworkModelList._
import tum.in.net.StringNode._


object FlowMatrix {

  /**
   * returns the flow matrix of the current graph.
   * Mainly internal function, you should know what you are doing if you call it
   */
  def create(graph: NetGraph): Array[Array[Boolean]] = {
    val size = graph.nodes.length
    val matrix: Array[Array[Boolean]] = new Array[Array[Boolean]](size)
    for (i_line <- 0 until matrix.length){
      val line = new Array[Boolean](size)
      matrix(i_line) = line
      for (j_column <- 0 until line.length){
        val flow = (graph.nodes(i_line), graph.nodes(j_column))
        val exists = (graph.edges contains flow)
        line(j_column) = exists
      }
    }
    matrix
  }
  
  /**
   * Convert some Flow matrix to some Flow matrix with printable string entries
   */
  def simpleStringRepr(matrix: Array[Array[Boolean]],
      contains: String, notContains: String): Array[Array[String]] = 
  {
    val newMatrix: Array[Array[String]] = new Array[Array[String]](matrix.size)
    
    for (i_line <- 0 until matrix.size){
      newMatrix(i_line) = matrix(i_line).map(e => if (e) contains else notContains)
    }
    
    newMatrix
  }
  
  
  /**
   * diff the two graphs g_old and g_new
   * The graph's nodes should be identical
   */
  def diffMatrix(g_old: NetGraph, g_new: NetGraph,
      both: String,
      newOnly: String,
      oldOnly: String,
      neither: String): Array[Array[String]] = 
  {
    require(g_old.nodes == g_new.nodes)

    val oldMatrix = FlowMatrix.create(g_old)
    val newMatrix  = FlowMatrix.create(g_new)
    
    println("generating diff matrix")
    assert(newMatrix.size == oldMatrix.size)
    
    val diffMatrix: Array[Array[String]] = new Array[Array[String]](newMatrix.size)
    
    for (i_line <- 0 until newMatrix.size){
      assert(newMatrix(i_line).size == oldMatrix.size)
      diffMatrix(i_line) = new Array[String](newMatrix(i_line).size)
    }
    
    for (i_line <- 0 until newMatrix.size; j_row <- 0 until newMatrix(i_line).size){
      val entry: String = if (oldMatrix(i_line)(j_row) && newMatrix(i_line)(j_row)) both else 
        if (!oldMatrix(i_line)(j_row) && newMatrix(i_line)(j_row)) newOnly else
        if (oldMatrix(i_line)(j_row) && !newMatrix(i_line)(j_row)) oldOnly else
        if (!oldMatrix(i_line)(j_row) && !newMatrix(i_line)(j_row)) neither else
          throw new RuntimeException("missing case")
      
      assert(entry.length > 0)
      diffMatrix(i_line)(j_row) = entry
    }
    
    diffMatrix
  }

//  /**
//   * input: a differential matrix, generated by generateDiffMatrix
//   *        Matrix string entries must be default!
//   */
//  // mapping of the matrix string entries to their meaning
//  abstract sealed class diffMatrixFields(val str: String)
//  case object Both extends diffMatrixFields(str = "  *  ")
//  case object NewOnly extends diffMatrixFields(str = "  _  ")
//  case object OldOnly extends diffMatrixFields(str = " X-X ")
//  case object Neither extends diffMatrixFields(str = "     ")
//  protected def diffMatrixUNUSEDFUNCTION(matrix: Array[Array[String]]): Array[Array[diffMatrixFields]] = {
//    def diffMatrixEntryToMeaning(s: String): diffMatrixFields = s match {
//      case Both.str => Both
//      case NewOnly.str => NewOnly
//      case OldOnly.str => OldOnly
//      case Neither.str => Neither
//    }
//    val myMatrix: Array[Array[diffMatrixFields]] = matrix.map(i => i.map(j => diffMatrixEntryToMeaning(j)))
//    myMatrix
//  }
  
}
