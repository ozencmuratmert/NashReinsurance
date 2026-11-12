function C = precompute_cache(X_sim, g, P)
% PRECOMPUTE_CACHE  Per-step building blocks on a retention grid g (1 x G).
%
% For every decision step i (draws in row i+1 of X_sim) and every grid
% value s in g it stores
%   EX(i)        sample mean of X
%   SL(i,s)      E[(X - s)^+]                      (stop-loss transform)
%   q(i,a)       VaR_alpha(X)                      (empirical quantile)
%   TX(i,a)      TVaR_alpha(X)                     (mean of the upper tail)
%   V(i,s,a)     (q - s)^+                         = VaR_alpha((X - s)^+)
%   B(i,s,a)     mean over tail of (X - s)^+       = TVaR_alpha((X - s)^+)
%
% Every stop-loss and limited stop-loss quantity used in the paper is an
% exact function of these blocks, because all contract payoffs are
% non-decreasing functions of X (so quantiles and upper tails map through).

n  = P.n_steps;  M = P.M;  G = numel(g);
A  = numel(P.alpha_levels);

C.g  = g;
C.EX = zeros(n,1);
C.SL = zeros(n,G);
C.q  = zeros(n,A);
C.TX = zeros(n,A);
C.V  = zeros(n,G,A);
C.B  = zeros(n,G,A);

for i = 1:n
    x  = sort(X_sim(i+1,:));              % 1 x M, ascending
    C.EX(i)   = mean(x);
    C.SL(i,:) = mean(max(x(:) - g, 0), 1);
    for a = 1:A
        n_tail = floor(M*(1 - P.alpha_levels(a)));
        qa     = x(M - n_tail);           % VaR: order statistic ceil(alpha*M)
        tail   = x(M - n_tail + 1 : M);
        C.q(i,a)    = qa;
        C.TX(i,a)   = mean(tail);
        C.V(i,:,a)  = max(qa - g, 0);
        C.B(i,:,a)  = mean(max(tail(:) - g, 0), 1);
    end
end

% Discount factors for the aggregation in Step 3 of Section 4.3
C.w = exp(-P.r * (1:n)' * P.dt);
end
