clear all;
rng(278);

% Consumption utility is u(wm + wf) = (wm + wf)^(1 - ucurve) / (1 - ucurve)
% Utility from child     v(nt)      = vfir * nt - vsec * nt^2
% Childcare cost         c_t(a_t)   = -max(0, cint - cslope * at)
% Parameters are         para       = [ucurve, vcurve, cint, cslope]


% Flow utility is stored in "flowu.m"

% Set hypothetical para
% Flow utility para
ucurve = 0.3;
vfir   = 4;
vsec   = 0.5;
cint   = 15;
cslope = 3;
cageint   = -6;
cageslope = 0.1;

% Dynamic parameters, borrowed from Dey Flinn
Beta    = 0.91;  % Capitalized to prevent confusion with beta function
deltam  = 0.032;
deltaf  = 0.05;
lambdam = 0.3;
lambdaf = 0.2;
mum     = 2.8;
muf     = 2.303;
sigmam  = 0.139;
sigmaf  = 0.135;

%Child arrival probability
Gamma = 0.6;  % Capitalized to prevent confusion with the gamma function

%%
% Set state space

% Set demographic (outside income)
y = 0.5;

%%%%%%%%%%
% Set terminal value to be zero (for now).
%%%%%%%%%%
term = 0;

% State space:
% wm, wf: continuous, following log-normal. 
% Discretize them into 10 points (for now)
wm = linspace(5, 20, 10);
wf = linspace(5, 20, 10);

