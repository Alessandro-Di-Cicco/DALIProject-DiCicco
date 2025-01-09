
:-dynamic distance/3.

:-dynamic phase/1.

:-dynamic waiting_for/2.

:-dynamic warehouse_online/1.

:-dynamic in_stock/3.

:-dynamic delivery_online/1.

:-dynamic delivery_busy/1.

:-dynamic delivery_location/1.

:-dynamic driver_at/2.

:-dynamic delivery_request/4.

distance(city_a,warehouse1,3).

distance(city_a,warehouse2,2).

distance(city_b,warehouse2,3).

distance(city_b,warehouse1,2).

distance(city_b,warehouse3,1.5).

distance(city_c,warehouse3,3).

distance(city_d,warehouse3,3).

distance(city_c,city_d,3).

distance(warehouse2,warehouse3,1.5).

connected(var_A,var_B,var_Dist):-distance(var_A,var_B,var_Dist).

connected(var_B,var_A,var_Dist):-distance(var_A,var_B,var_Dist).

path(var_Start,var_Start,0,var_Visited,var_Visited):-true.

path(var_Start,var_End,var_TotalDistance,var_Visited,var_Path):-format('Looking for path from ~w to ~w with visited ~w~n',[var_Start,var_End,var_Visited]),connected(var_Start,var_Intermediate,var_Distance1),format(' Exploring ~w~n',[var_Intermediate]),\+member(var_Intermediate,var_Visited),format('Exploring Intermediate ~w from ~w~n',[var_Intermediate,var_Start]),append([var_Intermediate],var_Visited,var_NewList),format('Created ~w from ~w and ~w~n',[var_NewList,var_Intermediate,var_Visited]),path(var_Intermediate,var_End,var_Distance2,var_NewList,var_Path),var_TotalDistance is var_Distance1+var_Distance2.

find_path(var_Start,var_End,var_TotalDistance,var_Path):-path(var_Start,var_End,var_TotalDistance,[var_Start],var_Path).

shortest_path(var_Start,var_End,var_ShortestDistance):-findnsols(5,var_Distance,path(var_Start,var_End,var_Distance,var_Visited),var_Distances),min_list(var_Distances,var_ShortestDistance).

phase(waiting).

waiting_for(warehouse,3).

waiting_for(delivery,2).

eve(warehouse_ready(var_Warehouse)):-phase(waiting),\+warehouse_online(var_Warehouse),waiting_for(warehouse,var_N),var_M is var_N-1,assert(warehouse_online(var_Warehouse)),retract(waiting_for(warehouse,var_N)),assert(waiting_for(warehouse,var_M)),a(message(var_Warehouse,send_message(ready_received,var_Me))),format('Successfully received warehouse ~w',[var_Warehouse]),phase_check.

eve(warehouse_ready(var_Warehouse)):-phase(waiting),warehouse_online(var_Warehouse),a(message(var_Warehouse,send_message(ready_received,var_Me))),format('Got multiple ready messages from ~w',[var_Warehouse]).

eve(warehouse_ready(var_Warehouse)):- \+phase(waiting),format('Receiving sync message from ~w after ready phase is over, something is wrong',[var_Warehouse]).

eve(warehouse_update(var_Warehouse,var_Resource,var_Amount)):-format('Stock update: ~w has ~w ~w~n',[var_Warehouse,var_Amount,var_Resource]),(in_stock(var_Warehouse,var_Resource,var_Any)->retract(in_stock(var_Warehouse,var_Resource,var_Any));true),assert(in_stock(var_Warehouse,var_Resource,var_Amount)).

eve(delivery_ready(var_Delivery)):-phase(waiting),\+delivery_online(var_Delivery),waiting_for(delivery,var_N),var_M is var_N-1,assert(delivery_online(var_Delivery)),retract(waiting_for(delivery,var_N)),assert(waiting_for(delivery,var_M)),a(message(var_Delivery,send_message(ready_received,var_Me))),format('Successfully received delivery ~w',[var_Delivery]),phase_check.

