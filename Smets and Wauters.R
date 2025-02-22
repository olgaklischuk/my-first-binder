# ############################################################################
# (c) Chancellery of the Prime Minister 2012-2015                            #
#                                                                            #
# Authors: Grzegorz Klima, Karol Podemski,                                   #
#          Kaja Retkiewicz-Wijtiwiak, Anna Sowińska                          #
# ############################################################################
# DSGE model based on Smets Wouters (2003), with corrected equations:
# - (31) The correct loglinearised law of motion for the capital
#        should be written as: K[] = (1 - tau) * K[-1] + tau * I[].
# - (35) The goods market equilibrium condition should be written as:
#        Y_P[] = (1 - tau * k_Y - g_Y) * C[] + tau * k_Y * I[] +
#                g_Y * epsilon_G[] + k_Y * r_k_bar * r_k[] * psi
#        In the [SW'03] the last term accounting for
#        the cost of capacity utilisation was missing.
# The shock $\eta^Q_t$ from equation (30) has not been introduced.
# ############################################################################

options
{
  output LaTeX = TRUE;
  output LaTeX landscape = TRUE;
  output logfile = TRUE;
  verbose = TRUE;
};

tryreduce
{
  H[], B[], H_f[], B_f[], K_j_d[], K_j_d_f[], K_d[], K_d_f[],
  P_f[], pi_star_w[], tc_j[], tc_j_f[],
  Y_j[], Y_j_f[], Div[], Div_f[], L_j_d_f[], L_j_d[], L_d[], L_d_f[],
  lambda[], lambda_f[], L_i_f[], L_i_star_f[];
};

##block CONSUMER#####
{
  definitions
  {
    u[] = epsilon_b[] * ((C[] - H[]) ^ (1 - sigma_c) / (1 - sigma_c) -
                           omega * epsilon_L[] * (L_s[]) ^ (1 + sigma_l) / (1 + sigma_l));
  };
  controls
  {
    C[], K[], I[], B[], z[];
  };
  objective
  {
    U[] = u[] + beta * E[][U[1]];
  };
  constraints
  {
    C[] + I[] + B[] / R[] =
      W[] * L[] +
      r_k[] * z[] * K[-1] - r_k[ss]  / psi * (exp(psi * (z[] - 1)) - 1)  * K[-1] +
      Div[] + B[-1] / pi[] - T[] : lambda[];
    K[] =  (1 - tau) * K[-1]  +
      (1 - varphi / 2 * (epsilon_I[] * I[] / I[-1] - 1) ^ 2) * I[] : q[];
  };
  identities
  {
    H[] = h * C[-1];
    Q[] = q[] / lambda[];
  };
  calibration
  {
    beta = 0.99;            # Discount factor
    tau = 0.025;            # Capital depreciation rate
    varphi = 6.771;         # Parameter of investment adjustment cost function
    psi = 0.169;            # Capacity utilisation cost parameter
    sigma_c = 1.353;        # Coefficient of relative risk aversion
    h = 0.573;              # Habit formation intensity
    sigma_l = 2.4;          # Reciprocal of labour elasticity w.r.t. wage
    omega = 1;              # Labour disutility parameter
  };
};

##block PREFERENCE_SHOCKS####
{
  identities
  {
    log(epsilon_b[]) = rho_b * log(epsilon_b[-1]) + eta_b[];
    log(epsilon_L[]) = rho_L * log(epsilon_L[-1]) - eta_L[];
  };
  shocks
  {
    eta_b[],    # Preference shock
    eta_L[];    # Labour supply shock
  };
  calibration
  {
    rho_b = 0.855;
    rho_L = 0.889;
  };
};

##block INVESTMENT_COST_SHOCKS####
{
  identities
  {
    log(epsilon_I[]) = rho_I * log(epsilon_I[-1]) + eta_I[];
  };
  shocks
  {
    eta_I[];    # Investment shock
  };
  calibration
  {
    rho_I = 0.927;
  };
};

