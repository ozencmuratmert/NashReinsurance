function [t, X] = simulate_pbjd_exact_Vectorized(X0, mu, sigma, lambda_u, nu_u, ...
                                                lambda_d, nu_d, T, dt, vd_floor)
% SIMULATE_PBJD_EXACT_VECTORIZED  Realized path of the Pareto-Beta jump
% diffusion, using the same algorithm and the same order of random draws as
% the code that produced the manuscript (August 2026 version):
%
%   Nu = Poisson(lambda_u dt), Nd = Poisson(lambda_d dt)   (all steps drawn first)
%   U  = uniforms for the jump sizes                       (all steps drawn first)
%   step i: X_i = X_{i-1} exp((mu - sigma^2/2) dt + sigma sqrt(dt) Z_i) * J_i,
%   J_i = V^u (one up-jump), max(V^d, vd_floor) (one down-jump), 1 otherwise,
%   with V^u = (1-U)^(-1/nu_u) ~ Pareto(nu_u),  V^d = U^(1/nu_d) ~ Beta(nu_d,1).
%
% Call rng(seed) immediately before this function to reproduce the path.

if nargin < 10, vd_floor = 0.80; end
n = round(T / dt);
t = linspace(0, T, n+1)';
X = zeros(n+1, 1);
X(1) = X0;

Nu = poisson_draw(lambda_u*dt, n+1);
Nd = poisson_draw(lambda_d*dt, n+1);
U  = rand(n+1, 2);

for i = 2:(n+1)
    x_cont = X(i-1) * exp((mu - sigma^2/2)*dt + sigma*sqrt(dt)*randn);
    V_u = (1 - U(i,1))^(-1/nu_u);
    V_d = max(U(i,2)^(1/nu_d), vd_floor);
    if Nu(i) == 0 && Nd(i) == 0
        X(i) = x_cont;
    elseif Nu(i) >= 1 && Nd(i) == 0
        X(i) = x_cont * V_u;
    elseif Nu(i) == 0 && Nd(i) >= 1
        X(i) = x_cont * V_d;
    else
        X(i) = x_cont;          % simultaneous jumps: negligible probability
    end
end
end

function N = poisson_draw(lam, n)
% Uses poissrnd (Statistics Toolbox) when available, so that the random
% stream is identical to the original code; otherwise a base-MATLAB
% inversion sampler (same distribution, different stream).
if exist('poissrnd', 'file') || exist('poissrnd', 'builtin')
    N = poissrnd(lam, n, 1);
else
    U = rand(n,1);  N = zeros(n,1);
    p = exp(-lam);  F = p;  k = 0;  active = U > F;
    while any(active)
        k = k + 1;  p = p*lam/k;  F = F + p;
        N(active) = k;  active = active & (U > F);
    end
end
end
