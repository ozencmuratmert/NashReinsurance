function S = aggregate_SL(C, P)
% AGGREGATE_SL  Discounted profits and risk capital over [0,T] for every
% stop-loss retention k on the grid C.g (Step 3 of Section 4.3).
%
%   P_I(k) = theta * sum_i w_i E[min(X_i,k)],  P_R(k) = theta * sum_i w_i E[(X_i-k)^+]
%   K_I(k) = sum_i w_i max(rho(C_I) - E[C_I], 0), similarly K_R,  rho = VaR or TVaR
%   RAROC  = P / K   (computed in run_strategies)
% KI, KR are stored as (risk measure: 1=VaR 2=TVaR) x (alpha index) x (k).

w  = C.w;  th = P.theta;
EI = C.EX - C.SL;             % E[min(X,k)]  (n x G)
ER = C.SL;                    % E[(X-k)^+]

S.k  = C.g;
S.PI = th * (w' * EI);
S.PR = th * (w' * ER);

A = numel(P.alpha_levels);
G = numel(C.g);
S.KI = zeros(2, A, G);  S.KR = zeros(2, A, G);    % (VaR/TVaR, alpha, k)
for a = 1:A
    V = C.V(:,:,a);  B = C.B(:,:,a);
    % VaR:  VaR(min(X,k)) = min(q,k) = q - (q-k)^+,  VaR((X-k)^+) = (q-k)^+
    rhoI = C.q(:,a) - V;      rhoR = V;
    S.KI(1,a,:) = w' * max(rhoI - EI, 0);
    S.KR(1,a,:) = w' * max(rhoR - ER, 0);
    % TVaR: TVaR(min(X,k)) = TX - B,  TVaR((X-k)^+) = B
    rhoI = C.TX(:,a) - B;     rhoR = B;
    S.KI(2,a,:) = w' * max(rhoI - EI, 0);
    S.KR(2,a,:) = w' * max(rhoR - ER, 0);
end
end
