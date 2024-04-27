import numpy as np
import random
from es import CMAES, OpenES

from ES_logic_multiple_runs import *

from files_def_multiple_runs import *

SIGMA_INIT_CMAES = 0.1
SOLVER_NAME = 'cmaes'

# === Start ===

def run_single_cmaes(V_S, seed, NPOPULATION, MAX_ITERATION):
    now = datetime.now()
    
    dir_run = SOLVER_NAME+'_'+ now.strftime("%Y_%m_%d_%Hh%M")
    
    dir_vs = dir_run +'/'+ str(V_S).replace('.','_')
    mkdir(dir_vs)

    random.seed(seed)
    x0 =  [
            random.uniform(range_D[0],     range_D[1]),
            random.uniform(range_AEdAO[0], range_AEdAO[1]),
            random.uniform(range_PdD[0],   range_PdD[1])
            ]

    # defines CMA-ES algorithm solver
    cmaes = CMAES(NPARAMS,
                    x0=x0,                     # initial parameters values to generate the population
                    popsize=NPOPULATION,
                    weight_decay=0.01,
                    sigma_init = SIGMA_INIT_CMAES,
                    lower_bounds=lower_bounds,
                    upper_bounds=upper_bounds,
                )

    # dir for the seed execution
    dir_seed = dir_run +'/'+ str(V_S).replace('.','_') +'/' + str(seed)
    mkdir(dir_seed)

    # create config file
    create_config_file_ES(dir_seed, SOLVER_NAME, V_S, NPOPULATION, MAX_ITERATION, seed, x0, SIGMA_INIT_CMAES)

    try:
        best_result = run_solver(dir_seed, cmaes, SOLVER_NAME, V_S, seed, NPOPULATION, MAX_ITERATION)
        print(best_result)
    except: pass

if __name__ == '__main__':
    V_S = 8.0
    SEED = 1

    # ES settings
    NPOPULATION   = 5 # size of population
    MAX_ITERATION = 30 # run solver for this generations

    run_single_cmaes(V_S, SEED, NPOPULATION, MAX_ITERATION)
