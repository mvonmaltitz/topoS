theory Imaginary_Factory_Network
imports "../TopoS_Impl"
begin

abbreviation "V\<equiv>TopoS_Vertices.V"

definition policy :: "vString list_graph" where
  "policy \<equiv> \<lparr> nodesL = [V ''Statistics'',
                        V ''SensorSink'',
                        V ''PresenceSensor'',
                        V ''Webcam'',
                        V ''TempSensor'',
                        V ''FireSensor'',
                        V ''MissionControl1'',
                        V ''MissionControl2'',
                        V ''Watchdog'',
                        V ''Bot1'',
                        V ''Bot2'',
                        V ''AdminPc'',
                        V ''INET''],
              edgesL = [(V ''PresenceSensor'', V ''SensorSink''),
                        (V ''Webcam'', V ''SensorSink''),
                        (V ''TempSensor'', V ''SensorSink''),
                        (V ''FireSensor'', V ''SensorSink''),
                        (V ''SensorSink'', V ''Statistics''),
                        (V ''MissionControl1'', V ''Bot1''),
                        (V ''MissionControl1'', V ''Bot2''),
                        (V ''MissionControl2'', V ''Bot2''),
                        (V ''AdminPc'', V ''MissionControl2''),
                        (V ''AdminPc'', V ''MissionControl1''),
                        (V ''Watchdog'', V ''Bot1''),
                        (V ''Watchdog'', V ''Bot2'')
                        ] \<rparr>"

lemma "wf_list_graph policy" by eval


ML_val{*
visualize_graph @{context} @{term "[]::vString SecurityInvariant list"} @{term "policy"};
*}

text{*Privacy for employees*}
context begin
  private definition "BLP_privacy_host_attributes \<equiv> [V ''Statistics'' \<mapsto> 3,
                           V ''SensorSink'' \<mapsto> 3,
                           V ''PresenceSensor'' \<mapsto> 2, (*less critical data*)
                           V ''Webcam'' \<mapsto> 3
                           ]"
  private lemma "dom (BLP_privacy_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_privacy_host_attributes_def policy_def)
  definition "BLP_privacy_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPbasic \<lparr> 
        node_properties = BLP_privacy_host_attributes \<rparr>"
end


text{*Secret corporate knowledge and intellectual property*}
context begin
  private definition "BLP_tradesecrets_host_attributes \<equiv> [V ''MissionControl1'' \<mapsto> 1,
                           V ''MissionControl2'' \<mapsto> 2,
                           V ''Bot1'' \<mapsto> 1,
                           V ''Bot2'' \<mapsto> 2
                           ]"
  private lemma "dom (BLP_tradesecrets_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_tradesecrets_host_attributes_def policy_def)
  definition "BLP_tradesecrets_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPbasic \<lparr> 
        node_properties = BLP_tradesecrets_host_attributes \<rparr>"
end


text{*Privacy for employees, exporting aggregated data*}
context begin
  private definition "BLP_employee_export_host_attributes \<equiv>
                          [V ''Statistics'' \<mapsto> \<lparr> privacy_level = 3, trusted = False \<rparr>,
                           V ''SensorSink'' \<mapsto> \<lparr> privacy_level = 2, trusted = True \<rparr>,
                           V ''PresenceSensor'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                           V ''Webcam'' \<mapsto> \<lparr> privacy_level = 3, trusted = False \<rparr>
                           ]"
  private lemma "dom (BLP_employee_export_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: BLP_employee_export_host_attributes_def policy_def)
  definition "BLP_employee_export_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted \<lparr> 
        node_properties = BLP_employee_export_host_attributes \<rparr>"
  (*TODO: what if Sensor sink were not trusted or had lower or higher clearance?*)
end



