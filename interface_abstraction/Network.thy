theory Network
imports Entity
begin

(*examples and code equations are in Network_ex*)

section{*A network consisting of entities*}
  text{*packet header*}
  type_synonym 'v hdr="('v entity \<times> 'v entity)" -- "packet header: (src address, dst address)"


  text{*fwd is an entity's packet forward function: 
      A packet arriving at port with a header (src, dst) is outputted to a set of ports.
      Example: flooding switch with 3 ports. If packet arrives at port 1, output at ports {2,3}.*}
  type_synonym 'v fwd_fun="port \<Rightarrow> 'v hdr \<Rightarrow> port set"

  
  text{* A network consists of
          A set of interfaces (ports at entities where packets are moved between)
          A forwarding behaviour per entity
          Links betweend interfaces (edges in a graph or cables in real world)*}
  record 'v network = interfaces :: "'v interface set"
                      forwarding :: "'v entity \<Rightarrow> 'v fwd_fun"
                      links      :: "(('v interface) \<times> ('v interface)) set"

  text{*here is an abbreviatin for forwarding in network N the packet with hdr at input interface hop:
          get forwarding function for hop, apply input port and hdr to it, get result*}
  abbreviation forward :: "'v network \<Rightarrow> 'v hdr \<Rightarrow> 'v interface \<Rightarrow> port set" where
    "forward N hdr hop \<equiv> ((forwarding N) (entity hop)) (port hop) hdr"

  text{*wellformed network.
        Links must be subset of interfaces, think of it as a graph. 
        names_disjunct verifies that no confusion arises if there is a switch ''x'' and a host ''x''.*}
  locale wellformed_network =
    fixes N :: "'v network"
    assumes fst_links: "fst ` links N \<subseteq> interfaces N"
    and     snd_links: "snd ` links N \<subseteq> interfaces N"
    and     finite_interfaces: "finite (interfaces N)"
    and     names_disjunct: "{host. Host host \<in> entity ` interfaces N} \<inter> {box. NetworkBox box \<in> entity ` interfaces N} = {}"
    begin
      lemma finite_links: "finite (links N)"
      proof - 
        have "\<And> X. X \<subseteq> fst ` X \<times> snd ` X" by force
        hence "links N \<subseteq> fst ` links N \<times> snd ` links N" by blast
        from this rev_finite_subset[OF finite_interfaces fst_links] rev_finite_subset[OF finite_interfaces snd_links] show ?thesis
          by (metis finite_cartesian_product rev_finite_subset)
      qed

      lemma finite_entity_interfaces: "finite (entity ` interfaces N)" by(simp add: finite_interfaces)
      lemma finite_entity_name_entity_interfaces: "finite (entity_name ` entity ` interfaces N)" by(simp add: finite_entity_interfaces)
      
      lemma names_disjunct_2: "\<forall>x\<in>interfaces N. \<forall>y\<in>interfaces N. entity_name (entity x) = entity_name (entity y) \<longrightarrow> entity x = entity y"
        apply(clarify)
        apply(case_tac x, rename_tac entity_x port_x, case_tac y, rename_tac entity_y port_y, clarsimp)
        apply(case_tac entity_x, case_tac entity_y)
        apply(simp add: entity_name_def)
        apply(simp add: entity_name_def)
        using names_disjunct apply force
        apply(clarsimp)
        apply(case_tac entity_y)
        apply(simp add: entity_name_def)
        using names_disjunct apply force
        apply(simp add: entity_name_def)
        done
      lemma "card (entity ` interfaces N) = card (entity_name ` entity ` interfaces N)"
        thm Set_Interval.BIJ
        apply(subst Set_Interval.BIJ[OF finite_entity_interfaces finite_entity_name_entity_interfaces, symmetric])
        apply(rule_tac x="entity_name" in exI)
        apply(simp add: bij_betw_def inj_on_def)
        apply(fact names_disjunct_2)
        done
    end


    subsection{*Moving packets*}
      text{*The following simple model is used. A packet is moved from input interface to input interface.
            Therefore, two steps are necessary. 
            1) the entity forwarding function outputs the packet at output interfaces. 
            2) the packet traverses the link and thus arrives at the next input interface. *}

      text{*succ moves packet along links. It is step 2*}
      definition succ :: "'v network \<Rightarrow> 'v interface \<Rightarrow> ('v interface) set" where
        "succ N out_iface \<equiv> {in_iface. (out_iface, in_iface) \<in> links N}"
  
      text{*A packet traverses a hop. It performs steps 1 and 2.*}
      (*recall: (forward N hdr hop) return the ports where the packet leaves the entity*)
      definition traverse :: "'v network \<Rightarrow> 'v hdr \<Rightarrow> 'v interface \<Rightarrow> ('v interface) set" where
        "traverse N hdr hop \<equiv> \<Union> p \<in> (forward N hdr hop). succ N \<lparr>entity = entity hop, port = p\<rparr>"

      (*traverse jumps over routers, it is not in the links. the forwarding function moves packets in routeres, there is no corresponding link IN an entity for it. *)
      lemma traverse_subseteq_interfaces: "wellformed_network N \<Longrightarrow> traverse N hdr hop \<subseteq> interfaces N"
        apply(simp add: traverse_def succ_def)
        apply(drule wellformed_network.snd_links)
        by force
      corollary traverse_finite: assumes wf_N: "wellformed_network N"
        shows "finite (traverse N hdr hop)"
        using traverse_subseteq_interfaces[OF wf_N] wellformed_network.finite_interfaces[OF wf_N] by (metis rev_finite_subset)

 

    subsection {*Reachable interfaces*}
      text{* Traverese performs one step to move a packet. The reachable set defines all reachable entities for a given start node of a packet. *}
      (* we can allow spoofing by allowing an arbitrary packet header.*)
      text{*reachable(1): a packet starts at a start node. This start node is reachable.
            reachable(2): if a hop is reachables, then the next hop is also reachable. *}
      inductive_set reachable :: "'v network \<Rightarrow> 'v hdr \<Rightarrow> 'v interface \<Rightarrow> ('v interface) set"
      for N::"'v network" and "pkt_hdr"::"'v hdr" and "start"::"'v interface"
      where
        "start \<in> (interfaces N) \<Longrightarrow> start \<in> reachable N pkt_hdr start" |
        "hop \<in> reachable N pkt_hdr start \<Longrightarrow> next_hop \<in> (traverse N pkt_hdr hop) \<Longrightarrow> next_hop \<in> reachable N pkt_hdr start"

      lemma reachable_subseteq_interfaces:
        assumes wf_N: "wellformed_network N"
        shows "reachable N pkt_hdr start \<subseteq> interfaces N"
        proof
          fix x
          show "x \<in> reachable N pkt_hdr start \<Longrightarrow> x \<in> interfaces N"
            apply(induction x rule: reachable.induct)
            apply(simp)
            using traverse_subseteq_interfaces[OF wf_N] by fast
        qed

      text{*For all starts, we reach all possible interfaces*}
      lemma reachable_completeness:
        assumes wf_N: "wellformed_network N"
        shows "(\<Union> start \<in> interfaces N. reachable N hdr start) = interfaces N"
        apply(rule equalityI)
        using reachable_subseteq_interfaces[OF wf_N] UN_least apply fast
        apply(clarify)
        by(auto intro: reachable.intros(1))

    subsection{*The view of a packet*}
      text{*For a fixed packet with a fixed header, its global network view is defined. 
            For any start interface the packet is set out, the interfaces the packet can go next is recoreded.
            
            Essentially, view is a relation or the edges of a graph. This graph describes how the packet can move. 
              The forwarding (and transfer) function is removed, the packet can directly move along the edges!

            It is the view a packet has from the network.
            *}
      definition view :: "'v network \<Rightarrow> 'v hdr \<Rightarrow> (('v interface) \<times> ('v interface)) set" where
        "view N hdr = {(src, dst). src \<in> interfaces N \<and> dst \<in> traverse N hdr src}"

      text{*Alternative definition of view: For all interfaces in the network, collect the next hops. *}
      lemma view_alt: "view N hdr = (\<Union>src \<in> interfaces N. {src} \<times> traverse N hdr src)"
        apply(simp add: view_def)
        apply(rule)
        apply blast
        apply(rule)
        by(clarify)

      lemma view_finite: assumes wf_N: "wellformed_network N"
        shows "finite (view N hdr)"
        apply(simp add: view_alt)
        apply(subst finite_UN[OF wellformed_network.finite_interfaces[OF wf_N]])
        apply(clarify)
        apply(rule finite_cartesian_product)
        apply simp
        using traverse_finite[OF wf_N] by simp

  
    theorem reachable_eq_rtrancl_view:
        assumes wf_N: "wellformed_network N"
        and     start_iface: "start \<in> interfaces N"
        shows "reachable N hdr start = {dst. (start, dst) \<in> (view N hdr)\<^sup>*}"
      apply(rule equalityI)
      apply(rule)
      apply(simp)
      apply(erule reachable.induct)
      apply(simp add: view_def)
      apply(simp add: view_def)
      apply(subgoal_tac "(hop, next_hop) \<in> {(src, dst). src \<in> interfaces N \<and> dst \<in> traverse N hdr src}")
      apply (metis (lifting, no_types) rtrancl.rtrancl_into_rtrancl)
      apply(simp)
      using reachable_subseteq_interfaces[OF wf_N] apply fast
      (*next, right to left subset*)
      apply(rule)
      apply(simp)
      apply(erule rtrancl_induct)
      apply(simp)
      apply(simp add: start_iface reachable.intros(1))
      apply(simp)
      apply(simp add: view_def)
      apply (metis (full_types) reachable.intros(2))
      done



section{*TEST TEST TES TEST of UNIO*}
  lemma "UNION {1::nat,2,3} (\<lambda>n. {n+1}) = {2,3,4}" by eval
  lemma "(\<Union>n\<in>{1::nat, 2, 3}. {n + 1}) = {2, 3, 4}" by eval
  lemma "UNION {1::nat,2,3} (\<lambda>n. {n+1}) = set (map (\<lambda>n. n+1) [1,2,3])" by eval


  locale X =
    fixes N1 N2
    assumes well_n1: "wellformed_network N1"
    assumes well_n2: "wellformed_network N2"
  begin
  end

  sublocale X \<subseteq> n1!: wellformed_network N1
    by (rule well_n1)
  sublocale X \<subseteq> n2!: wellformed_network N2
    by (rule well_n2)
  
    context X
    begin
      
    end

end
