section {* Refinement Framework *}
theory Refine_Monadic
imports 
  Refine_Chapter
  Refine_Basic 
  Refine_Leof
  Refine_Heuristics 
  Refine_While 
  Refine_Foreach 
  Refine_Transfer
  Refine_Pfun
  Refine_Automation
  Autoref_Monadic
begin
  text {*
    This theory summarizes all default theories of the refinement framework.
    *}

  subsection \<open>Convenience Constructs\<close>

  definition "REC_annot pre post body x \<equiv> 
    REC (\<lambda>D x. do {ASSERT (pre x); r\<leftarrow>body D x; ASSERT (post x r); RETURN r}) x"
  
  theorem REC_annot_rule[refine_vcg]:
    assumes M: "trimono body"
    and P: "pre x"
    and S: "\<And>f x. \<lbrakk>\<And>x. pre x \<Longrightarrow> f x \<le> SPEC (post x); pre x\<rbrakk> 
            \<Longrightarrow> body f x \<le> SPEC (post x)"
    and C: "\<And>r. post x r \<Longrightarrow> \<Phi> r"
    shows "REC_annot pre post body x \<le> SPEC \<Phi>"
  proof -
    from `trimono body` have [refine_mono]:
      "\<And>f g x xa. (\<And>x. flat_ge (f x) (g x)) \<Longrightarrow> flat_ge (body f x) (body g x)"
      "\<And>f g x xa. (\<And>x. f x \<le> g x) \<Longrightarrow> body f x \<le> body g x"
      apply -
      unfolding trimono_def monotone_def fun_ord_def mono_def le_fun_def
      apply (auto)
      done
  
    show ?thesis
      unfolding REC_annot_def
      apply (rule order_trans[where y="SPEC (post x)"])
      apply (refine_rcg 
        refine_vcg 
        REC_rule[where pre=pre and M="\<lambda>x. SPEC (post x)"]
        order_trans[OF S]
      )
      apply fact
      apply simp
      using C apply (auto) []
      done
  qed
  

end