text{*Who can access bot2?*}
context begin
  private definition "ACL_bot2_host_attributues \<equiv>
                          [V ''Bot2'' \<mapsto> Master [V ''Bot1'',
                                                 V ''MissionControl1'',
                                                 V ''MissionControl2'',
                                                 V ''Watchdog''],
                           V ''MissionControl1'' \<mapsto> Care,
                           V ''MissionControl2'' \<mapsto> Care,
                           V ''Watchdog'' \<mapsto> Care
                           ]"
  private lemma "dom (ACL_bot2_host_attributues) \<subseteq> set (nodesL policy)"
    by(simp add: ACL_bot2_host_attributues_def policy_def)
  definition "ACL_bot2_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_CommunicationPartners
                             \<lparr>node_properties = ACL_bot2_host_attributues \<rparr>"
  (*TODO: bot1 cannot access bot2 anyway!*)
end


(*TODO: dependability*)


text{*Hierarchy of fab robots*}
context begin
  private definition "DomainHierarchy_host_attributes \<equiv>
                [(V ''MissionControl1'',
                    DN (''ControlTerminal''--''ControlDevices''--Leaf, 0)),
                 (V ''MissionControl2'',
                    DN (''ControlTerminal''--''ControlDevices''--Leaf, 0)),
                 (V ''Watchdog'',
                    DN (''ControlTerminal''--''Supervision''--Leaf, 1)),
                 (V ''Bot1'',
                    DN (''ControlTerminal''--''ControlDevices''--''Robots''--Leaf, 0)),
                 (V ''Bot2'',
                    DN (''ControlTerminal''--''ControlDevices''--''Robots''--Leaf, 0)),
                 (V ''AdminPc'',
                    DN (''ControlTerminal''--Leaf, 0))
                 ]"
  private lemma "dom (map_of DomainHierarchy_host_attributes) \<subseteq> set (nodesL policy)"
    by(simp add: DomainHierarchy_host_attributes_def policy_def)

  lemma "DomainHierarchyNG_sanity_check_config
    (map snd DomainHierarchy_host_attributes)
        (
        Department ''ControlTerminal'' [
          Department ''ControlDevices'' [
            Department ''Robots'' [],
            Department ''OtherStuff'' [],
            Department ''ThirdSubDomain'' []
          ],
          Department ''Supervision'' [
            Department ''S1'' [],
            Department ''S2'' []
          ]
        ])" by eval

  definition "Control_hierarchy_m \<equiv> new_configured_list_SecurityInvariant
                                    SINVAR_LIB_DomainHierarchyNG
                                    \<lparr> node_properties = map_of DomainHierarchy_host_attributes \<rparr>"
end

text{*NonInterference of something (for the sake of example)
Whatever happens, Admin must not interfere with the fire sensor.
Because the company that sold the fire sensor wrote it in their contract or something.*}
context begin
  private definition "NonInterference_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Unrelated,
                 V ''SensorSink'' \<mapsto> Unrelated,
                 V ''PresenceSensor'' \<mapsto> Unrelated,
                 V ''Webcam'' \<mapsto> Unrelated,
                 V ''TempSensor'' \<mapsto> Unrelated,
                 V ''FireSensor'' \<mapsto> Interfering, (*!*)
                 V ''MissionControl1'' \<mapsto> Unrelated,
                 V ''MissionControl2'' \<mapsto> Unrelated,
                 V ''Watchdog'' \<mapsto> Unrelated,
                 V ''Bot1'' \<mapsto> Unrelated,
                 V ''Bot2'' \<mapsto> Unrelated,
                 V ''AdminPc'' \<mapsto> Interfering, (*!*)
                 V ''INET'' \<mapsto> Unrelated
                 ]"
  private lemma "dom NonInterference_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: NonInterference_host_attributes_def policy_def)
  definition "NonInterference_m \<equiv> new_configured_list_SecurityInvariant SINVAR_LIB_NonInterference
                                    \<lparr> node_properties = NonInterference_host_attributes \<rparr>"
end



