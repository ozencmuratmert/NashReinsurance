%% main_run_all.m
%  Reproduces all numerical results (Tables 2-9, Figures 1-7) of
%  "Stochastic Jump Diffusion Model For Optimal Reinsurance Design:
%   A Nash Bargaining Approach"  (Mert & Selcuk-Kestel).
%
%  Run from the NashReinsurance/ folder:   >> main_run_all
%  Requires base MATLAB only (no toolboxes). Also runs in GNU Octave >= 6.

clear; clc; close all;
if exist('OCTAVE_VERSION','builtin'), try, pkg load statistics; catch, end, end
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
addpath(fullfile(here,'Model'), fullfile(here,'Simulation'), ...
        fullfile(here,'Contracts'), fullfile(here,'Optimization'), ...
        fullfile(here,'Results'));
fdir = fullfile(here, 'Results', 'Figures');
tdir = fullfile(here, 'Results', 'Tables');
if ~exist(fdir,'dir'), mkdir(fdir); end
if ~exist(tdir,'dir'), mkdir(tdir); end

%% 1. Parameters and seed
P = setup_params();
rng(P.seed, 'twister');
fprintf('Seed %d, M = %d, dt = 1/%d\n', P.seed, P.M, round(1/P.dt));

%% 2. Realized path and conditional simulations (Step 1, Section 4.3)
if ~isempty(P.path_file)
    X_real = load(fullfile(here, P.path_file));    % manuscript path (Figure 1)
    X_real = X_real(:);
else
    [~, X_real] = simulate_pbjd_exact_Vectorized(P.X0, P.mu, P.sigma, ...
        P.lambda_u, P.nu_u, P.lambda_d, P.nu_d, P.T, P.dt, P.vd_floor);
end
X_sim = simulate_conditional(X_real, P);
fprintf('Realized path: min %.2f, max %.2f  (manuscript: min 34.78)\n', min(X_real), max(X_real));
if P.reproduce_august
    fprintf('*** reproduce_august = true: verification run only, not for the paper ***\n');
end

%% 3. Grids
k_min = P.k_min_frac * P.X0;
g_SL  = linspace(k_min, max(X_real), P.n_k_SL);
g_LSL = linspace(k_min, P.m_max_mult*max(X_real), P.n_g_LSL);
if ~isempty(P.lsl_cap), g_LSL = unique([g_LSL, P.lsl_cap]); end   % cap is a grid point

%% 4. Per-step cache (Step 2) and aggregation over [0,T] (Step 3)
tic;
C_SL  = precompute_cache(X_sim, g_SL,  P);
C_LSL = precompute_cache(X_sim, g_LSL, P);
SL    = aggregate_SL(C_SL, P);
LSL   = aggregate_LSL(C_LSL, P);
fprintf('Cache and aggregation: %.1f s\n', toc);

%% 5. Optimization (Step 4): five criteria, VaR/TVaR, three levels
LSL.PIc = LSL.PI;  LSL.PRc = LSL.PR;
if ~isempty(P.lsl_cap)
    im_cap = find(abs(LSL.m - P.lsl_cap) < 1e-9, 1);
    keep = false(size(LSL.PI));  keep(:, im_cap) = true;
    LSL.PIc(~keep) = NaN;  LSL.PRc(~keep) = NaN;
end
A = numel(P.alpha_levels);
SL.strat  = cell(2, A);
LSL.strat = cell(2, A);
for typ = 1:2
    for a = 1:A
        SL.strat{typ,a}  = run_strategies(SL.PI, SL.PR, ...
            squeeze(SL.KI(typ,a,:))', squeeze(SL.KR(typ,a,:))', P);
        LSL.strat{typ,a} = run_strategies(LSL.PI, LSL.PR, ...
            LSL.KI(:,:,typ,a), LSL.KR(:,:,typ,a), P);
        if ~isempty(P.lsl_cap)      % Nash contract for the given cap
            Rc = run_strategies(LSL.PIc, LSL.PRc, ...
                LSL.KI(:,:,typ,a), LSL.KR(:,:,typ,a), P);
            LSL.strat{typ,a}(4) = Rc(4);
        end
    end
end

%% 6. Asymmetric Nash bargaining (Section 5.3), VaR at P.asym_level
a = P.asym_level;
SL.asym  = run_nash_asymmetric(SL.PI, SL.PR, ...
    squeeze(SL.KI(1,a,:))', squeeze(SL.KR(1,a,:))', P);
LSL.asym = run_nash_asymmetric(LSL.PIc, LSL.PRc, ...
    LSL.KI(:,:,1,a), LSL.KR(:,:,1,a), P);

for b = 1:numel(SL.asym)
    if SL.asym(b).on_boundary || LSL.asym(b).on_boundary
        warning('alpha_b = %.1f: optimum on the grid boundary - widen the grid.', ...
                SL.asym(b).alpha_b);
    end
end

%% 7. Output
out = struct('X_real', X_real, 'C_SL', C_SL, 'SL', SL, 'LSL', LSL);
generate_tables(out, P, fullfile(tdir, 'all_tables.tex'));
make_figures(out, P, fdir);
save(fullfile(here,'Results','results.mat'), 'out', 'P', '-v7');
fprintf('\nDone.\n');