eve(delivery_ready(var_Delivery)):-phase(waiting),delivery_online(var_Delivery),a(message(var_Delivery,send_message(ready_received,var_Me))),format('Got multiple ready messages from ~w',[var_Delivery]).

eve(delivery_ready(var_Delivery)):- \+phase(waiting),format('Receiving sync message from ~w after ready phase is over, something is wrong',[var_Warehouse]).

eve(driver_location(var_Driver,var_Location)):-(driver_at(var_Driver,var_OtherLocation)->retract(driver_at(var_Driver,var_OtherLocation));true),assert(driver_at(var_Driver,var_Location)),format('~w is now located at ~w~n',[var_Driver,var_Location]).

phase_check:-waiting_for(var_Agent,var_N),var_N>0.

phase_check:-waiting_for(warehouse,0),waiting_for(delivery,0),retract(phase(waiting)),format('~nAll agents successfully synced~n',[]),assert(phase(init)).

evi(phase(init)):-a(message(warehouse1,send_message(restock(copper,100),var_Me))),a(message(warehouse1,send_message(restock(iron,50),var_Me))),a(message(warehouse1,send_message(restock(silver,30),var_Me))),a(message(warehouse2,send_message(restock(copper,50),var_Me))),a(message(warehouse2,send_message(restock(iron,100),var_Me))),a(message(warehouse3,send_message(restock(copper,50),var_Me))),a(message(warehouse3,send_message(restock(iron,200),var_Me))),a(message(delivery1,send_message(pos_update(city_a),var_Me))),a(message(delivery2,send_message(pos_update(city_d),var_Me))),format('Refilled all warehouses',[]),retract(phase(init)).

available_driver(var_Delivery):-delivery_online(var_Delivery),\+delivery_busy(var_Delivery).

available_driver_at(var_Driver,var_Location):-available_driver(var_Driver),driver_at(var_Driver,var_Location).

find_warehouse(var_Resource,var_Quantity,var_Warehouse):-in_stock(var_Warehouse,var_Resource,var_AvailableQty),var_AvailableQty>=var_Quantity.

eve(deliver(var_Location,var_Resource,var_Quantity,var_Sender)):-assert(delivery_request(var_Location,var_Resource,var_Quantity,var_Sender)).

evi(delivery_request(var_Location,var_Resource,var_Quantity,var_Sender)):-available_driver(var_Driver),find_warehouse(var_Resource,var_Quantity,var_Warehouse)->make_delivery(var_Location,var_Resource,var_Quantity),assert(delivery_busy(var_Driver)),format('Asked ~w to deliver ~w ~w to ~w~n',[var_Driver,var_Quantity,var_Resource,var_Location]);format('Rejected delivery of ~w ~w to ~w~nNo drivers available~n',[var_Quantity,var_Resource,var_Location]),reject_delivery(var_Location,var_Resource,var_Quantity,var_Sender),retract(delivery_request(var_Location,var_Resource,var_Quantity,var_Sender)).

make_delivery(var_Destination,var_Resource,var_Quantity):-format('Delivery computation~n',[]),available_driver_at(var_Driver,var_DriverLocation),format('Found driver ~w located in ~w~n',[var_Driver,var_DriverLocation]),find_warehouse(var_Resource,var_Quantity,var_Warehouse),format('Found warehouse ~w with ~w ~w~n',[var_Warehouse,var_Quantity,var_Resource]),find_path(var_DriverLocation,var_Warehouse,var_Distance1,var_Path1),format('Computed path from driver to warehouse ~w~n',[var_Path1]),find_path(var_Warehouse,var_Destination,var_Distance2,var_Path2),format('Computed path from warehouse to destination ~w~n',[var_Path2]),var_TotalDistance is var_Distance1+var_Distance2,a(message(var_Driver,send_message(new_delivery(var_Destination,var_Warehouse,var_Resource,var_Quantity),var_Me))),format('selected ~w going to ~w for a distance of ~w~n~n',[var_SelectedDriver,var_SelectedWarehouse,var_TotalDistance]).