text{*Sensor Gateway*}
context begin
  private definition "SecurityGateway_host_attributes \<equiv>
                [V ''SensorSink'' \<mapsto> SecurityGateway,
                 V ''PresenceSensor'' \<mapsto> DomainMember,
                 V ''Webcam'' \<mapsto> DomainMember,
                 V ''TempSensor'' \<mapsto> DomainMember,
                 V ''FireSensor'' \<mapsto> DomainMember
                 ]"
  private lemma "dom SecurityGateway_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SecurityGateway_host_attributes_def policy_def)
  definition "SecurityGateway_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_SecurityGatewayExtended
                                    \<lparr> node_properties = SecurityGateway_host_attributes \<rparr>"
end


text{*Production Robots are an information sink*}
context begin
  private definition "SinkRobots_host_attributes \<equiv>
                [V ''MissionControl1'' \<mapsto> SinkPool,
                 V ''MissionControl2'' \<mapsto> SinkPool,
                 V ''Bot1'' \<mapsto> Sink,
                 V ''Bot2'' \<mapsto> Sink
                 ]"
  private lemma "dom SinkRobots_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SinkRobots_host_attributes_def policy_def)
  definition "SinkRobots_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_Sink
                                    \<lparr> node_properties = SinkRobots_host_attributes \<rparr>"
end

text{*Subnet of the fab*}
context begin
  private definition "Subnets_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Subnet 1,
                 V ''SensorSink'' \<mapsto> Subnet 1,
                 V ''PresenceSensor'' \<mapsto> Subnet 1,
                 V ''Webcam'' \<mapsto> Subnet 1,
                 V ''TempSensor'' \<mapsto> Subnet 1,
                 V ''FireSensor'' \<mapsto> Subnet 1,
                 V ''AdminPc'' \<mapsto> Subnet 4
                 ]"
  private lemma "dom Subnets_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: Subnets_host_attributes_def policy_def)
  definition "Subnets_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_Subnets
                                    \<lparr> node_properties = Subnets_host_attributes \<rparr>"
end


context begin
  private definition "SubnetsInGW_host_attributes \<equiv>
                [V ''Statistics'' \<mapsto> Member,
                 V ''SensorSink'' \<mapsto> InboundGateway
                 ]"
  private lemma "dom SubnetsInGW_host_attributes \<subseteq> set (nodesL policy)"
    by(simp add: SubnetsInGW_host_attributes_def policy_def)
  definition "SubnetsInGW_m \<equiv> new_configured_list_SecurityInvariant
                                  SINVAR_LIB_SubnetsInGW
                                    \<lparr> node_properties = SubnetsInGW_host_attributes \<rparr>"
end


definition "invariants \<equiv> [BLP_privacy_m, BLP_tradesecrets_m, BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m,
                          SecurityGateway_m, SinkRobots_m, Subnets_m, SubnetsInGW_m]"
text{*We have excluded @{const NonInterference_m} because of its infeasible runtime.*}


lemma "length invariants = 9" by eval


text{*All security requirements (including @{const NonInterference_m}) are fulfilled.*}
lemma "all_security_requirements_fulfilled (NonInterference_m#invariants) policy" by eval
ML{*
visualize_graph @{context} @{term "invariants"} @{term "policy"};
*}


definition make_policy :: "('a SecurityInvariant) list \<Rightarrow> 'a list \<Rightarrow> 'a list_graph" where
  "make_policy sinvars Vs \<equiv> generate_valid_topology sinvars \<lparr>nodesL = Vs, edgesL = List.product Vs Vs \<rparr>"


definition make_policy_efficient :: "('a SecurityInvariant) list \<Rightarrow> 'a list \<Rightarrow> 'a list_graph" where
  "make_policy_efficient sinvars Vs \<equiv> generate_valid_topology_some sinvars \<lparr>nodesL = Vs, edgesL = List.product Vs Vs \<rparr>"



