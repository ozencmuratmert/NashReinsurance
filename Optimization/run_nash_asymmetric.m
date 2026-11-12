function R = run_nash_asymmetric(PI, PR, KI, KR, P)
% RUN_NASH_ASYMMETRIC  Asymmetric Nash bargaining (Appendix E):
%   maximise alpha_b*log(P_I) + (1-alpha_b)*log(P_R) over the candidates,
% for every alpha_b in P.alpha_b. Also records whether the optimum sits on
% the boundary of the grid (a warning sign that the grid is too narrow).

ok = ~isnan(PI) & ~isnan(PR) & PI > 0 & PR > 0;
for b = 1:numel(P.alpha_b)
    ab  = P.alpha_b(b);
    f   = -Inf(size(PI));
    f(ok) = ab*log(PI(ok)) + (1-ab)*log(PR(ok));
    [~, idx] = max(f(:));
    R(b).alpha_b = ab;
    R(b).idx = idx;
    R(b).PI = PI(idx);  R(b).PR = PR(idx);
    R(b).RI = sdiv(PI(idx), KI(idx));
    R(b).RR = sdiv(PR(idx), KR(idx));
    R(b).ratio = PI(idx) / PR(idx);
    R(b).theory_ratio = ab / (1-ab);
    if isvector(PI)
        R(b).on_boundary = (idx == 1) || (idx == numel(PI));
    else
        [ik, im] = ind2sub(size(PI), idx);
        R(b).on_boundary = (ik == 1);
    end
end
end

function r = sdiv(a, b)
if b <= 1e-6 * max(abs(a), 1), r = NaN; else, r = a / b; end
end