#block WAGE_SETTING_PROBLEM##########
{
  definitions
  {
    L_star[] = (pi_star_w[]) ^ (-((1 + lambda_w) / lambda_w)) * L[];
  }
  identities
  {
    f_1[] = 1 / (1 + lambda_w) * w_star[] * lambda[] * L_star[] +
      beta * xi_w * E[][((pi[] ^ gamma_w) / pi[1])^(-1 / lambda_w) *
                          (w_star[1] / w_star[])^(1 / lambda_w) * f_1[1]];
    f_2[] = epsilon_L[] * omega * epsilon_b[] * (L_star[]) ^ (1 + sigma_l) +
      beta * xi_w * E[][((pi[] ^ gamma_w) / pi[1])^
                          (-((1 + lambda_w) / lambda_w)*(1 + sigma_l)) *
                          (w_star[1] / w_star[])^(((1 + lambda_w) / lambda_w) * (1 + sigma_l)) * f_2[1]];
    f_1[] = f_2[] + eta_w[];
    pi_star_w[] = w_star[] / W[];
  };
  shocks
  {
    eta_w[];                # Wage mark-up shock
  };
  calibration
  {
    gamma_w = 0.763;        # Indexation parameter for non-optimising workers
    lambda_w = 0.5;         # Wage mark-up
    xi_w = 0.737;           # Probability of not receiving ``wage-change signal''
  };
};

#block WAGE_EVOLUTION####
{
  identities
  {
    1 = xi_w * ((pi[-1] ^ gamma_w) / pi[]) ^ (-1 / lambda_w) *
      (W[-1] / W[])^(-1 / lambda_w) + (1 - xi_w) * (pi_star_w[]) ^ (-1 / lambda_w);
  };
};

#block LABOUR_AGGREGATION####
{
  identities
  {
    nu_w[] = (1 - xi_w) * pi_star_w[] ^(-((1 + lambda_w) / lambda_w)) +
      xi_w * ((W[-1]/W[]) * ((pi[-1]^gamma_w) / pi[])) ^
      (-((1 + lambda_w) / lambda_w)) * nu_w[-1];
    L[] = L_s[] / nu_w[];
  };
};

#block CONSUMER_FLEXIBLE####
{
  definitions
  {
    u_f[] = epsilon_b[] * ((C_f[] - H_f[]) ^ (1 - sigma_c) / (1 - sigma_c) -
                             omega * epsilon_L[] * L_s_f[] ^ (1 + sigma_l) / (1 + sigma_l));
    Inc_i_f[] =  W_disutil_f[] * L_s_f[]  + Pi_ws_f[] +
      r_k_f[] * z_f[] * K_f[-1] -
      r_k_f[ss]  / psi * (exp(psi * (z_f[] - 1)) - 1)  * K_f[-1];
  };
  controls
  {
    C_f[], K_f[], I_f[], B_f[], z_f[], L_s_f[];
  };
  objective
  {
    U_f[] = u_f[] + beta * E[][U_f[1]];
  };
  constraints
  {
    C_f[] + I_f[] + B_f[] / R_f[]  =
      Inc_i_f[] + Div_f[] + B_f[-1] - T_f[]: lambda_f[];
    K_f[] = (1 - tau) * K_f[-1]  +
      (1 - varphi / 2 * (epsilon_I[] * I_f[] / I_f[-1] - 1)^2) * I_f[]  : q_f[];
  };
  identities
  {
    H_f[] = h * C_f[-1];
    Q_f[] = q_f[] / lambda_f[];
  };
};

#block FLEXIBLE_MONOPOLISTIC_WORKER####
{
  controls
  {
    W_i_f[], L_i_star_f[];
  };
  objective
  {
    Pi_ws_f[] = (W_i_f[] - W_disutil_f[]) * L_i_star_f[];
  };
  constraints
  {
    L_i_star_f[] = L_f[] * (W_i_f[] / W_f[])^(-(1 + lambda_w) / lambda_w);
  };
  identities
  {
    L_i_star_f[] = L_i_f[];
  };
};