text{*
The diff to the maximum policy.
Since we excluded @{const NonInterference_m}, it should be the maximum.
*}
value[code] "make_policy invariants (nodesL policy)" (*15s without NonInterference*)
lemma "make_policy invariants (nodesL policy) = 
   \<lparr>nodesL =
    [V ''Statistics'', V ''SensorSink'', V ''PresenceSensor'', V ''Webcam'', V ''TempSensor'',
     V ''FireSensor'', V ''MissionControl1'', V ''MissionControl2'', V ''Watchdog'', V ''Bot1'',
     V ''Bot2'', V ''AdminPc'', V ''INET''],
    edgesL =
      [(V ''Statistics'', V ''Statistics''), (V ''SensorSink'', V ''Statistics''),
       (V ''SensorSink'', V ''SensorSink''), (V ''SensorSink'', V ''Webcam''),
       (V ''PresenceSensor'', V ''SensorSink''), (V ''PresenceSensor'', V ''PresenceSensor''),
       (V ''Webcam'', V ''SensorSink''), (V ''Webcam'', V ''Webcam''),
       (V ''TempSensor'', V ''SensorSink''), (V ''TempSensor'', V ''TempSensor''),
       (V ''TempSensor'', V ''INET''), (V ''FireSensor'', V ''SensorSink''),
       (V ''FireSensor'', V ''FireSensor''), (V ''FireSensor'', V ''INET''),
       (V ''MissionControl1'', V ''MissionControl1''),
       (V ''MissionControl1'', V ''MissionControl2''), (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl1'', V ''Bot2''), (V ''MissionControl2'', V ''MissionControl2''),
       (V ''MissionControl2'', V ''Bot2''), (V ''Watchdog'', V ''MissionControl1''),
       (V ''Watchdog'', V ''MissionControl2''), (V ''Watchdog'', V ''Watchdog''),
       (V ''Watchdog'', V ''Bot1''), (V ''Watchdog'', V ''Bot2''), (V ''Watchdog'', V ''INET''),
       (V ''Bot1'', V ''Bot1''), (V ''Bot2'', V ''Bot2''), (V ''AdminPc'', V ''MissionControl1''),
       (V ''AdminPc'', V ''MissionControl2''), (V ''AdminPc'', V ''Watchdog''),
       (V ''AdminPc'', V ''Bot1''), (V ''AdminPc'', V ''AdminPc''), (V ''AdminPc'', V ''INET''),
       (V ''INET'', V ''INET'')]\<rparr>" by eval

text{*Additional flows which would be allowed but which are not in the policy*}
lemma  "set [e \<leftarrow> edgesL (make_policy invariants (nodesL policy)). e \<notin> set (edgesL policy)] = 
        set [(v,v). v \<leftarrow> (nodesL policy)] \<union>
        set [(V ''SensorSink'', V ''Webcam''),
             (V ''TempSensor'', V ''INET''),
             (V ''FireSensor'', V ''INET''),
             (V ''MissionControl1'', V ''MissionControl2''),
             (V ''Watchdog'', V ''MissionControl1''),
             (V ''Watchdog'', V ''MissionControl2''),
             (V ''Watchdog'', V ''INET''),
             (V ''AdminPc'', V ''Watchdog''),
             (V ''AdminPc'', V ''Bot1''),
             (V ''AdminPc'', V ''INET'')]" by eval
ML_val{*
visualize_edges @{context} @{term "edgesL policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL policy)]"})] ""; 
*}

text{* without @{const NonInterference_m} *}
lemma "all_security_requirements_fulfilled invariants (make_policy invariants (nodesL policy))" by eval




text{*Side note: what if we exclude subnets?*}
ML_val{*
visualize_edges @{context} @{term "edgesL (make_policy invariants (nodesL policy))"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy [BLP_privacy_m, BLP_tradesecrets_m, BLP_employee_export_m,
                           ACL_bot2_m, Control_hierarchy_m,
                           SecurityGateway_m, SinkRobots_m, (*Subnets_m, *)SubnetsInGW_m]  (nodesL policy)).
                e \<notin> set (edgesL (make_policy invariants (nodesL policy)))]"})] ""; 
*}


text{*The more efficient algorithm does not need to construct the complete set of offending flows*}
value[code] "make_policy_efficient (invariants@[NonInterference_m]) (nodesL policy)"
value[code] "make_policy_efficient (NonInterference_m#invariants) (nodesL policy)"


