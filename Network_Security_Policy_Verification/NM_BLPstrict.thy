theory NM_BLPstrict
imports NetworkModel_Interface NetworkModel_Helper
begin

section {* Stricter Bell LePadula NetworkModel *}
text{* All unclassified data sources must be labeled, defualt assumption: all is secret

Warning: This is considered here an access control strategy
By default, everything is secret and one explicitly prohibits sending to non-secret hosts*}

datatype security_clearance = Unclassified | Confidential | Secret

(*total order*)
instantiation security_clearance :: linorder
  begin
  fun less_eq_security_clearance :: "security_clearance \<Rightarrow> security_clearance \<Rightarrow> bool" where
    "(Unclassified \<le> Unclassified) = True" |
    "(Confidential \<le> Confidential) = True" |
    "(Secret \<le> Secret) = True" |
    "(Unclassified \<le> Confidential) = True" |
    "(Confidential \<le> Secret) = True"  |
    "(Unclassified \<le> Secret) = True"  |
    "(Secret \<le> Confidential) = False"  |
    "(Confidential \<le> Unclassified) = False"  |
    "(Secret \<le> Unclassified) = False"

  fun less_security_clearance :: "security_clearance \<Rightarrow> security_clearance \<Rightarrow> bool" where
    "(Unclassified < Unclassified) = False" |
    "(Confidential < Confidential) = False" |
    "(Secret < Secret) = False" |
    "(Unclassified < Confidential) = True" |
    "(Confidential < Secret) = True"  |
    "(Unclassified < Secret) = True"  |
    "(Secret < Confidential) = False"  |
    "(Confidential < Unclassified) = False"  |
    "(Secret < Unclassified) = False"
  instance
    apply(intro_classes)
    apply(case_tac [!] x)
    apply(simp_all)
    apply(case_tac  [!] y)
    apply(simp_all)
    apply(case_tac  [!] z)
    apply(simp_all)
    done
  end
  


definition default_node_properties :: "security_clearance"
  where  "default_node_properties \<equiv> Secret"



fun eval_model :: "'v graph \<Rightarrow> ('v \<Rightarrow> security_clearance) \<Rightarrow> bool" where
  "eval_model G nP = (\<forall> (e1,e2) \<in> edges G. (nP e1) \<le> (nP e2))"

fun verify_globals :: "'v graph \<Rightarrow> ('v \<Rightarrow> security_clearance) \<Rightarrow> 'b \<Rightarrow> bool" where
  "verify_globals _ _ _ = True"

definition target_focus :: "bool" where "target_focus \<equiv> False"


lemma eval_model_mono: "NetworkModel_withOffendingFlows.eval_model_mono eval_model"
  apply(simp only: NetworkModel_withOffendingFlows.eval_model_mono_def)
  apply(clarify)
  by auto


interpretation NetworkModel_preliminaries
where eval_model = eval_model
and verify_globals = verify_globals
  apply unfold_locales
    apply(frule_tac finite_distinct_list[OF valid_graph.finiteE])
    apply(erule_tac exE)
    apply(rename_tac list_edges)
    apply(rule_tac ff="list_edges" in NetworkModel_withOffendingFlows.mono_imp_set_offending_flows_not_empty[OF eval_model_mono])
        apply(auto)[6]
   apply(auto simp add: NetworkModel_withOffendingFlows.is_offending_flows_def graph_ops)[1]
  apply(fact NetworkModel_withOffendingFlows.eval_model_mono_imp_is_offending_flows_mono[OF eval_model_mono])
 done



section {*ENF*}
  lemma secret_default_candidate: "\<And> (nP::('v \<Rightarrow> security_clearance)) e1 e2. \<not> (nP e1) \<le> (nP e2) \<Longrightarrow> \<not> Secret \<le> (nP e2)"
    apply(case_tac "nP e1")
    apply(simp_all)
    apply(case_tac [!] "nP e2")
    apply(simp_all)
    done
  lemma BLP_ENF: "NetworkModel_withOffendingFlows.eval_model_all_edges_normal_form eval_model (op \<le>)"
    unfolding NetworkModel_withOffendingFlows.eval_model_all_edges_normal_form_def
    by simp
  lemma BLP_ENF_refl: "NetworkModel_withOffendingFlows.ENF_refl eval_model (op \<le>)"
    unfolding NetworkModel_withOffendingFlows.ENF_refl_def
    apply(rule conjI)
     apply(simp add: BLP_ENF)
    apply(simp)
  done

  definition BLP_offending_set:: "'v graph \<Rightarrow> ('v \<Rightarrow> security_clearance) \<Rightarrow> ('v \<times> 'v) set set" where
  "BLP_offending_set G nP = (if eval_model G nP then
      {}
     else 
      { {e \<in> edges G. case e of (e1,e2) \<Rightarrow> (nP e1) > (nP e2)} })"
  lemma BLP_offending_set: "NetworkModel_withOffendingFlows.set_offending_flows eval_model = BLP_offending_set"
    apply(simp only: fun_eq_iff NetworkModel_withOffendingFlows.ENF_offending_set[OF BLP_ENF] BLP_offending_set_def)
    apply(rule allI)+
    apply(rename_tac G nP)
    apply(auto)
  done
   

  interpretation BLPstrict: NetworkModel_ACS eval_model verify_globals default_node_properties
  where "NetworkModel_withOffendingFlows.set_offending_flows eval_model = BLP_offending_set"
    unfolding target_focus_def
    unfolding default_node_properties_def
    apply(unfold_locales)
      apply(rule ballI)
      apply(rule NetworkModel_withOffendingFlows.ENF_fsts_refl_instance[OF BLP_ENF_refl])
         apply(simp_all add: BLP_ENF BLP_ENF_refl)[3]
      apply(simp add: secret_default_candidate)
     apply(erule default_uniqueness_by_counterexample_ACS)
     apply(rule_tac x="\<lparr> nodes=set [vertex_1,vertex_2], edges = set [(vertex_1,vertex_2)] \<rparr>" in exI, simp)
     apply(simp add: BLP_offending_set graph_ops valid_graph_def)
     apply(rule_tac x="(\<lambda> x. Secret)(vertex_1 := Secret, vertex_2 := Confidential)" in exI, simp)
     apply(rule_tac x="vertex_1" in exI, simp)
     apply(rule_tac x="set [(vertex_1,vertex_2)]" in exI, simp)
     apply(simp add: BLP_offending_set_def)
     apply(rule conjI)
      apply fastforce
     apply (case_tac otherbot, simp_all)
    apply(fact BLP_offending_set)
   done


  lemma NetworkModel_BLPstrict: "NetworkModel eval_model default_node_properties target_focus"
  unfolding target_focus_def by unfold_locales
   
hide_fact (open) eval_model_mono   

hide_const (open) eval_model verify_globals target_focus default_node_properties

end