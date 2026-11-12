function P = setup_params()
% SETUP_PARAMS  All model, simulation and grid parameters in one place.
%   Values follow Table 1 of the manuscript.

%% PBJD model (Table 1)
P.mu       = 0.10;      % drift (annual)
P.sigma    = 0.45;      % volatility (annual)
P.lambda_u = 12;        % up-jump intensity
P.nu_u     = 8;         % Pareto shape (up-jumps)
P.lambda_d = 4;         % down-jump intensity
P.nu_d     = 0.8;       % Beta(nu_d,1) shape (down-jumps)
P.X0       = 100;       % initial claims
P.T        = 1.0;       % horizon (years)
P.dt       = 1/364;     % daily step
P.n_steps  = round(P.T / P.dt);

%% Pricing and capital
P.theta    = 0.03;      % security loading
P.r        = 0.03;      % risk-free (discount) rate
P.r_coc    = 0.03;      % cost of capital in the risk-adjusted profit criterion
P.R_bar    = 0.10;      % minimum reinsurer RAROC (constrained Max RAROC_I)
P.alpha_levels = [0.95 0.975 0.99];

%% Realized path
%  The manuscript's realized claims path (Figure 1) is stored as data.
%  Set P.path_file = '' to simulate a new path from the seed instead.
P.path_file = fullfile('Data', 'realized_path.csv');

%% Simulation
P.M        = 1000;      % conditional simulations per time step
P.seed     = 42;        % fixes the realized path AND all conditional draws
P.vd_floor = 0.80;      % floor on the down-jump size V_d, as used in the
                        % code behind the manuscript (set 0 for pure Beta)
P.reproduce_august = false;  % true = replicate the August 2026 conditional
                             % draws exactly (incl. their errors); use only
                             % to verify that the manuscript path is recovered

%% Retention / cap grids
%  CHANGE FOR THE REVISION: the stop-loss grid now starts close to zero
%  instead of at min(X_real), so that small optimal retentions (e.g. the
%  asymmetric Nash solution for alpha_b = 0.3) are not cut off by the grid.
P.n_k_SL    = 1000;     % stop-loss grid size
P.k_min_frac = 0.01;    % k_min = k_min_frac * X0
P.n_g_LSL   = 500;      % limited stop-loss: N_k = N_m = 500 (as in the paper)
P.m_max_mult = 1.2;     % upper end of the LSL grid = 1.2 * max(X_real)

%% Limited stop-loss Nash selection (Proposition 9 / Remark on selection)
%  The Nash optimum is a curve of (k,m) pairs with identical profits. The
%  reported contract is the Nash-optimal retention for a GIVEN cap m.
%  Set [] to report the raw grid maximiser instead.
P.lsl_cap = 132.28;

%% Asymmetric Nash bargaining
P.alpha_b    = [0.3 0.4 0.5 0.6 0.7];
P.asym_level = 1;       % index into alpha_levels used for RAROC (1 = 95%)
end