lemma "make_policy_efficient (invariants@[NonInterference_m]) (nodesL policy) = 
       make_policy_efficient (NonInterference_m#invariants) (nodesL policy)" by eval

text{*But @{const NonInterference_m} insists on removing something, which would not be necessary.*}
lemma "make_policy invariants (nodesL policy) \<noteq> make_policy_efficient (NonInterference_m#invariants) (nodesL policy)" by eval

lemma "set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))
       \<subseteq>
       set (edgesL (make_policy invariants (nodesL policy)))" by eval

text{*This is what it wants to be gone.*} (*may take some minutes*)
lemma "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))] =
       [(V ''AdminPc'', V ''MissionControl1''), (V ''AdminPc'', V ''MissionControl2''),
        (V ''AdminPc'', V ''Watchdog''), (V ''AdminPc'', V ''Bot1''), (V ''AdminPc'', V ''INET'')]"
  by eval

lemma "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
               e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))] =
       [e \<leftarrow> edgesL (make_policy invariants (nodesL policy)). fst e = V ''AdminPc'' \<and> snd e \<noteq> V ''AdminPc'']"
  by eval
ML_val{*
visualize_edges @{context} @{term "edgesL policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
     @{term "[e \<leftarrow> edgesL (make_policy invariants (nodesL policy)).
                e \<notin> set (edgesL (make_policy_efficient (NonInterference_m#invariants) (nodesL policy)))]"})] ""; 
*}





subsection{*stateful implementation*}
definition "stateful_policy = generate_valid_stateful_policy_IFSACS policy invariants"
lemma "stateful_policy =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics'')]\<rparr>" by eval

ML_val{*
visualize_edges @{context} @{term "flows_fixL stateful_policy"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]", @{term "flows_stateL stateful_policy"})] ""; 
*}


text{*Because @{const BLP_tradesecrets_m} and @{const SinkRobots_m} restrict information leakage,
     @{term "''Watchdog''"} cannot establish a stateful connection to the bots.
     The invariants clearly state that the bots must not leak information, and Watchdog
     was never given permission to get any information back.*}


text{*Without those two invariants, also AdminPc can set up stateful connections to the machines
      it is intended to administer.*}

lemma "generate_valid_stateful_policy_IFSACS policy
      [BLP_privacy_m, BLP_employee_export_m,
       ACL_bot2_m, Control_hierarchy_m, 
       SecurityGateway_m,  Subnets_m, SubnetsInGW_m] =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics''),
       (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl1'', V ''Bot2''),
       (V ''MissionControl2'', V ''Bot2''),
       (V ''AdminPc'', V ''MissionControl2''),
       (V ''AdminPc'', V ''MissionControl1''),
       (V ''Watchdog'', V ''Bot1''),
       (V ''Watchdog'', V ''Bot2'')]\<rparr>" by eval


ML_val{*
visualize_edges @{context} @{term "flows_fixL (generate_valid_stateful_policy_IFSACS policy [BLP_privacy_m,  BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m, 
                          SecurityGateway_m,  Subnets_m, SubnetsInGW_m])"} 
    [("edge [dir=\"arrow\", style=dashed, color=\"#FF8822\", constraint=false]",
      @{term "flows_stateL (generate_valid_stateful_policy_IFSACS policy [BLP_privacy_m,  BLP_employee_export_m,
                          ACL_bot2_m, Control_hierarchy_m, 
                          SecurityGateway_m,  Subnets_m, SubnetsInGW_m])"})] ""; 
*}


text{*Bot1 and Bot2 have different security clearances.
      If Watchdog wants to get information from both, it needs to be trusted.
      Also, Watchdog needs to be included into the SinkPool to set up a stateful connection to the Bots. 
      The bots must be lifted from Sinks to the SinkPool, otherwise, it would be impossible 
      to get any information flow back from them.

      Same for AdminPC.*}

lemma "all_security_requirements_fulfilled [BLP_privacy_m, BLP_employee_export_m,
               ACL_bot2_m, Control_hierarchy_m, 
               SecurityGateway_m, Subnets_m, SubnetsInGW_m,
               new_configured_list_SecurityInvariant SINVAR_LIB_Sink
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> SinkPool,
                                      V ''MissionControl2'' \<mapsto> SinkPool,
                                      V ''Bot1'' \<mapsto> SinkPool,
                                      V ''Bot2'' \<mapsto> SinkPool,
                                      V ''Watchdog'' \<mapsto> SinkPool,
                                      V ''AdminPc'' \<mapsto> SinkPool
                                      ] \<rparr>,
               new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''MissionControl2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Bot1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''Bot2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Watchdog'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>,
                                        (*trust because bot2 must send to it. privacy_level 1 to interact with bot 1*)
                                      V ''AdminPc'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>
                                      ] \<rparr>
              ]
       policy" by eval

