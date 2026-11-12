function X_sim = simulate_conditional(X_real, P)
% SIMULATE_CONDITIONAL  M one-step-ahead draws of X_{t_n + dt} given X_{t_n},
% for every decision point t_n on the realized path (Step 1, Section 4.3).
% Row n+1 of X_sim holds the draws conditional on X_real(n); row 1 is X0.
%
% P.reproduce_august = true  replicates the August 2026 code exactly,
%   INCLUDING its two errors, only to verify that the manuscript numbers
%   are recovered:
%     (i)  the diffusion term was sqrt(dt)*Z, i.e. sigma was missing
%          (effective volatility 1 instead of sigma = 0.45);
%     (ii) when an up- and a down-jump occurred in the same step the draw
%          was never assigned and stayed 0.
%   It also keeps the realized path as draw number 1.
%
% P.reproduce_august = false (default) is the corrected version: correct
%   sigma, single-jump regimes with probabilities p_0 : p_d : p_u
%   (Proposition 1), down-jumps floored at P.vd_floor (0 = no floor).

n = P.n_steps;  M = P.M;  dt = P.dt;
X_sim = zeros(n+1, M);
X_sim(1,:) = X_real(1);

if P.reproduce_august
    X_sim(:,1) = X_real;
    for j = 2:M
        Nu = poissrnd(P.lambda_u*dt, n+1, 1);
        Nd = poissrnd(P.lambda_d*dt, n+1, 1);
        for i = 2:(n+1)
            x_cont = X_real(i-1) * exp((P.mu - P.sigma^2/2)*dt + sqrt(dt)*randn);
            u   = rand(1,2);
            V_u = (1 - u(1))^(-1/P.nu_u);
            V_d = u(2)^(1/P.nu_d);
            if Nu(i)==0 && Nd(i)==0
                X_sim(i,j) = x_cont;
            elseif Nu(i)>=1 && Nd(i)==0
                X_sim(i,j) = x_cont * V_u;
            elseif Nu(i)==0 && Nd(i)>=1
                X_sim(i,j) = x_cont * max(V_d, P.vd_floor);
            end
        end
    end
    return
end

w  = [1, P.lambda_d*dt, P.lambda_u*dt];  w = w / sum(w);
cd = w(1);  cu = w(1) + w(2);
for i = 2:(n+1)
    Z  = (P.mu - 0.5*P.sigma^2)*dt + P.sigma*sqrt(dt)*randn(1,M);
    U  = rand(1,M);
    Vu = rand(1,M).^(-1/P.nu_u);
    Vd = rand(1,M).^( 1/P.nu_d);
    if P.vd_floor > 0, Vd = max(Vd, P.vd_floor); end
    J = ones(1,M);
    idx_d = (U > cd) & (U <= cu);
    idx_u = (U > cu);
    J(idx_d) = Vd(idx_d);
    J(idx_u) = Vu(idx_u);
    X_sim(i,:) = X_real(i-1) * exp(Z) .* J;
end
end
