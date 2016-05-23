theory Analysis_Tainting
imports SINVAR_Tainting SINVAR_BLPbasic
        SINVAR_TaintingTrusted SINVAR_BLPtrusted
begin

term SINVAR_Tainting.sinvar
term SINVAR_BLPbasic.sinvar


lemma tainting_imp_blp_cutcard: "\<forall>ts v. nP v = ts \<longrightarrow> finite ts \<Longrightarrow>
  SINVAR_Tainting.sinvar G nP \<Longrightarrow> SINVAR_BLPbasic.sinvar G ((\<lambda>ts. card (ts \<inter> X)) \<circ> nP)"
apply(simp add: SINVAR_Tainting.sinvar_def)
apply(clarify, rename_tac a b)
apply(erule_tac x="(a,b)" in ballE)
 apply(simp_all)
apply(subgoal_tac "finite (nP a \<inter> X)")
 prefer 2 subgoal using finite_Int by blast
apply(subgoal_tac "finite (nP b \<inter> X)")
 prefer 2 subgoal using finite_Int by blast
using card_mono by (metis Int_subset_iff order_refl subset_antisym)

lemma tainting_imp_blp_cutcard2: "finite X \<Longrightarrow>
  SINVAR_Tainting.sinvar G nP \<Longrightarrow> SINVAR_BLPbasic.sinvar G ((\<lambda>ts. card (ts \<inter> X)) \<circ> nP)"
apply(simp add: SINVAR_Tainting.sinvar_def)
apply(clarify, rename_tac a b)
apply(erule_tac x="(a,b)" in ballE)
 apply(simp_all)
apply(subgoal_tac "finite (nP a \<inter> X)")
 prefer 2 subgoal using finite_Int by blast
apply(subgoal_tac "finite (nP b \<inter> X)")
 prefer 2 subgoal using finite_Int by blast
using card_mono by (metis Int_subset_iff order_refl subset_antisym)

lemma "\<forall>ts v. nP v = ts \<longrightarrow> finite ts \<Longrightarrow>
  SINVAR_Tainting.sinvar G nP \<Longrightarrow> SINVAR_BLPbasic.sinvar G (card \<circ> nP)"
apply(drule(1) tainting_imp_blp_cutcard[where X=UNIV])
by(simp)


(*Stronger version*)
lemma "\<forall>b \<in> snd ` edges G. finite (nP b) \<Longrightarrow>
  SINVAR_Tainting.sinvar G nP \<Longrightarrow> SINVAR_BLPbasic.sinvar G (card \<circ> nP)"
apply(simp add: SINVAR_Tainting.sinvar_def)
apply(clarify, rename_tac a b)
apply(erule_tac x="(a,b)" in ballE)
 apply(simp_all)
apply(case_tac "finite (nP a)")
 apply(case_tac [!] "finite (nP b)")
   using card_mono apply blast
  apply(simp_all)
done


text\<open>One tainting invariant is equal to many BLP invariants. 
     The BLP invariants are the projection of the tainting mapping for exactly one label\<close>
lemma tainting_iff_blp:
  defines "extract \<equiv> \<lambda>a ts. if a \<in> ts then 1::privacy_level else 0::privacy_level"
  shows "SINVAR_Tainting.sinvar G nP \<longleftrightarrow> (\<forall>a. SINVAR_BLPbasic.sinvar G (extract a \<circ> nP))"
proof
  show"SINVAR_Tainting.sinvar G nP \<Longrightarrow> \<forall>a. SINVAR_BLPbasic.sinvar G (extract a \<circ> nP)"
    apply(simp add: extract_def)
    apply(safe)
     apply simp
    apply(simp add: SINVAR_Tainting.sinvar_def)
    by fast
  next
    assume blp: "\<forall>a. SINVAR_BLPbasic.sinvar G (extract a \<circ> nP)"
    { fix v1 v2
      assume *: "(v1,v2)\<in>edges G"
      { fix a
        from blp * have "(if a \<in> nP v1 then 1::privacy_level else 0) \<le> (if a \<in> nP v2 then 1 else 0)"
          unfolding extract_def
          apply(simp)
          apply(erule_tac x=a in allE)
          apply(erule_tac x="(v1, v2)" in ballE)
           apply(simp_all)
          apply(simp split: split_if_asm)
          done
        hence "a \<in> nP v1 \<Longrightarrow> a \<in> nP v2" by(simp split: split_if_asm)
      }
      from this have "nP v1 \<subseteq> nP v2" by auto
    }
    thus "SINVAR_Tainting.sinvar G nP" unfolding SINVAR_Tainting.sinvar_def by blast
qed



text{*
  Translated to the Bell LaPadula model with trust:
  security clearance is the number of tainted minus the untainted things
  We set the Trusted flag if a machine untaints things.
*}
lemma "\<forall>ts v. nP v = ts \<longrightarrow> finite (taints ts) \<Longrightarrow>
  SINVAR_TaintingTrusted.sinvar G nP \<Longrightarrow>
    SINVAR_BLPtrusted.sinvar G ((\<lambda> ts. \<lparr>privacy_level = card (taints ts - untaints ts), trusted = (untaints ts \<noteq> {})\<rparr> ) \<circ> nP)"
apply(simp add: SINVAR_TaintingTrusted.sinvar_def)
apply(clarify, rename_tac a b)
apply(erule_tac x="(a,b)" in ballE)
 apply(simp_all)
apply(subgoal_tac "finite (taints (nP a) - untaints (nP a))")
 prefer 2 subgoal by blast
apply(rule card_mono)
 by blast+

lemma tainting_iff_blp_trusted:
  defines "project \<equiv> \<lambda>a ts. \<lparr>
      privacy_level =
        if
          a \<in> (taints ts - untaints ts)
        then
          1::privacy_level
        else
          0::privacy_level
      , trusted = a \<in> untaints ts\<rparr>"
  shows "SINVAR_TaintingTrusted.sinvar G nP \<longleftrightarrow> (\<forall>a. SINVAR_BLPtrusted.sinvar G (project a \<circ> nP))"
unfolding project_def
apply(rule iffI)
 subgoal
 apply(simp add: SINVAR_TaintingTrusted.sinvar_def)
 apply(clarify, rename_tac a b)
 apply(erule_tac x="(a,b)" in ballE)
  apply(simp_all)
 by blast
apply(simp)
apply(simp add: SINVAR_TaintingTrusted.sinvar_def)
apply(clarify, rename_tac a b taintlabel)
apply(erule_tac x=taintlabel in allE)
apply(erule_tac x="(a,b)" in ballE)
 apply(simp_all)
apply(simp split: split_if_asm)
using taints_wellformedness by blast

end