function L = aggregate_LSL(C, P)
% AGGREGATE_LSL  Discounted profits and risk capital for every limited
% stop-loss contract (k, m), k < m, with k and m on the same grid C.g.
%
% Uses C_R = (X-k)^+ - (X-m)^+ and C_I = X - C_R. Both are non-decreasing
% in X, hence
%   E[C_R]    = SL(k) - SL(m)
%   VaR(C_R)  = V(k) - V(m),     VaR(C_I)  = q  - VaR(C_R)
%   TVaR(C_R) = B(k) - B(m),     TVaR(C_I) = TX - TVaR(C_R)
% Matrices are G x G with rows = k index and columns = m index; entries
% with m <= k are set to NaN.

w  = C.w;  th = P.theta;  g = C.g(:)';  G = numel(g);
n  = P.n_steps;  A = numel(P.alpha_levels);

mask = triu(true(G), 1);                 % m > k

% Profits are separable: P_R(k,m) = a(k) - a(m)
aR   = th * (w' * C.SL);                 % 1 x G
aEX  = th * (w' * C.EX);                 % scalar
L.PR = aR(:) - aR;                       % G x G
L.PI = aEX - L.PR;

L.KI = zeros(G, G, 2, A);  L.KR = zeros(G, G, 2, A);
for a = 1:A
    for typ = 1:2
        KI = zeros(G);  KR = zeros(G);
        for i = 1:n
            if typ == 1
                D  = C.V(i,:,a) - C.SL(i,:);          % rho_R(s) - E_R(s), VaR
                cI = C.q(i,a)  - C.EX(i);
            else
                D  = C.B(i,:,a) - C.SL(i,:);          % TVaR
                cI = C.TX(i,a) - C.EX(i);
            end
            d  = D(:) - D;                             % G x G
            KR = KR + w(i) * max(d, 0);
            KI = KI + w(i) * max(cI - d, 0);
        end
        L.KR(:,:,typ,a) = KR;
        L.KI(:,:,typ,a) = KI;
    end
end

L.k = g;  L.m = g;  L.mask = mask;
L.PI(~mask) = NaN;  L.PR(~mask) = NaN;
end