#block LABOUR_AGGREGATION_FLEXIBLE####
{
  identities
  {
    L_s_f[] = L_i_f[];
    L_f[] = L_s_f[];
  };
};

#block FIRM####
{
  controls
  {
    K_j_d[], L_j_d[];
  };
  objective
  {
    tc_j[] = - L_j_d[] * W[] - K_j_d[] * r_k[];
  };
  constraints
  {
    Y_j[] = epsilon_a[] * K_j_d[] ^ alpha * L_j_d[]^(1 - alpha) - Phi :       mc[];
  };
  calibration
  {
    alpha = 0.3;                                # Capital share in output
    (Y_j[ss] + Phi) / Y_j[ss] = 1.408 -> Phi;   # Calibration of fixed costs
  };
};

#block TECHNOLOGY####
{
  identities
  {
    log(epsilon_a[]) = rho_a * log(epsilon_a[-1]) + eta_a[];
  };
  shocks
  {
    eta_a[];    # Productivity shock
  };
  calibration
  {
    rho_a = 0.823;
  };
};

#block PRICE_SETTING_PROBLEM####
{
  identities
  {
    g_1[] = (1 + lambda_p) * g_2[] + eta_p[];
    g_1[] = lambda[] * pi_star[] * Y[] + beta * xi_p *
      E[][(pi[] ^ gamma_p / pi[1]) ^ (-1 / lambda_p) *
            (pi_star[] / pi_star[1]) * g_1[1]];
    g_2[] = lambda[] * mc[] * Y[] + beta * xi_p *
      E[][(pi[] ^ gamma_p / pi[1]) ^ (-((1 + lambda_p) / lambda_p)) * g_2[1]];
  };
  shocks
  {
    eta_p[];                # Price mark-up shock
  };
  calibration
  {
    xi_p = 0.908;           # Probability of not receiving the ``price-change signal''
    gamma_p = 0.469;        # Indexation parameter for non-optimising firms
  };
};

#block PRICE_EVOLUTION####
{
  identities
  {
    1 = xi_p * (pi[-1] ^ gamma_p / pi[]) ^ (-1 / lambda_p) +
      (1 - xi_p) * pi_star[] ^ (-1 / lambda_p);
  };
};

#block FACTOR_DEMAND_AGGREGATION####
{
  identities
  {
    K_d[] = K_j_d[];
    L_d[] = L_j_d[];
  };
};

#block PRODUCT_AGGREGATION####
{
  identities
  {
    Y_s[] = Y_j[];
    nu_p[] = (1 - xi_p) * pi_star[] ^ (-((1 + lambda_p) / lambda_p))
    + xi_p * (pi[-1] ^ gamma_p / pi[]) ^
      (-((1 + lambda_p) / lambda_p)) * nu_p[-1];
    Y[] * nu_p[] = Y_s[];
  };
};

#block FIRM_FLEXIBLE####
{
  controls
  {
    K_j_d_f[], L_j_d_f[];
  };
  objective
  {
    tc_j_f[] = - L_j_d_f[] * W_f[] - K_j_d_f[] * r_k_f[];
  };
  constraints
  {
    Y_j_f[] = epsilon_a[] * K_j_d_f[]^alpha * L_j_d_f[]^(1 - alpha) - Phi    : mc_f[];
  };
};

#block PRICE_SETTING_PROBLEM_FLEXIBLE####
{
  controls
  {
    Y_j_f[], P_j_f[];
  };
  objective
  {
    Pi_ps_f[] = (P_j_f[] - mc_f[]) * Y_j_f[];
  };
  constraints
  {
    Y_j_f[] = (P_j_f[] / P_f[])^ (-((1 + lambda_p) / lambda_p)) * Y_f[];
  };
  calibration
  {
    C_f[ss] / Y_f[ss]  = 0.6  -> lambda_p;      # Calibration of the price mark-up
  };
};