eve(driver_busy(var_Driver,var_Location,var_Warehouse,var_Resource,var_Quantity)):-format('~w is busy, declined the request~n',[var_Driver]).

eve(driver_accepts(var_Driver,var_Location,var_Warehouse,var_Resource,var_Quantity)):-delivery_request(var_Location,var_Resource,var_Quantity,var_Sender),retract(delivery_request(var_Location,var_Resource,var_Quantity,var_Sender)),a(message(var_Sender,send_message(accepted(var_Location,var_Resource,var_Quantity),var_Me))),in_stock(var_Warehouse,var_Resource,var_Total),var_NewQty is var_Total-var_Quantity,retract(in_stock(var_Warehouse,var_Resource,var_Total)),assert(in_stock(var_Warehouse,var_Resource,var_NewQty)).

reject_delivery(var_Location,var_Resource,var_Quantity,var_Sender):-a(message(var_Sender,send_message(rejected(var_Location,var_Resource,var_Quantity),var_Me))).

:-dynamic receive/1.

:-dynamic send/2.

:-dynamic isa/3.

receive(send_message(var_X,var_Ag)):-told(var_Ag,send_message(var_X)),call_send_message(var_X,var_Ag).

receive(propose(var_A,var_C,var_Ag)):-told(var_Ag,propose(var_A,var_C)),call_propose(var_A,var_C,var_Ag).

receive(cfp(var_A,var_C,var_Ag)):-told(var_Ag,cfp(var_A,var_C)),call_cfp(var_A,var_C,var_Ag).

receive(accept_proposal(var_A,var_Mp,var_Ag)):-told(var_Ag,accept_proposal(var_A,var_Mp),var_T),call_accept_proposal(var_A,var_Mp,var_Ag,var_T).

receive(reject_proposal(var_A,var_Mp,var_Ag)):-told(var_Ag,reject_proposal(var_A,var_Mp),var_T),call_reject_proposal(var_A,var_Mp,var_Ag,var_T).

receive(failure(var_A,var_M,var_Ag)):-told(var_Ag,failure(var_A,var_M),var_T),call_failure(var_A,var_M,var_Ag,var_T).

receive(cancel(var_A,var_Ag)):-told(var_Ag,cancel(var_A)),call_cancel(var_A,var_Ag).

receive(execute_proc(var_X,var_Ag)):-told(var_Ag,execute_proc(var_X)),call_execute_proc(var_X,var_Ag).

receive(query_ref(var_X,var_N,var_Ag)):-told(var_Ag,query_ref(var_X,var_N)),call_query_ref(var_X,var_N,var_Ag).

receive(inform(var_X,var_M,var_Ag)):-told(var_Ag,inform(var_X,var_M),var_T),call_inform(var_X,var_Ag,var_M,var_T).

receive(inform(var_X,var_Ag)):-told(var_Ag,inform(var_X),var_T),call_inform(var_X,var_Ag,var_T).

receive(refuse(var_X,var_Ag)):-told(var_Ag,refuse(var_X),var_T),call_refuse(var_X,var_Ag,var_T).

receive(agree(var_X,var_Ag)):-told(var_Ag,agree(var_X)),call_agree(var_X,var_Ag).

receive(confirm(var_X,var_Ag)):-told(var_Ag,confirm(var_X),var_T),call_confirm(var_X,var_Ag,var_T).

receive(disconfirm(var_X,var_Ag)):-told(var_Ag,disconfirm(var_X)),call_disconfirm(var_X,var_Ag).

receive(reply(var_X,var_Ag)):-told(var_Ag,reply(var_X)).

send(var_To,query_ref(var_X,var_N,var_Ag)):-tell(var_To,var_Ag,query_ref(var_X,var_N)),send_m(var_To,query_ref(var_X,var_N,var_Ag)).

send(var_To,send_message(var_X,var_Ag)):-tell(var_To,var_Ag,send_message(var_X)),send_m(var_To,send_message(var_X,var_Ag)).