lemma "generate_valid_stateful_policy_IFSACS policy
              [BLP_privacy_m, BLP_employee_export_m,
               ACL_bot2_m, Control_hierarchy_m, 
               SecurityGateway_m, Subnets_m, SubnetsInGW_m,
               new_configured_list_SecurityInvariant SINVAR_LIB_Sink
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> SinkPool,
                                      V ''MissionControl2'' \<mapsto> SinkPool,
                                      V ''Bot1'' \<mapsto> SinkPool,
                                      V ''Bot2'' \<mapsto> SinkPool,
                                      V ''Watchdog'' \<mapsto> SinkPool,
                                      V ''AdminPc'' \<mapsto> SinkPool
                                      ] \<rparr>,
               new_configured_list_SecurityInvariant SINVAR_LIB_BLPtrusted
                 \<lparr> node_properties = [V ''MissionControl1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''MissionControl2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Bot1'' \<mapsto> \<lparr> privacy_level = 1, trusted = False \<rparr>,
                                      V ''Bot2'' \<mapsto> \<lparr> privacy_level = 2, trusted = False \<rparr>,
                                      V ''Watchdog'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>,
                                        (*trust because bot2 must send to it. privacy_level 1 to interact with bot 1*)
                                      V ''AdminPc'' \<mapsto> \<lparr> privacy_level = 1, trusted = True \<rparr>
                                      ] \<rparr>
              ]
 =
 \<lparr>hostsL = nodesL policy,
    flows_fixL = edgesL policy,
    flows_stateL =
      [(V ''Webcam'', V ''SensorSink''),
       (V ''SensorSink'', V ''Statistics''),
       (V ''MissionControl1'', V ''Bot1''),
       (V ''MissionControl2'', V ''Bot2''),
       (V ''AdminPc'', V ''MissionControl2''),
       (V ''AdminPc'', V ''MissionControl1''),
       (V ''Watchdog'', V ''Bot1''),
       (V ''Watchdog'', V ''Bot2'')]\<rparr>" by eval



text{*firewall -- classical use case*}
ML_val{*

(*header*)
writeln ("echo 1 > /proc/sys/net/ipv4/ip_forward"^"\n"^
         "# flush all rules"^"\n"^
         "iptables -F"^"\n"^
         "#default policy for FORWARD chain:"^"\n"^
         "iptables -P FORWARD DROP");

iterate_edges_ML @{context}  @{term "flows_fixL stateful_policy"}
  (fn (v1,v2) => writeln ("iptables -A FORWARD -i $"^v1^"_iface -s $"^v1^"_ipv4 -o $"^v2^"_iface -d $"^v2^"_ipv4 -j ACCEPT"^" # "^v1^" -> "^v2) )
  (fn _ => () )
  (fn _ => () );

iterate_edges_ML @{context} @{term "flows_stateL stateful_policy"}
  (fn (v1,v2) => writeln ("iptables -I FORWARD -m state --state ESTABLISHED -i $"^v2^"_iface -s $"^v2^"_ipv4 -o $"^v1^"_iface -d $"^v1^"_ipv4 # "^v2^" -> "^v1^" (answer)") )
  (fn _ => () )
  (fn _ => () )
*}

end


