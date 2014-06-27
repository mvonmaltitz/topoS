theory NM_BLPtrusted_impl
imports NM_BLPtrusted "../TopoS_Lists_Impl_Interface"
begin

code_identifier code_module NM_BLPtrusted_impl => (Scala) NM_BLPtrusted

fun sinvar :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> NM_BLPtrusted.node_config) \<Rightarrow> bool" where
  "sinvar G nP = (\<forall> (e1,e2) \<in> set (edgesL G). (if trusted (nP e2) then True else privacy_level (nP e1) \<le> privacy_level (nP e2) ))"

fun verify_globals :: "'v list_graph \<Rightarrow> ('v \<Rightarrow> NM_BLPtrusted.node_config) \<Rightarrow> unit \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"


definition BLP_offending_list:: "'v list_graph \<Rightarrow> ('v \<Rightarrow> NM_BLPtrusted.node_config) \<Rightarrow> ('v \<times> 'v) list list" where
  "BLP_offending_list G nP = (if sinvar G nP then
    []
   else 
    [ [e \<leftarrow> edgesL G. case e of (e1,e2) \<Rightarrow> \<not> NM_BLPtrusted.BLP_P (nP e1) (nP e2)] ])"



definition "NetModel_node_props P = (\<lambda> i. (case (node_properties P) i of Some property \<Rightarrow> property | None \<Rightarrow> NM_BLPtrusted.default_node_properties))"
lemma[code_unfold]: "SecurityInvariant.node_props NM_BLPtrusted.default_node_properties P = NetModel_node_props P"
apply(simp add: NetModel_node_props_def)
done

definition "BLP_eval G P = (valid_list_graph G \<and> 
  verify_globals G (SecurityInvariant.node_props NM_BLPtrusted.default_node_properties P) (model_global_properties P) \<and> 
  sinvar G (SecurityInvariant.node_props NM_BLPtrusted.default_node_properties P))"


interpretation BLPtrusted_impl:TopoS_List_Impl 
  where default_node_properties=NM_BLPtrusted.default_node_properties
  and sinvar_spec=NM_BLPtrusted.sinvar
  and sinvar_impl=sinvar
  and verify_globals_spec=NM_BLPtrusted.verify_globals
  and verify_globals_impl=verify_globals
  and receiver_violation=NM_BLPtrusted.receiver_violation
  and offending_flows_impl=BLP_offending_list
  and node_props_impl=NetModel_node_props
  and eval_impl=BLP_eval
 apply(unfold TopoS_List_Impl_def)
 apply(rule conjI)
  apply(simp add: TopoS_BLPtrusted list_graph_to_graph_def)
 apply(rule conjI)
  apply(simp add: list_graph_to_graph_def BLP_offending_set BLP_offending_set_def BLP_offending_list_def)
 apply(rule conjI)
  apply(simp only: NetModel_node_props_def)
  apply(metis BLPtrusted.node_props.simps BLPtrusted.node_props_eq_node_props_formaldef)
 apply(simp only: BLP_eval_def)
 apply(intro allI)
 apply(rule TopoS_eval_impl_proofrule[OF TopoS_BLPtrusted])
 apply(simp_all add: list_graph_to_graph_def)
done



section {* BLPtrusted packing *}
  definition NM_LIB_BLPtrusted :: "('v::vertex, NM_BLPtrusted.node_config, unit) TopoS_packed" where
    "NM_LIB_BLPtrusted \<equiv> 
    \<lparr> nm_name = ''BLPtrusted'', 
      nm_receiver_violation = NM_BLPtrusted.receiver_violation,
      nm_default = NM_BLPtrusted.default_node_properties, 
      nm_sinvar = sinvar,
      nm_verify_globals = verify_globals,
      nm_offending_flows = BLP_offending_list, 
      nm_node_props = NetModel_node_props,
      nm_eval = BLP_eval
      \<rparr>"
  interpretation NM_LIB_BLPtrusted_interpretation: TopoS_modelLibrary NM_LIB_BLPtrusted 
      NM_BLPtrusted.sinvar NM_BLPtrusted.verify_globals
    apply(unfold TopoS_modelLibrary_def NM_LIB_BLPtrusted_def)
    apply(rule conjI)
     apply(simp)
    apply(simp)
    by(unfold_locales)

section{* Example *}
 (*TODO*)


export_code NM_LIB_BLPtrusted in Scala


hide_const (open) NetModel_node_props BLP_offending_list BLP_eval

hide_const (open) sinvar verify_globals

end