send(var_To,reject_proposal(var_X,var_L,var_Ag)):-tell(var_To,var_Ag,reject_proposal(var_X,var_L)),send_m(var_To,reject_proposal(var_X,var_L,var_Ag)).

send(var_To,accept_proposal(var_X,var_L,var_Ag)):-tell(var_To,var_Ag,accept_proposal(var_X,var_L)),send_m(var_To,accept_proposal(var_X,var_L,var_Ag)).

send(var_To,confirm(var_X,var_Ag)):-tell(var_To,var_Ag,confirm(var_X)),send_m(var_To,confirm(var_X,var_Ag)).

send(var_To,propose(var_X,var_C,var_Ag)):-tell(var_To,var_Ag,propose(var_X,var_C)),send_m(var_To,propose(var_X,var_C,var_Ag)).

send(var_To,disconfirm(var_X,var_Ag)):-tell(var_To,var_Ag,disconfirm(var_X)),send_m(var_To,disconfirm(var_X,var_Ag)).

send(var_To,inform(var_X,var_M,var_Ag)):-tell(var_To,var_Ag,inform(var_X,var_M)),send_m(var_To,inform(var_X,var_M,var_Ag)).

send(var_To,inform(var_X,var_Ag)):-tell(var_To,var_Ag,inform(var_X)),send_m(var_To,inform(var_X,var_Ag)).

send(var_To,refuse(var_X,var_Ag)):-tell(var_To,var_Ag,refuse(var_X)),send_m(var_To,refuse(var_X,var_Ag)).

send(var_To,failure(var_X,var_M,var_Ag)):-tell(var_To,var_Ag,failure(var_X,var_M)),send_m(var_To,failure(var_X,var_M,var_Ag)).

send(var_To,execute_proc(var_X,var_Ag)):-tell(var_To,var_Ag,execute_proc(var_X)),send_m(var_To,execute_proc(var_X,var_Ag)).

send(var_To,agree(var_X,var_Ag)):-tell(var_To,var_Ag,agree(var_X)),send_m(var_To,agree(var_X,var_Ag)).

call_send_message(var_X,var_Ag):-send_message(var_X,var_Ag).

call_execute_proc(var_X,var_Ag):-execute_proc(var_X,var_Ag).

call_query_ref(var_X,var_N,var_Ag):-clause(agent(var_A),var__),not(var(var_X)),meta_ref(var_X,var_N,var_L,var_Ag),a(message(var_Ag,inform(query_ref(var_X,var_N),values(var_L),var_A))).

call_query_ref(var_X,var__,var_Ag):-clause(agent(var_A),var__),var(var_X),a(message(var_Ag,refuse(query_ref(variable),motivation(refused_variables),var_A))).

call_query_ref(var_X,var_N,var_Ag):-clause(agent(var_A),var__),not(var(var_X)),not(meta_ref(var_X,var_N,var__,var__)),a(message(var_Ag,inform(query_ref(var_X,var_N),motivation(no_values),var_A))).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),ground(var_X),meta_agree(var_X,var_Ag),a(message(var_Ag,inform(agree(var_X),values(yes),var_A))).

call_confirm(var_X,var_Ag,var_T):-ground(var_X),statistics(walltime,[var_Tp,var__]),asse_cosa(past_event(var_X,var_T)),retractall(past(var_X,var_Tp,var_Ag)),assert(past(var_X,var_Tp,var_Ag)).

call_disconfirm(var_X,var_Ag):-ground(var_X),retractall(past(var_X,var__,var_Ag)),retractall(past_event(var_X,var__)).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),ground(var_X),not(meta_agree(var_X,var__)),a(message(var_Ag,inform(agree(var_X),values(no),var_A))).

call_agree(var_X,var_Ag):-clause(agent(var_A),var__),not(ground(var_X)),a(message(var_Ag,refuse(agree(variable),motivation(refused_variables),var_A))).

