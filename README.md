# NashReinsurance

Code for **"Stochastic Jump Diffusion Model For Optimal Reinsurance Design: A Nash Bargaining Approach"**
(O. M. Mert and A. S. Selcuk-Kestel, *Applied Stochastic Models in Business and Industry*).

It reproduces every numerical result of the paper: Tables 5–9 and Figures 1–7.

## Requirements
Base MATLAB (R2016b or later). No toolboxes are needed. The code also runs in GNU Octave 6 or later.

## How to run
```matlab
>> cd NashReinsurance
>> main_run_all
```
A full run takes about 20 seconds. It writes the following outputs:

| Output | Content |
|---|---|
| `Results/Tables/all_tables.tex` | LaTeX bodies of Tables 5–9, plus the TVaR-based versions of Tables 6 and 7 (quoted in the text, not tabulated in the paper) |
| `Results/Figures/*.eps, *.png` | Figures 1–7 (file names listed below) |
| `Results/results.mat` | All intermediate quantities (created by the run, not stored in the repository) |

## Structure
```
main_run_all.m                      single entry point
Model/setup_params.m                all parameters (Table 1), seed, grids
Simulation/simulate_pbjd_exact_Vectorized.m   realized PBJD path (exact)
Simulation/simulate_conditional.m   M one-step-ahead draws per decision point
Contracts/precompute_cache.m        per-step E[X], E[(X-s)^+], VaR, TVaR on the grid
Contracts/aggregate_SL.m            discounted profits / risk capital, stop-loss
Contracts/aggregate_LSL.m           same for limited stop-loss (k, m)
Optimization/run_strategies.m       the five criteria of Tables 6-7
Optimization/run_nash_asymmetric.m  asymmetric Nash (Tables 8-9)
Results/generate_tables.m, make_figures.m
```

## Figures
| Paper | File |
|---|---|
| Figure 1 | `Figure_Insurer_RAROC` |
| Figure 2 | `Figure1_RealPath` |
| Figure 3 | `Figure_RiskMeasures_AllLevels` |
| Figure 4 | `Figure_NashProduct_ProfitDistribution` |
| Figure 5 | `Figure7_StopLoss_TimeSeries` |
| Figure 6 | `Figure5_Limited_NashSurface` |
| Figure 7 | `Figure6_Limited_TimeSeries` |

## Data
`Data/realized_path.csv` is the realized claims path used in the manuscript (Figure 1; 365 daily values, X0 = 100). The data are simulated, and no real insurance data are used.

## Method notes
* **Reproducibility:** the realized path is read from `Data/realized_path.csv`. `P.seed = 42` fixes all conditional draws. With `P.path_file = ''`, a new path is simulated from the seed instead.
* **Exact formulas:** stop-loss and limited stop-loss payoffs are non-decreasing in X. Their expectations, VaR and TVaR are therefore computed exactly from the empirical distribution of the M draws (for example, VaR(min(X,k)) = min(VaR(X), k)). The 500 × 500 limited stop-loss grid then costs only a few seconds.
* **Grid:** the retention grid starts at `0.01*X0`. This keeps small optimal retentions, such as the asymmetric solution at α_b = 0.3, inside the grid. The code warns if any optimum lies on the grid boundary.
* **Limited stop-loss Nash contract:** the Nash product is maximal along a curve of (k, m) pairs with identical profits. The reported contract is the Nash-optimal retention for the cap `P.lsl_cap = 132.28` (set it to `[]` to report the raw grid maximizer).
* **Down-jumps:** the down-jump size is floored, V_d = max(U^{1/ν_d}, 0.80), through `P.vd_floor = 0.80`. Set it to 0 for a pure Beta(ν_d, 1) jump size.
* **Verification mode:** `P.reproduce_august = true` replicates the earlier (August 2026) conditional draws exactly, including two errors that were corrected afterwards: σ missing in the diffusion term, and draws left at 0 when both jump types occurred in one step. Use it only to check that the realized path is recovered; it is not used for any reported result.

## License
MIT License (see `LICENSE`).