#block FACTOR_DEMAND_AGGREGATION_FLEXIBLE####
{
  identities
  {
    K_d_f[] = K_j_d_f[];
    L_d_f[] = L_j_d_f[];
  };
};

#block PRODUCT_AGGREGATION_FLEXIBLE####
{
  identities
  {
    Y_s_f[] = Y_j_f[];
    Y_f[] = Y_s_f[];
  };
};

#block PRICE_EVOLUTION_FLEXIBLE####
{
  identities
  {
    P_f[] = 1;
  };
};

#block GOVERNMENT####
{
  identities
  {
    G[] = G_bar * epsilon_G[];
    G[] + B[-1] / pi[] = T[] + B[] / R[];
  };
  calibration
  {
    G[ss] / Y[ss] = 0.18  -> G_bar; # Calibration of the steady state government expenditures
  };
};

#block GOVERNMENT_SPENDING_SHOCK####
{
  identities
  {
    log(epsilon_G[]) = rho_G * log(epsilon_G[-1]) + eta_G[];
  };
  shocks
  {
    eta_G[];    # Government spending shock
  };
  calibration
  {
    rho_G = 0.949;
  };
};

#block GOVERNMENT_FLEXIBLE####
{
  identities
  {
    G_f[] = G_bar * epsilon_G[];
    G_f[] + B_f[-1] = T_f[] + B_f[] / R_f[];
  };
};

#block MONETARY_POLICY_AUTHORITY####
{
  identities
  {
    log(R[] / R[ss]) + calibr_pi = rho * log(R[-1] / R[ss]) +
      (1 - rho) * (log(pi_obj[]) +
                     r_pi * (log(pi[-1] / pi[ss]) - log(pi_obj[])) +
                     r_Y * (log(Y[]/ Y[ss]) - log(Y_f[] / Y_f[ss]))) +
      r_Delta_pi * (log(pi[]/pi[ss]) - log(pi[-1]/pi[ss])) +
      r_Delta_y * (log(Y[] / Y[ss]) -
                     log(Y_f[] / Y_f[ss]) -
                     (log(Y[-1] / Y[ss]) -
                        log(Y_f[-1] / Y_f[ss]))) +
      eta_R[];
    log(pi_obj[]) = (1 - rho_pi_bar) * log(calibr_pi_obj) +
      rho_pi_bar * log(pi_obj[-1]) + eta_pi[];
  };
  shocks
  {
    eta_R[],    # Interest rate shock
    eta_pi[];   # Inflation objective shock
  };
  calibration
  {
    r_Delta_pi = 0.14;                        # Weight on the dynamics of inflation
    r_Delta_y = 0.159;                        # Weight on the dynamics of output gap
    rho = 0.961;                              # Interest rate smoothing parameter
    r_Y = 0.099;                              # Weight on the output gap
    r_pi = 1.684;                             # Weight on the inflation gap
    pi_obj[ss] = 1      -> calibr_pi_obj;     # Calibration of the inflation objective
    pi[ss] = pi_obj[ss] -> calibr_pi;         # Calibration of the inflation
    rho_pi_bar = 0.924;                       # AR parameter for the inflation objective
  };
};

#block EQUILIBRIUM####
{
  identities
  {
    K_d[] = z[] * K[-1];
    L[] = L_d[];
    B[] = 0;
    Div[] = Y[] - L_d[] * W[] - K_d[] * r_k[];
  };
};

#block EQUILIBRIUM_FLEXIBLE####
{
  identities
  {
    K_d_f[] = z_f[] * K_f[-1];
    L_f[] = L_d_f[];
    B_f[] = 0;
    Div_f[] = Y_f[] - L_d_f[] * W_f[] - K_d_f[] * r_k_f[];
  };
};