call_inform(var_X,var_Ag,var_M,var_T):-asse_cosa(past_event(inform(var_X,var_M,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(inform(var_X,var_M,var_Ag),var__,var_Ag)),assert(past(inform(var_X,var_M,var_Ag),var_Tp,var_Ag)).

call_inform(var_X,var_Ag,var_T):-asse_cosa(past_event(inform(var_X,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(inform(var_X,var_Ag),var__,var_Ag)),assert(past(inform(var_X,var_Ag),var_Tp,var_Ag)).

call_refuse(var_X,var_Ag,var_T):-clause(agent(var_A),var__),asse_cosa(past_event(var_X,var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(var_X,var__,var_Ag)),assert(past(var_X,var_Tp,var_Ag)),a(message(var_Ag,reply(received(var_X),var_A))).

call_cfp(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_561415,var_Ontology,_561419),_561409),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_cfp(var_A,var_C,var_Ag,_561453)),a(message(var_Ag,propose(var_A,[_561453],var_AgI))),retractall(ext_agent(var_Ag,_561491,var_Ontology,_561495)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_561289,var_Ontology,_561293),_561283),asserisci_ontologia(var_Ag,var_Ontology,var_A),once(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,accept_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_561359,var_Ontology,_561363)).

call_propose(var_A,var_C,var_Ag):-clause(agent(var_AgI),var__),clause(ext_agent(var_Ag,_561177,var_Ontology,_561181),_561171),not(call_meta_execute_propose(var_A,var_C,var_Ag)),a(message(var_Ag,reject_proposal(var_A,[],var_AgI))),retractall(ext_agent(var_Ag,_561233,var_Ontology,_561237)).

call_accept_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(accepted_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(accepted_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(accepted_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_reject_proposal(var_A,var_Mp,var_Ag,var_T):-asse_cosa(past_event(rejected_proposal(var_A,var_Mp,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(rejected_proposal(var_A,var_Mp,var_Ag),var__,var_Ag)),assert(past(rejected_proposal(var_A,var_Mp,var_Ag),var_Tp,var_Ag)).

call_failure(var_A,var_M,var_Ag,var_T):-asse_cosa(past_event(failed_action(var_A,var_M,var_Ag),var_T)),statistics(walltime,[var_Tp,var__]),retractall(past(failed_action(var_A,var_M,var_Ag),var__,var_Ag)),assert(past(failed_action(var_A,var_M,var_Ag),var_Tp,var_Ag)).

call_cancel(var_A,var_Ag):-if(clause(high_action(var_A,var_Te,var_Ag),_560741),retractall(high_action(var_A,var_Te,var_Ag)),true),if(clause(normal_action(var_A,var_Te,var_Ag),_560775),retractall(normal_action(var_A,var_Te,var_Ag)),true).

external_refused_action_propose(var_A,var_Ag):-clause(not_executable_action_propose(var_A,var_Ag),var__).

evi(external_refused_action_propose(var_A,var_Ag)):-clause(agent(var_Ai),var__),a(message(var_Ag,failure(var_A,motivation(false_conditions),var_Ai))),retractall(not_executable_action_propose(var_A,var_Ag)).

refused_message(var_AgM,var_Con):-clause(eliminated_message(var_AgM,var__,var__,var_Con,var__),var__).

refused_message(var_To,var_M):-clause(eliminated_message(var_M,var_To,motivation(conditions_not_verified)),_560557).

evi(refused_message(var_AgM,var_Con)):-clause(agent(var_Ai),var__),a(message(var_AgM,inform(var_Con,motivation(refused_message),var_Ai))),retractall(eliminated_message(var_AgM,var__,var__,var_Con,var__)),retractall(eliminated_message(var_Con,var_AgM,motivation(conditions_not_verified))).

send_jasper_return_message(var_X,var_S,var_T,var_S0):-clause(agent(var_Ag),_560405),a(message(var_S,send_message(sent_rmi(var_X,var_T,var_S0),var_Ag))).

gest_learn(var_H):-clause(past(learn(var_H),var_T,var_U),_560353),learn_if(var_H,var_T,var_U).

evi(gest_learn(var_H)):-retractall(past(learn(var_H),_560229,_560231)),clause(agente(_560251,_560253,_560255,var_S),_560247),name(var_S,var_N),append(var_L,[46,112,108],var_N),name(var_F,var_L),manage_lg(var_H,var_F),a(learned(var_H)).

cllearn:-clause(agente(_560023,_560025,_560027,var_S),_560019),name(var_S,var_N),append(var_L,[46,112,108],var_N),append(var_L,[46,116,120,116],var_To),name(var_FI,var_To),open(var_FI,read,_560123,[]),repeat,read(_560123,var_T),arg(1,var_T,var_H),write(var_H),nl,var_T==end_of_file,!,close(_560123).

send_msg_learn(var_T,var_A,var_Ag):-a(message(var_Ag,confirm(learn(var_T),var_A))).

told(var_From,send_message(var_M)):-true.

told(var_Ag,execute_proc(var__)):-true.

told(var_Ag,query_ref(var__,var__)):-true.

told(var_Ag,agree(var__)):-true.

told(var_Ag,confirm(var__),200):-true.

told(var_Ag,disconfirm(var__)):-true.

told(var_Ag,request(var__,var__)):-true.

told(var_Ag,propose(var__,var__)):-true.

told(var_Ag,accept_proposal(var__,var__),20):-true.

told(var_Ag,reject_proposal(var__,var__),20):-true.

told(var__,failure(var__,var__),200):-true.

told(var__,cancel(var__)):-true.

told(var_Ag,inform(var__,var__),70):-true.

told(var_Ag,inform(var__),70):-true.

told(var_Ag,reply(var__)):-true.

told(var__,refuse(var__,var_Xp)):-functor(var_Xp,var_Fp,var__),var_Fp=agree.

tell(var_To,var_From,send_message(var_M)):-true.

tell(var_To,var__,confirm(var__)):-true.

tell(var_To,var__,disconfirm(var__)):-true.

tell(var_To,var__,propose(var__,var__)):-true.

tell(var_To,var__,request(var__,var__)):-true.

tell(var_To,var__,execute_proc(var__)):-true.

tell(var_To,var__,agree(var__)):-true.

tell(var_To,var__,reject_proposal(var__,var__)):-true.

tell(var_To,var__,accept_proposal(var__,var__)):-true.

tell(var_To,var__,failure(var__,var__)):-true.

tell(var_To,var__,query_ref(var__,var__)):-true.

tell(var_To,var__,eve(var__)):-true.

tell(var__,var__,refuse(var_X,var__)):-functor(var_X,var_F,var__),(var_F=send_message;var_F=query_ref).

tell(var_To,var__,inform(var__,var_M)):-true;var_M=motivation(refused_message).

tell(var_To,var__,inform(var__)):-true,var_To\=user.

tell(var_To,var__,propose_desire(var__,var__)):-true.

meta(var_P,var_V,var_AgM):-functor(var_P,var_F,var_N),var_N=0,clause(agent(var_Ag),var__),clause(ontology(var_Pre,[var_Rep,var_Host],var_Ag),var__),if((eq_property(var_F,var_V,var_Pre,[var_Rep,var_Host]);same_as(var_F,var_V,var_Pre,[var_Rep,var_Host]);eq_class(var_F,var_V,var_Pre,[var_Rep,var_Host])),true,if(clause(ontology(var_PreM,[var_RepM,var_HostM],var_AgM),var__),if((eq_property(var_F,var_V,var_PreM,[var_RepM,var_HostM]);same_as(var_F,var_V,var_PreM,[var_RepM,var_HostM]);eq_class(var_F,var_V,var_PreM,[var_RepM,var_HostM])),true,false),false)).

meta(var_P,var_V,var_AgM):-functor(var_P,var_F,var_N),(var_N=1;var_N=2),clause(agent(var_Ag),var__),clause(ontology(var_Pre,[var_Rep,var_Host],var_Ag),var__),if((eq_property(var_F,var_H,var_Pre,[var_Rep,var_Host]);same_as(var_F,var_H,var_Pre,[var_Rep,var_Host]);eq_class(var_F,var_H,var_Pre,[var_Rep,var_Host])),true,if(clause(ontology(var_PreM,[var_RepM,var_HostM],var_AgM),var__),if((eq_property(var_F,var_H,var_PreM,[var_RepM,var_HostM]);same_as(var_F,var_H,var_PreM,[var_RepM,var_HostM]);eq_class(var_F,var_H,var_PreM,[var_RepM,var_HostM])),true,false),false)),var_P=..var_L,substitute(var_F,var_L,var_H,var_Lf),var_V=..var_Lf.

meta(var_P,var_V,var__):-functor(var_P,var_F,var_N),var_N=2,symmetric(var_F),var_P=..var_L,delete(var_L,var_F,var_R),reverse(var_R,var_R1),append([var_F],var_R1,var_R2),var_V=..var_R2.

meta(var_P,var_V,var_AgM):-clause(agent(var_Ag),var__),functor(var_P,var_F,var_N),var_N=2,(symmetric(var_F,var_AgM);symmetric(var_F)),var_P=..var_L,delete(var_L,var_F,var_R),reverse(var_R,var_R1),clause(ontology(var_Pre,[var_Rep,var_Host],var_Ag),var__),if((eq_property(var_F,var_Y,var_Pre,[var_Rep,var_Host]);same_as(var_F,var_Y,var_Pre,[var_Rep,var_Host]);eq_class(var_F,var_Y,var_Pre,[var_Rep,var_Host])),true,if(clause(ontology(var_PreM,[var_RepM,var_HostM],var_AgM),var__),if((eq_property(var_F,var_Y,var_PreM,[var_RepM,var_HostM]);same_as(var_F,var_Y,var_PreM,[var_RepM,var_HostM]);eq_class(var_F,var_Y,var_PreM,[var_RepM,var_HostM])),true,false),false)),append([var_Y],var_R1,var_R2),var_V=..var_R2.

meta(var_P,var_V,var_AgM):-clause(agent(var_Ag),var__),clause(ontology(var_Pre,[var_Rep,var_Host],var_Ag),var__),functor(var_P,var_F,var_N),var_N>2,if((eq_property(var_F,var_H,var_Pre,[var_Rep,var_Host]);same_as(var_F,var_H,var_Pre,[var_Rep,var_Host]);eq_class(var_F,var_H,var_Pre,[var_Rep,var_Host])),true,if(clause(ontology(var_PreM,[var_RepM,var_HostM],var_AgM),var__),if((eq_property(var_F,var_H,var_PreM,[var_RepM,var_HostM]);same_as(var_F,var_H,var_PreM,[var_RepM,var_HostM]);eq_class(var_F,var_H,var_PreM,[var_RepM,var_HostM])),true,false),false)),var_P=..var_L,substitute(var_F,var_L,var_H,var_Lf),var_V=..var_Lf.

meta(var_P,var_V,var_AgM):-clause(agent(var_Ag),var__),clause(ontology(var_Pre,[var_Rep,var_Host],var_Ag),var__),functor(var_P,var_F,var_N),var_N=2,var_P=..var_L,if((eq_property(var_F,var_H,var_Pre,[var_Rep,var_Host]);same_as(var_F,var_H,var_Pre,[var_Rep,var_Host]);eq_class(var_F,var_H,var_Pre,[var_Rep,var_Host])),true,if(clause(ontology(var_PreM,[var_RepM,var_HostM],var_AgM),var__),if((eq_property(var_F,var_H,var_PreM,[var_RepM,var_HostM]);same_as(var_F,var_H,var_PreM,[var_RepM,var_HostM]);eq_class(var_F,var_H,var_PreM,[var_RepM,var_HostM])),true,false),false)),substitute(var_F,var_L,var_H,var_Lf),var_V=..var_Lf.
