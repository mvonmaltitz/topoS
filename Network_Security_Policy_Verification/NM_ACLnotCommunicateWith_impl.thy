theory NM_ACLnotCommunicateWith_impl
imports NM_ACLnotCommunicateWith NetworkModel_Lists_Impl_Interface
begin

code_identifier code_module NM_ACLnotCommunicateWith_impl => (Scala) NM_ACLnotCommunicateWith


section {* NetworkModel ACLnotCommunicateWith List Implementation *}


fun eval_model :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> 'v set) \<Rightarrow> bool" where
  "eval_model G nP = (\<forall> v \<in> set (nodesL G). \<forall> a \<in> set (succ_tran G v). a \<notin> (nP v))"

fun verify_globals :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> 'v set) \<Rightarrow> unit \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"


definition "NetModel_node_props (P::('v::vertex, 'v set, 'b) NetworkModel_Params) = 
  (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> NM_ACLnotCommunicateWith.default_node_properties))"
lemma[code_unfold]: "NetworkModel.node_props NM_ACLnotCommunicateWith.default_node_properties P = NetModel_node_props P"
apply(simp add: NetModel_node_props_def)
done

definition "ACLnotCommunicateWith_offending_list = Generic_offending_list eval_model"

definition "ACLnotCommunicateWith_eval G P = (valid_list_graph G \<and> 
  verify_globals G (NetworkModel.node_props NM_ACLnotCommunicateWith.default_node_properties P) (model_global_properties P) \<and> 
  eval_model G (NetworkModel.node_props NM_ACLnotCommunicateWith.default_node_properties P))"


interpretation ACLnotCommunicateWith_impl:NetworkModel_List_Impl 
  where default_node_properties=NM_ACLnotCommunicateWith.default_node_properties
  and eval_model_spec=NM_ACLnotCommunicateWith.eval_model
  and eval_model_impl=eval_model
  and verify_globals_spec=NM_ACLnotCommunicateWith.verify_globals
  and verify_globals_impl=verify_globals
  and target_focus=NM_ACLnotCommunicateWith.target_focus
  and offending_flows_impl=ACLnotCommunicateWith_offending_list
  and node_props_impl=NetModel_node_props
  and eval_impl=ACLnotCommunicateWith_eval
apply(unfold_locales)
 apply(simp add: FiniteListGraph.succ_tran_correct[symmetric] list_graph_to_graph_def)
 apply(simp add: list_graph_to_graph_def)
 apply(unfold ACLnotCommunicateWith_offending_list_def)
  apply(rule Generic_offending_list_correct)
  apply(simp)
 apply(simp add: FiniteListGraph.succ_tran_correct[symmetric] list_graph_to_graph_def)
apply(simp only: NetModel_node_props_def)
 apply(metis ACLnotCommunicateWith.node_props.simps ACLnotCommunicateWith.node_props_eq_node_props_formaldef)
apply(simp only: ACLnotCommunicateWith_eval_def)
apply(rule_tac target_focus=NM_ACLnotCommunicateWith.target_focus in NetworkModel_eval_impl_proofrule)
 apply(unfold_locales) (*instance*)
apply(simp_all add: list_graph_to_graph_def FiniteListGraph.succ_tran_correct[symmetric])
done


section {* CommunicationPartners packing *}
  definition NM_LIB_ACLnotCommunicateWith:: "('v::vertex, 'v set, unit) NetworkModel_packed" where
    "NM_LIB_ACLnotCommunicateWith \<equiv> 
    \<lparr> nm_name = ''ACLnotCommunicateWith'', 
      nm_target_focus = NM_ACLnotCommunicateWith.target_focus,
      nm_default = NM_ACLnotCommunicateWith.default_node_properties, 
      nm_eval_model = eval_model,
      nm_verify_globals = verify_globals,
      nm_offending_flows = ACLnotCommunicateWith_offending_list, 
      nm_node_props = NetModel_node_props,
      nm_eval = ACLnotCommunicateWith_eval
      \<rparr>"
  interpretation NM_LIB_ACLnotCommunicateWith_interpretation: NetworkModel_modelLibrary NM_LIB_ACLnotCommunicateWith
      NM_ACLnotCommunicateWith.eval_model NM_ACLnotCommunicateWith.verify_globals
    apply(unfold NetworkModel_modelLibrary_def NM_LIB_ACLnotCommunicateWith_def)
    apply(rule conjI)
     apply(simp)
    apply(simp)
    by(unfold_locales)



text {* Examples*}



hide_const (open) NetModel_node_props
hide_const (open) eval_model verify_globals

end