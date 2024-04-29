from oct2py import Oct2Py

V_S = 8.0
Z = 2
D = 0.7866192509637266
AEdAO = 0.30959504136781724
PdD = 0.5587743757849281

def run_octave_evaluation(V_S,D,Z,AEdAO,PdD):
    P_B, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax = [-1, -1, -1, -1, -1, -1, -1]
    with Oct2Py() as octave:
        octave.warning ("off", "Octave:data-file-in-path");
        octave.addpath('./allCodesOctave');
        P_B, n, etaO,etaR, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax = octave.F_LabH2_return_constraints(V_S,D,Z,AEdAO,PdD, nout=10)
    return [P_B, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax]

# --------------------------

P_B, t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax = run_octave_evaluation(V_S,D,Z,AEdAO,PdD)

print('P_B       ',P_B)
print('t075dD    ',t075dD)
print('tmin075dD ',tmin075dD) 
print('tal07R    ',tal07R)
print('cavLim    ',cavLim) 
print('Vtip      ',Vtip)
print('Vtipmax   ',Vtipmax)

# Strength Constraint
if (t075dD < tmin075dD):
    penalty = tmin075dD - t075dD
    print('broke Strength  ', penalty)

# Cavitation Constrant
if (tal07R > cavLim):
    penalty = tal07R - cavLim
    print('broke Cavitation', penalty)

# Peripherical Velocity Constraint
if (Vtip > Vtipmax):
    penalty = Vtip - Vtipmax
    print('broke Velocity  ', penalty)
    
strength,strengthMin, cavitation,cavitationMax, velocity,velocityMax = t075dD,tmin075dD, tal07R,cavLim, Vtip,Vtipmax

fit_value = P_B * (1 + max(((cavitation - cavitationMax)/cavitationMax), 0) + max(((velocity - velocityMax)/velocityMax), 0) + max(((strengthMin - strength)/strengthMin), 0) )

print('fit', fit_value)
print('dif', abs(fit_value - P_B) )