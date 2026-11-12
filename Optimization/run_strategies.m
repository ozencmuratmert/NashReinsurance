function R = run_strategies(PI, PR, KI, KR, P)
% RUN_STRATEGIES  The five criteria of Section 3.4 / Tables 4-5 on a set of
% candidate contracts (vectors or matrices of equal size; NaN = infeasible).
%
%   1 Max RAROC_I subject to RAROC_R >= R_bar
%   2 Max Profit_I
%   3 Max risk-adjusted Profit_I  = P_I - r_coc * K_I
%   4 Nash product  P_I * P_R  (P_I, P_R > 0)
%   5 Max total profit  P_I + P_R
%
% Returns R(s).idx (linear index of the optimum) and the metrics there.

RI = safe_div(PI, KI);
RR = safe_div(PR, KR);
% Note: when (almost) all simulated claims exceed k, the insurer's retained
% layer min(X,k) is (almost) riskless, K_I -> 0 and RAROC_I is undefined.
ok = ~isnan(PI) & ~isnan(PR);

names = {'Max RAROC$_I$ (constrained)', 'Max Profit$_I$', ...
         'Max RiskAdjProfit$_I$', 'Nash Product', 'Max Total Profit'};
obj = cell(1,5);
obj{1} = RI;   obj{1}(~(ok & RR >= P.R_bar & KI > 1e-12)) = -Inf;
obj{2} = PI;   obj{2}(~ok) = -Inf;
obj{3} = PI - P.r_coc*KI;  obj{3}(~ok) = -Inf;
obj{4} = PI .* PR;  obj{4}(~(ok & PI > 0 & PR > 0)) = -Inf;
obj{5} = PI + PR;   obj{5}(~ok) = -Inf;

for s = 1:5
    o = obj{s}(:);  o(isnan(o)) = -Inf;
    [best, idx] = max(o);
    R(s).name = names{s};
    R(s).feasible = isfinite(best);
    R(s).idx  = idx;
    R(s).PI = PI(idx);  R(s).PR = PR(idx);
    R(s).RI = RI(idx);  R(s).RR = RR(idx);
end
end

function r = safe_div(a, b)
% RAROC is reported as undefined (NaN, printed '--') when the risk capital
% is negligible relative to the profit (|K| < 1e-6 |P|).
r = a ./ b;
r(b <= 1e-6 * max(abs(a), 1)) = NaN;
end