% Number of children: up to 5. Child age up to 5 (for now, because at age 5 
% c(at)=0.

% Update 5/22 (model v1.2 update)
% Slight modification from the paper made. Used to be: if nt=0, at=0 and no
% evolution.
% Now: no matter what nt is, at evolves in the same way, but if nt=0 then at
% does not show up in utility.
% This makes the evolution of state space simpler.
nt = 0:5;
at = 1:5;

%%
% The size of the state space is 10 * 10 * 6 * 5 = 3000. 
% Make it a one-dimensional vector.
[aux1, aux2, aux3, aux4] = ndgrid(wm, wf, nt, at);
state        = [aux1(:), aux2(:), aux3(:), aux4(:)];
wmstate      = state(:, 1);
wfstate      = state(:, 2);
ntstate      = state(:, 3);
atstate      = state(:, 4);
% Order of state: wm first, then wf, then nt, and finally at changes.
sizestate    = numel(state(:, 1));

clear aux1 aux2 aux3 aux4



%%
% To use arrayfun later, make parameters 3000*1 dimensional object as well.
simucurve = ones(sizestate, 1) * ucurve;
simvfir   = ones(sizestate, 1) * vfir;
simvsec   = ones(sizestate, 1) * vsec;
simcint   = ones(sizestate, 1) * cint;
simcslope = ones(sizestate, 1) * cslope;
simcageint   = ones(sizestate, 1) * cageint;
simcageslope   = ones(sizestate, 1) * cageslope;

yy = ones(sizestate, 1) * y;

% Also, make working decision 3000*1 dimensional
work   = ones(sizestate, 1);
nowork = zeros(sizestate, 1);

% Now all the inputs to the function "flowu" are set as 3000*1 vectors.

%%
%%%%%%%%%%
% From here, I denote "choice-based value functions" as Vee,Veu,Vue,Vuu.
% These are functions of state space AND CHOICES.
% I denote "value functions" as Vmf, Vm, Vf, Vu. These are functions only
% of state space.

% Solve DP for 20 periods. 
period = 20;

% To start backward induction, we need to have utility corresponding to four
% choices (male/female work/not work) at the terminal period.

% Utility is nothing but just flow utility. So calculate flow utility at all
% the state points.

% Now we are in terminal period
t  = period;
tt = ones(sizestate,1)*t;

% Choice-based value functions corresponding to four cases.
% Man work, woman work
VeeT = arrayfun(@flowu, simucurve, simvfir, simvsec, simcint,...
                simcslope, simcageint, simcageslope, wmstate, wfstate, ntstate,...
                atstate, work, work, yy, tt) + term;
            
% Man work, woman not
VeuT = arrayfun(@flowu, simucurve, simvfir, simvsec, simcint,...
                simcslope, simcageint, simcageslope, wmstate, wfstate, ntstate,...
                atstate, work, nowork, yy, tt) + term;      
            
% Man not, woman work
VueT = arrayfun(@flowu, simucurve, simvfir, simvsec, simcint,...
                simcslope, simcageint, simcageslope, wmstate, wfstate, ntstate,...
                atstate, nowork, work, yy, tt) + term;
            
% Man not, woman not
VuuT = arrayfun(@flowu, simucurve, simvfir, simvsec, simcint,...
                simcslope, simcageint, simcageslope, wmstate, wfstate, ntstate,...
                atstate, nowork, nowork, yy, tt) + term;
            

%%%%%%%%%%%%%%%%
% Might worth considering%
% Full state space only needed for ee. For uu, it only depends on nt and at.
% i.e. 30 dimensions are enough.
% Does this lose speed? I don't know. In calculating Emax later, I need to
% boost VuuT to 3000*1 by taking Kronecker product anyway.
%%%%%%%%%%%%%%%%


%Construct matrices to store values and policies. The dimension is number of state space *
%number of periods
Veemat  = zeros(sizestate,period);
Veumat  = zeros(sizestate,period);
Vuemat  = zeros(sizestate,period);
Vuumat  = zeros(sizestate,period);
Vmfmat  = zeros(sizestate,period);
Vmmat   = zeros(sizestate,period);
Vfmat   = zeros(sizestate,period);
Vumat   = zeros(sizestate,period);
Pmfmat  = zeros(sizestate,period);
Pmmat   = zeros(sizestate,period);
Pfmat   = zeros(sizestate,period);
Pumat   = zeros(sizestate,period);
Pbeemat = zeros(sizestate,period);
Pbeumat = zeros(sizestate,period);
Pbuemat = zeros(sizestate,period);
Pbuumat = zeros(sizestate,period);
Pwbeemat = zeros(sizestate,period);
Pwbeumat = zeros(sizestate,period);
Pwbuemat = zeros(sizestate,period);
Pwbuumat = zeros(sizestate,period);

% Store terminal period value that I calculated above.
Veemat(:,t) = VeeT;
Veumat(:,t) = VeuT;
Vuemat(:,t) = VueT;
Vuumat(:,t) = VuuT;


%%
%%%%%%
% Instruction of iteration
%%%%%%

% Below, I iterate the economy from period 19 to period 1.
% Each step proceeds as follows. First, given choice based value functions at
% period t+1 (conditional on realized wage and choice), calculate 
% value functions at period t+1. i.e. calculate optimal choice at period t+1
% given offer/job destruction.
% Second, using value function at t+1 obtained, calculate  EMAX by taking
% appropriate integrals. i.e. RHS of equations (1)-(24) in the paper.
% Finally, calculate choice-based value functions at period t (LHS=RHS, conditional
% on realized wage at t and choice at t). This
% completes period t's iteration.


%Iteration from period 19 to priod 1.
%Set period 20's choice based value functions as initial value.
Veeup = VeeT;
Veuup = VeuT;
Vueup = VueT;
Vuuup = VuuT;

for tau = 1:(period-1)
t = period-tau;

%Use the updated choice based value functions at period t+1.
Vee = Veeup;
Veu = Veuup;
Vuu = Vuuup;
Vue = Vueup;


% Step 1: Solve period t+1's optimal choice. i.e. Derive value function at t+1.

% Two choices: work and fertility. First consider working decision.

% Working decision
% Calculate optimal choice conditional on whether each spouse can make a choice or not.

% If two of them can choose whether to work (two offers, one already working 
% and one offer,etc)
% Pick the choice that maximizes value
aux       = [Vee,Veu,Vue,Vuu];
[Vmf,Pmf] = max(aux,[],2);
% mf implies both of them can work.

% If only  male can choose (female not getting offer, job just
% destroyed etc...)
aux2    = [Veu,Vuu];
[Vm,aux4] = max(aux2,[],2);
Pm = 2*aux4; % To make the indeces of choices aligned

% If only female can choose
aux3    = [Vue,Vuu];
[Vf,aux5] = max(aux3,[],2);
Pf = 2+aux5; % To make the indeces of choices aligned

% If noone can work (both unemployed previously and no offers, or one
% unemployed previously and the other job destroyed, etc)
Vu = Vuu;
Pu = 4*ones(sizestate,1); % To make the indeces of choices aligned

clear aux aux2 aux3 aux4 aux5
% This yields policy function and value functions (conditional only on
% state values and NOT on choices). 


% Also, I need to solve for policy function for fertility. But I will solve
% it jointly with calculating Emax functions, which is computationally
% simpler.




% Second step: Compute EMAX.
% i.e. Given the optimal choice (for work) at period t+1, calculate RHS of equation 
% (1)-(24).

% To compute Emax taking expectation over wage needed. 
% Assume log-normal wage.
distwm = lognpdf(wm,mum,sigmam);
distwf = lognpdf(wf,muf,sigmaf);


% Note that the variable we are taking expectation over differs depending on
% which state we come from. Emax is path-dependent. Need for computing them each by each.
% Start from equation number (1)-(6) in the paper.

% Equation 2 requires taking expectation of Vmf over wm
% Calculate 300*1 vector corresponding to expectation over wm.
aux = (distwm * reshape(Vmf, numel(wm), numel(wf)*numel(nt)*numel(at))).';
% Align the order of rows to match them (i.e. LHS state (wf,nt,at) =RHS
% state (wf,nt,at+1) for each row).
% Delete top rows with at=1.
aux(1 : numel(wf)*numel(nt)) = [];
%%%%%%%%%%%Treatment at corner%%%%%%%%%%%%%%%%%
% If at=5, then set a{t+1}=5 as well (it doesn't matter anyway).
% Do the same for all cases below.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
aux((1+numel(wf)*numel(nt)*(numel(at)-1)) : numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wf)*numel(nt)*(numel(at)-2)) : numel(wf)*numel(nt)*(numel(at)-1));
%Finally, make it 3000*1 again.
eq2 = kron(aux, ones(numel(wm),1));
clear aux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equation 2 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%equation 3 requires expectation of Vm over wm.
aux = (distwm * reshape(Vm,numel(wm), numel(wf)*numel(nt)*numel(at))).';
%Same procedure as above.
aux(1 : numel(wf)*numel(nt)) = [];
aux((1+numel(wf)*numel(nt)*(numel(at)-1)) : numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wf)*numel(nt)*(numel(at)-2)) : numel(wf)*numel(nt)*(numel(at)-1));

