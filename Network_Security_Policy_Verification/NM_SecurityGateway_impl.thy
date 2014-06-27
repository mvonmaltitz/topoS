theory NM_SecurityGateway_impl
imports NM_SecurityGateway NetworkModel_Lists_Impl_Interface
begin

code_identifier code_module  NM_SecurityGateway_impl => (Scala) NM_SecurityGateway


section {* NetworkModel SecurityGateway Implementation *}

fun eval_model :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> bool" where
  "eval_model G nP = (\<forall> (e1,e2) \<in> set (edgesL G). e1 \<noteq> e2 \<longrightarrow> allowed_secgw_flow (nP e1) (nP e2))"

fun verify_globals :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> unit \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"


definition SecurityGateway_offending_list:: "'v list_graph \<Rightarrow> ('v \<Rightarrow> secgw_member) \<Rightarrow> ('v \<times> 'v) list list" where
  "SecurityGateway_offending_list G nP = (if eval_model G nP then
    []
   else 
    [ [e \<leftarrow> edgesL G. case e of (e1,e2) \<Rightarrow> e1 \<noteq> e2 \<and> \<not> allowed_secgw_flow (nP e1) (nP e2)] ])"



definition "NetModel_node_props P = (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> NM_SecurityGateway.default_node_properties))"
lemma[code_unfold]: "NetworkModel.node_props NM_SecurityGateway.default_node_properties P = NetModel_node_props P"
apply(simp add: NetModel_node_props_def)
done

definition "SecurityGateway_eval G P = (valid_list_graph G \<and> 
  verify_globals G (NetworkModel.node_props NM_SecurityGateway.default_node_properties P) (model_global_properties P) \<and> 
  eval_model G (NetworkModel.node_props NM_SecurityGateway.default_node_properties P))"


interpretation SecurityGateway_impl:NetworkModel_List_Impl 
  where default_node_properties=NM_SecurityGateway.default_node_properties
  and eval_model_spec=NM_SecurityGateway.eval_model
  and eval_model_impl=eval_model
  and verify_globals_spec=NM_SecurityGateway.verify_globals
  and verify_globals_impl=verify_globals
  and target_focus=NM_SecurityGateway.target_focus
  and offending_flows_impl=SecurityGateway_offending_list
  and node_props_impl=NetModel_node_props
  and eval_impl=SecurityGateway_eval
apply(unfold_locales)
 apply(simp add: list_graph_to_graph_def)
 apply(simp add: list_graph_to_graph_def)
 apply(simp add: list_graph_to_graph_def SecurityGateway_offending_set SecurityGateway_offending_set_def SecurityGateway_offending_list_def)
apply(simp only: NetModel_node_props_def)
 apply(metis SecurityGateway.node_props.simps SecurityGateway.node_props_eq_node_props_formaldef)
apply(simp only: SecurityGateway_eval_def)
apply(rule_tac target_focus=NM_SecurityGateway.target_focus in NetworkModel_eval_impl_proofrule)
 apply(unfold_locales) (*instance*)
apply(simp_all add: list_graph_to_graph_def)
done



section {* SecurityGateway packing *}
  definition NM_LIB_SecurityGateway :: "('v::vertex, secgw_member, unit) NetworkModel_packed" where
    "NM_LIB_SecurityGateway \<equiv> 
    \<lparr> nm_name = ''SecurityGateway'', 
      nm_target_focus = NM_SecurityGateway.target_focus,
      nm_default = NM_SecurityGateway.default_node_properties, 
      nm_eval_model = eval_model,
      nm_verify_globals = verify_globals,
      nm_offending_flows = SecurityGateway_offending_list, 
      nm_node_props = NetModel_node_props,
      nm_eval = SecurityGateway_eval
      \<rparr>"
  interpretation NM_LIB_SecurityGateway_interpretation: NetworkModel_modelLibrary NM_LIB_SecurityGateway 
      NM_SecurityGateway.eval_model NM_SecurityGateway.verify_globals
    apply(unfold NetworkModel_modelLibrary_def NM_LIB_SecurityGateway_def)
    apply(rule conjI)
     apply(simp)
    apply(simp)
    by(unfold_locales)

text {* Examples*}

  definition example_net_secgw :: "nat list_graph" where
  "example_net_secgw \<equiv> \<lparr> nodesL = [1::nat,2,3, 8, 11,12], 
    edgesL = [(1,8),(8,2),(2,8),(8,1), (8,11),(8,12), (11,12)] \<rparr>"
  value[code] "valid_list_graph example_net_secgw"
  
  definition example_conf_secgw where
  "example_conf_secgw \<equiv> ((\<lambda>e. NM_SecurityGateway.default_node_properties)
    (1 := DomainMember, 2:= DomainMember, 3:= DomainMember,
     8:= SecurityGateway))" 
  
  value[code] "eval_model example_net_secgw example_conf_secgw"
  value[code] "SecurityGateway_offending_list example_net_secgw example_conf_secgw"


  definition example_net_secgw_invalid where
  "example_net_secgw_invalid \<equiv> example_net_secgw\<lparr>edgesL := (11,1)#(11,8)#(1,2)#(edgesL example_net_secgw)\<rparr>"

  value[code] "eval_model example_net_secgw_invalid example_conf_secgw"
  value[code] "SecurityGateway_offending_list example_net_secgw_invalid example_conf_secgw"


hide_const (open) NetModel_node_props
hide_const (open) eval_model verify_globals

end