eq3 = kron(aux, ones(numel(wm),1));
clear aux

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Equation 3 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Equation 4 just requires alignment of at.
aux=Vu;
aux(1:numel(wm)*numel(wf)*numel(nt))=[];
aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));

eq4=aux;
clear aux

%Same for equation 6. No choices in this case, so use Vue instead of Vf.
aux=Vue;
aux(1:numel(wm)*numel(wf)*numel(nt))=[];
aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));

eq6=aux;
clear aux

%Now, for equation 5, I need to two things\ solve optimization at t+1 concerning 
%childbirth (which I didn't do above). i.e. compare Vue(nt,at+1) and Vue(nt+1,1).
%Since their job status hasn't changed from the previous period (essentially
%no choice today. Last period's optimal choice=today's optimal choice), I
%only need Vue and not Vf.

%Then, I need to align the state space values to make equation 5 hold.
%Do these simultaneously.

%If give a birth,
%add 1 to Nt, at goes back to 1.
%First, slash Nt=0 region and at>1 region. 
aux=Vue((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
%%%%%%%%%%%%%%%Treatment at corner%%%%%%%%%%%%%%%%
%Once N=5, then by giving a birth N stays 5. Only at is re-set to 1
%This makes it suboptimal to give a birth when N=5 by construction.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This gives me Nt \in [1,2,3,4,5,5] and at=1 region.
aux((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately aligned state
%space values.
aux2=repmat(aux,numel(at),1);

%If not give a birth, same as before.
aux3=Vue;
aux3(1:numel(wm)*numel(wf)*numel(nt))=[];
aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
aux4=[aux3,aux2];

%Value and policy
[eq5,Pbue]=max(aux4,[],2);
Pwbue=3*ones(sizestate,1);

%Pbue=1 not give birth, =2 give birth. I separate birth choice (stored in
%Pbue) from corresponding work choice (stored in Pwbue). In this case,
%there's no work choice involved, so Pwbue contains "only female keeps
%working".

clear aux aux2 aux3 aux4


%Equation 8=Equation 6.
eq8=eq6;

%Equation 9
aux=Veu;
aux(1:numel(wm)*numel(wf)*numel(nt))=[];
aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
eq9=aux;
clear aux

%Equation 10=Equation 4.
eq10=eq4;

%Eguation 11=similar to equation 5.
%If not giving birth,
aux=Vee;
aux(1:numel(wm)*numel(wf)*numel(nt))=[];
aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
%If giving birth without quitting, same procedure as the first part of
%equation 5.
aux2=Vee((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
aux2((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux2((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately updated state
%space.
aux3=repmat(aux2,numel(at),1);

%If give birth and male quit, same as above using Vue.
aux4=Vue((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
aux4((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux4((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately updated state
%space.
aux5=repmat(aux4,numel(at),1);

%If give birth and female quit
aux6=Veu((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
aux6((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux6((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately updated state
%space.
aux7=repmat(aux6,numel(at),1);
aux8=[aux,aux3,aux5,aux7];

%Policy function denoted as Pbee.
[eq11,aux9]=max(aux8,[],2);
%Policy: 1 =no give birth, 2=give birth no quit, 3=give birth male quit, 
%4=give birth female quit.

% Split this policy into two: work and fertility
Pbee = zeros(sizestate,1);
Pbee(aux9>1) = 1;
Pwbee = zeros(sizestate,1);
Pwbee(aux9<3) = 1;
Pwbee(aux9==3) = 3;
Pwbee(aux9==4) = 2;
% If Pbee =2, give birth, =1 no give birth.
% If Pwbee=1, both work, =2 only male work, =3 only female work.
% In this state, it makes a difference to separate the two choices.

clear aux aux2 aux3 aux4 aux5 aux6 aux7 aux8 aux9 aux10


%Equation 12
aux=Vee;
aux(1:numel(wm)*numel(wf)*numel(nt))=[];
aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
eq12=aux;
clear aux


%Equation 14
%Take expectation of Vmf over both wm and wf.
%First, take expectation over wm. Exactly the same procedure as in equation
%2.
aux=(distwm*reshape(Vmf,numel(wm),numel(wf)*numel(nt)*numel(at))).';
aux(1:numel(wf)*numel(nt))=[];
aux((1+numel(wf)*numel(nt)*(numel(at)-1)):numel(wf)*numel(nt)*numel(at))=...
    aux((1+numel(wf)*numel(nt)*(numel(at)-2)):numel(wf)*numel(nt)*(numel(at)-1));
aux2=kron(aux,ones(numel(wm),1));

%Now, take expectation over wf. No need for adjustment of nt anymore. So
%just take expectation, and restore the size by Kronecker.
%Sort rows with respect to wf, so that I can use simple multiplicative form.
aux3=[state,aux2];
aux4=sortrows(aux3,[4,3,1]);
aux5=aux4(:,5);
%Do the same as above.
aux6=(distwf*reshape(aux5,numel(wf),numel(wm)*numel(nt)*numel(at))).';
aux7=kron(aux6,ones(numel(wf),1));
%Re-sort them to original order
aux8=[state,aux7];
aux9=sortrows(aux8,[4,3,2]);

eq14=aux9(:,5);
clear aux aux2 aux3 aux4 aux5 aux6 aux7 aux8 aux9

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Equation 14 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Equation 15=Equation 3
eq15=eq3;

%Equation 16
%Sort rows with respect to wf.
aux=[state,Vf];
aux2=sortrows(aux,[4,3,1]);
aux3=aux2(:,5);
%Do the same thing as equation 3.
aux4=(distwf*reshape(aux3,numel(wf),numel(wm)*numel(nt)*numel(at))).';
aux4(1:numel(wm)*numel(nt))=[];
aux4((1+numel(wm)*numel(nt)*(numel(at)-1)):numel(wm)*numel(nt)*numel(at))=...
    aux4((1+numel(wm)*numel(nt)*(numel(at)-2)):numel(wm)*numel(nt)*(numel(at)-1));
aux5=kron(aux4,ones(numel(wf),1));
%Re-sort them to original order
aux6=[state,aux5];
aux7=sortrows(aux6,[4,3,2]);

eq16=aux7(:,5);
clear aux aux2 aux3 aux4 aux5 aux6 aux7

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Equation 16 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Equation 17
%Similar to equation 5
%If give a birth,
%add 1 to Nt, at goes back to 1.
%First, slash Nt=0 region and at>1 region. 
aux=Vuu((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
aux((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately updated state
%space.
aux2=repmat(aux,numel(at),1);

%If not give a birth, same as before.
aux3=Vuu;
aux3(1:numel(wm)*numel(wf)*numel(nt))=[];
aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
aux4=[aux3, aux2];

%Policy function denoted as Pbuu.
[eq17,Pbuu]=max(aux4,[],2);
Pwbuu=4*ones(sizestate,1);

clear aux aux2 aux3 aux4


%Equation 18=equation 4
eq18=eq4;


%Case eu is the mirror image of case ue, with just re-ordering required.
%Equation 20 (see model version 1.3 updated on May 22)
%Sort rows with respect to wf.
aux=[state,Vmf];
aux2=sortrows(aux,[4,3,1]);
aux3=aux2(:,5);
%Do the same thing as equation 2.
aux4=(distwf*reshape(aux3,numel(wf),numel(wm)*numel(nt)*numel(at))).';
%Align the order of rows to match them (i.e. LHS state (wf,nt,at) =RHS
%state (wf,nt,at+1) for each row).
%Delete top rows with at=0.
aux4(1:numel(wm)*numel(nt))=[];
aux4((1+numel(wm)*numel(nt)*(numel(at)-1)):numel(wm)*numel(nt)*numel(at))=...
    aux4((1+numel(wm)*numel(nt)*(numel(at)-2)):numel(wm)*numel(nt)*(numel(at)-1));
aux5=kron(aux4,ones(numel(wf),1));
%Re-sort them to original order
aux6=[state,aux5];
aux7=sortrows(aux6,[4,3,2]);


eq20=aux7(:,5);
clear aux aux2 aux3 aux4 aux5 aux6 aux7

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Equation 20 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%equation 21 =Equation 16
eq21=eq16;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Equation 21 to be replaced by simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Equation 22 =Equation 4
eq22=eq4;

%Equation 23 similar to equation 5.
%If give a birth,
%add 1 to Nt, at goes back to 1.
%First, slash Nt=0 region and at>1 region. 
aux=Veu((1+numel(wm)*numel(wf)):numel(wm)*numel(wf)*numel(nt));
%This gives me Nt \in [1,2,3,4,5,5] and at=1 region.
aux((1+numel(wm)*numel(wf)*(numel(nt)-1)):numel(wm)*numel(wf)*numel(nt))=aux((1+numel(wm)*numel(wf)*(numel(nt)-2)):numel(wm)*numel(wf)*(numel(nt)-1));
%Repeat them numel(at) times. That gives me the appropriately updated state
%space.
aux2=repmat(aux,numel(at),1);

%If not give a birth, same as before.
aux3=Veu;
aux3(1:numel(wm)*numel(wf)*numel(nt))=[];
aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-1)):numel(wm)*numel(wf)*numel(nt)*numel(at))=...
    aux3((1+numel(wm)*numel(wf)*numel(nt)*(numel(at)-2)):numel(wm)*numel(wf)*numel(nt)*(numel(at)-1));
aux4=[aux3,aux2];

%Policy function denoted as Pbeu.
[eq23,Pbeu]=max(aux4,[],2);
Pwbeu = 2*ones(sizestate,1);

clear aux aux2 aux3 aux4

%Equation 24 =Equation 9.
eq24=eq9;

%All equations on RHS derived.
%EMAX derivation done.

%Step 3
%Choice-based value function at period t (conditional on choice and state at t).
%Just calculate the four equations on the paper.
tt=ones(sizestate,1)*t;

%State ue
Vueup=arrayfun(@flowu,simucurve,simvfir,simvsec,simcint,simcslope, simcageint, simcageslope,wmstate,wfstate,ntstate,atstate,nowork,work,yy,tt)+Beta*lambdam*(1-deltaf)*eq2+Beta*lambdam*deltaf*eq3+Beta*(1-lambdam)*deltaf*eq4+Beta*(1-lambdam)*Gamma*(1-deltaf)*eq5+Beta*(1-lambdam)*(1-Gamma)*(1-deltaf)*eq6;
%State ee
Veeup=arrayfun(@flowu,simucurve,simvfir,simvsec,simcint,simcslope, simcageint, simcageslope,wmstate,wfstate,ntstate,atstate,work,work,yy,tt)+Beta*deltam*(1-deltaf)*eq8+Beta*(1-deltam)*deltaf*eq9+Beta*deltam*deltaf*eq10+Beta*Gamma*(1-deltam)*(1-deltaf)*eq11+Beta*(1-Gamma)*(1-deltam)*(1-deltaf)*eq12;
%State uu
Vuuup=arrayfun(@flowu,simucurve,simvfir,simvsec,simcint,simcslope, simcageint, simcageslope,wmstate,wfstate,ntstate,atstate,nowork,nowork,yy,tt)+Beta*lambdam*lambdaf*eq14+Beta*lambdam*(1-lambdaf)*eq15+Beta*(1-lambdam)*lambdaf*eq16+Beta*(1-lambdam)*(1-lambdaf)*Gamma*eq17+Beta*(1-lambdam)*(1-lambdaf)*(1-Gamma)*eq18;
%State eu
Veuup=arrayfun(@flowu,simucurve,simvfir,simvsec,simcint,simcslope, simcageint, simcageslope,wmstate,wfstate,ntstate,atstate,work,nowork,yy,tt)+Beta*lambdaf*(1-deltam)*eq20+Beta*lambdaf*deltam*eq21+Beta*(1-lambdaf)*deltam*eq22+Beta*(1-lambdaf)*(1-deltam)*Gamma*eq23+Beta*(1-lambdaf)*(1-deltam)*(1-Gamma)*eq24;


%Everything is done for period t. Store them in the matrices created
%before. Note that calculated policies are at period t+1. So they are
%allocated to t+1 column. For value functions (not choice-based), I put it in t+1
%column as well (doesn't matter).
Veemat(:,t)=Veeup;
Veumat(:,t)=Veuup;
Vuemat(:,t)=Vueup;
Vuumat(:,t)=Vuuup;
Vmfmat(:,t+1)=Vmf;
Vmmat(:,t+1)=Vm;
Vfmat(:,t+1)=Vf;
Vumat(:,t+1)=Vu;
Pmfmat(:,t+1)=Pmf;
Pmmat(:,t+1)=Pm;
Pfmat(:,t+1)=Pf;
Pumat(:,t+1)=Pu;
Pbeemat(:,t+1)=Pbee;
Pbeumat(:,t+1)=Pbeu;
Pbuemat(:,t+1)=Pbue;
Pbuumat(:,t+1)=Pbuu;
Pwbeemat(:,t+1)=Pwbee;
Pwbeumat(:,t+1)=Pwbeu;
Pwbuemat(:,t+1)=Pwbue;
Pwbuumat(:,t+1)=Pwbuu;

% 4 value functions (mf,m,f,u) and 4 choice based value functions (ee,eu,ue,uu).
% 4 Policy functions concerning working choice (Pmf, Pm, Pf, Pu), 4 policy
% functions concerning working choice when child arrives (Pwbee, Pwbeu, Pwbue,
% Pwbuu) and 4 policies concerning childbirth (Pbee, Pbeu, Pbue, Pbuu).
% 
% Pmfmat 1 = both work, 2 = male work, 3 = female work, 4 = none work
% Pfmat 3 = female work, 4 = none work
% Pmmat 2 = male work, 4= none work
% Pumat 4 = none work
% Pwbeemat 1= both work, 2 = male work, 3 = female work,
% Pwbeumat 2= male work
% Pwbuemat 3= female work
% Pwbuumat 4= none work

% In other words, 1= both work, 2 = male work, 3= female work and 4 =none
% work no matter what the states are. This is why I aligned the number
% above (e.g. lines 228,233,238).

% Pbeemat, Pbuemat, Pbeumat, Pbuumat 1 = no give birth, 2 = give birth.

end


%%
% I noticed that I need Policy at period 1, so let me calculate it here in
% addition.
aux       = [Veemat(:,1),Veumat(:,1),Vuemat(:,1),Vuumat(:,1)];
[Vmfmat(:,1),Pmfmat(:,1)] = max(aux,[],2);

aux2      = [Veumat(:,1),Vuumat(:,1)];
[Vmmat(:,1),aux4] = max(aux2,[],2);
Pmmat(:,1) = 2*aux4;

aux3      = [Vuemat(:,1),Vuumat(:,1)];
[Vfmat(:,1), aux5] = max(aux3,[],2);
Pfmat(:,1) = 2+aux5;

Vumat(:,1) = Vuumat(:,1);
Pumat(:,1) = 4*ones(sizestate,1);

clear aux aux2 aux3 aux4 aux5


%%
% Simulation of 10000 individuals
nsim = 10000;


% Draw shocks: job arrival, wage offer, job destruction (for both spouses)
% and child arrival per period. In total, number of period * 7 shocks.

% Job arrival
simofferm = reshape(binornd(1,lambdam,period*nsim,1),nsim,period);
simofferf = reshape(binornd(1,lambdaf,period*nsim,1),nsim,period);

% Wage offer, ignoring normality for now. Wage taken from uniform over wm
% and wf space.
% Generate random indeces 
simwagem = reshape(randi(10,period*nsim,1),nsim,period);
% Pick elements of wm with corresponding indeces
simwagemvalue = wm(simwagem);

rng(21890);
simwagef = reshape(randi(10,period*nsim,1),nsim,period);
simwagefvalue = wf(simwagef);

%Job destruction
simdestm = reshape(binornd(1,deltam,period*nsim,1),nsim,period);
simdestf = reshape(binornd(1,deltaf,period*nsim,1),nsim,period);


% Child arrival
simchildarr = reshape(binornd(1,Gamma,period*nsim,1),nsim,period);


%Create matrix to store behaviors and realized states
simwork = zeros(nsim,period);
simstate = zeros(nsim,period);
simnkids = zeros(nsim,period);

% Calculate initial period
% Initial arrival rate set higher so that we have more employed young
% workers
initofferm = reshape(binornd(1,0.8,period*nsim,1),nsim,period);
initofferf = reshape(binornd(1,0.7,period*nsim,1),nsim,period);

% Set initial working status and state
for i = 1:nsim
    if initofferm(i,1) + initofferf(i,1)==2 %Two offers
        simstate(i,1) = simwagem(i,1)*simwagef(i,1);
        simwork(i,1) = Pmfmat(simwagem(i,1)+(simwagef(i,1)-1)*numel(wm),1);
        
    elseif initofferm(i,1)==1               %Only male offer
        simstate(i,1) = simwagem(i,1)*simwagef(i,1);
        simwork(i,1) = Pmmat(simwagem(i,1)+(simwagef(i,1)-1)*numel(wm),1);
        
    elseif initofferf(i,1)==1               %Only female offer
        simstate(i,1) = simwagem(i,1)*simwagef(i,1);
        simwork(i,1) = Pfmat(simwagem(i,1)+(simwagef(i,1)-1)*numel(wm),1);
        
    else                                    %No offer
        simstate(i,1) = simwagem(i,1)*simwagef(i,1);
        simwork(i,1) = Pumat(simwagem(i,1)+(simwagef(i,1)-1)*numel(wm),1);
        
    end
end

%Now solve for the sequence of choices
% for i = 1:nsim
%     for t = 2:period
%         
%         if simwork(i,t-1)==1 % If both worked in the previous period
%             
%             if simdestm(i,t)+simdestf(i,t)==2 % If both jobs destroyed
%                 simstate(i,t) = simstate(i,t-1)+numel(wm)*numel(wf)*numel(nt);
%                 %State at evolves by one. Everything else stays the same.
%                 simwork(i,t) = Pumat(simstate(i,t),t);
%             
%             elseif simdestm(i,t)==1 %Only male job destroyed
%                 simstate(i,t) = simstate(i,t-1)+numel(wm)*numel(wf)*numel(nt);
%                      %State at evolves by one. Everything else stays the same.
%                 simwork(i,t) = Pfmat(simstate(i,t),t);
%                 
%             elseif simdestf(i,t)==1 % Only female job destroyed
%                 simstate(i,t) = simstate(i,t-1)+numel(wm)*numel(wf)*numel(nt);
%                      %State at evolves by one. Everything else stays the same.
%                 simwork(i,t) = Pmmat(simstate(i,t),t);
%                 
%             elseif simchildarr(i,t)==1 %Child arrives
%                 simnkids(i,t) = simnkids(i,t-1)+Pbeemat(i,t)-1;
%                      %If give birth, add 1 to "simnkids".
%                 if Pbeemat(i,t)== 1
%                     % State evolution depends on choices. If not giving a birth
%                 simstate(i,t) = simstate(i,t-1)+numel(wm)*numel(wf)*numel(nt);
%                      %then state at evolves by one. Everything else stays the same.
%                 elseif Pbeemat (i,t)>1
%                     % If giving a birth,
%                 simstate(i,t) = simstate(i,t-1)+
%                 
%                 
%         if simofferm(i,t)+simofferf(i,t)==2
%             
%             
% 
% 
% 
% 


