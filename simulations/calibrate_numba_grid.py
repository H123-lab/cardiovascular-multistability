from __future__ import annotations
import csv, itertools, math, sys, time
from pathlib import Path
import numpy as np
from numba import njit

OUT = Path('results/calibration')
OUT.mkdir(parents=True, exist_ok=True)
T, T_SYS = 0.80, 0.24
EMAX, EMIN, V0 = 2.0, 0.06, 10.0
CA, CV = 1.5, 100.0
RAV, RMV = 0.01, 0.008
ALPHA, DT, CSTEPS = 0.72, 0.001, 800

@njit
def _elast(t):
    tm = t % T
    if tm <= T_SYS:
        return 0.5 * (1.0 - math.cos(math.pi * tm / T_SYS))
    return 0.0

@njit
def _rhs(v, pa, pv, elast, R, pcrit, beta, ksig):
    z = (pa - (beta * R + pcrit)) / ksig
    if z > 700.0: z = 700.0
    if z < -700.0: z = -700.0
    perf = ALPHA + (1.0 - ALPHA) / (1.0 + math.exp(-z))
    plv = (EMIN + (EMAX * perf - EMIN) * elast) * (v - V0)
    qmv = (pv - plv) / RMV if pv > plv else 0.0
    qav = (plv - pa) / RAV if plv > pa else 0.0
    qsys = (pa - pv) / R
    return qmv-qav, (qav-qsys)/CA, (qsys-qmv)/CV

@njit
def integrate_last_two(v, pa, pv, R, seconds, pcrit, beta, ksig):
    n = int(round(seconds / DT))
    start = n - 2*CSTEPS
    y = np.zeros((3, 2*CSTEPS+1), dtype=np.float64)
    if start == 0:
        y[0,0], y[1,0], y[2,0] = v, pa, pv
    for i in range(n):
        t0 = i*DT
        e0 = _elast(t0); eh = _elast(t0+0.5*DT); e1 = _elast(t0+DT)
        a1,b1,c1 = _rhs(v,pa,pv,e0,R,pcrit,beta,ksig)
        a2,b2,c2 = _rhs(v+0.5*DT*a1,pa+0.5*DT*b1,pv+0.5*DT*c1,eh,R,pcrit,beta,ksig)
        a3,b3,c3 = _rhs(v+0.5*DT*a2,pa+0.5*DT*b2,pv+0.5*DT*c2,eh,R,pcrit,beta,ksig)
        a4,b4,c4 = _rhs(v+DT*a3,pa+DT*b3,pv+DT*c3,e1,R,pcrit,beta,ksig)
        v += DT*(a1+2*a2+2*a3+a4)/6.0
        pa += DT*(b1+2*b2+2*b3+b4)/6.0
        pv += DT*(c1+2*c2+2*c3+c4)/6.0
        if not (math.isfinite(v) and math.isfinite(pa) and math.isfinite(pv)):
            return y, v, pa, pv, False
        j=i+1
        if j>=start:
            k=j-start
            y[0,k],y[1,k],y[2,k]=v,pa,pv
    return y,v,pa,pv,True

@njit
def map_cycle(y):
    s=0.0
    for i in range(1,CSTEPS+1):
        s += 0.5*(y[1,CSTEPS+i-1]+y[1,CSTEPS+i])*DT
    return s/T

@njit
def cycle_diff(y):
    d=0.0
    for k in range(3):
        for i in range(CSTEPS+1):
            q=abs(y[k,CSTEPS+i]-y[k,i])
            if q>d: d=q
    return d

@njit
def sweep_one_direction(rvals, reverse, v, pa, pv, pcrit, beta, ksig):
    n=len(rvals)
    ends=np.zeros((3,n)); maps=np.zeros(n)
    for z in range(n):
        i=n-1-z if reverse else z
        y,v,pa,pv,ok=integrate_last_two(v,pa,pv,rvals[i],300.0,pcrit,beta,ksig)
        if not ok: return maps,ends,v,pa,pv,False
        maps[i]=map_cycle(y)
        ends[0,i]=v; ends[1,i]=pa; ends[2,i]=pv
    return maps,ends,v,pa,pv,True

@njit
def branch_sep_and_persistence(xa, xb, R, pcrit, beta, ksig):
    ya,_,_,_,oka=integrate_last_two(xa[0],xa[1],xa[2],R,300.0,pcrit,beta,ksig)
    yb,_,_,_,okb=integrate_last_two(xb[0],xb[1],xb[2],R,300.0,pcrit,beta,ksig)
    if not oka or not okb: return 0.0, 1e99, 1e99, False
    da=cycle_diff(ya); db=cycle_diff(yb)
    sep=0.0
    for i in range(CSTEPS+1):
        q=abs(ya[1,CSTEPS+i]-yb[1,CSTEPS+i])
        if q>sep: sep=q
    ya6,_,_,_,oka6=integrate_last_two(xa[0],xa[1],xa[2],R,600.0,pcrit,beta,ksig)
    yb6,_,_,_,okb6=integrate_last_two(xb[0],xb[1],xb[2],R,600.0,pcrit,beta,ksig)
    if not oka6 or not okb6: return sep,da,1e99,False
    d6=max(cycle_diff(ya6),cycle_diff(yb6))
    return sep,max(da,db),d6,True

def write_csv(path, header, rows):
    with path.open('w', newline='') as f:
        w=csv.writer(f); w.writerow(header); w.writerows(rows)

def main():
    # Deterministic ascending grid: 7 x 5 x 5 x 5 = 875 combinations.
    v_grid=[950,975,1000,1025,1050,1075,1100]
    pc_grid=[30,35,40,45,50]
    beta_grid=[45,50,55,60,65]
    ks_grid=[1.5,2.0,2.5,3.0,3.5]
    combos=list(itertools.product(v_grid,pc_grid,beta_grid,ks_grid))
    log=[]; rows=[]; selected=None
    started=time.time()
    log.append(f'Grid: {len(combos)} combinations; V_total={v_grid}; P_crit={pc_grid}; beta_R={beta_grid}; k_sig={ks_grid}')
    log.append(f'Integrator: classical RK4, fixed dt={DT:.3f} s; T={T:.2f} s; alpha={ALPHA:.2f}')
    for idx,(vt,pc,br,ks) in enumerate(combos,1):
        pv_init=(vt-120.0-CA*135.0)/CV
        y300,_,_,_,ok=integrate_last_two(120.0,135.0,pv_init,1.40,300.0,pc,br,ks)
        if not ok:
            rows.append([vt,pc,br,ks,'NONFINITE_BASELINE','','','','','']); continue
        m=map_cycle(y300)
        if not (90.0 <= m <= 105.0):
            rows.append([vt,pc,br,ks,'MAP_FAIL',f'{m:.8f}','','','','']); continue
        y600,_,_,_,ok600=integrate_last_two(120.0,135.0,pv_init,1.40,600.0,pc,br,ks)
        if not ok600:
            rows.append([vt,pc,br,ks,'NONFINITE_600S',f'{m:.8f}','','','','']); continue
        d300=cycle_diff(y300); d600=cycle_diff(y600)
        if not (d300 < 1e-6 and d600 < 1e-6):
            rows.append([vt,pc,br,ks,'PERIODICITY_FAIL',f'{m:.8f}',f'{d300:.8e}',f'{d600:.8e}','','']); continue
        rv=np.round(np.arange(0.80,2.0001,0.02),4)
        fm,fe,_,_,_,okf=sweep_one_direction(rv,False,120.0,135.0,pv_init,pc,br,ks)
        if not okf:
            rows.append([vt,pc,br,ks,'FORWARD_SWEEP_NONFINITE',f'{m:.8f}',f'{d300:.8e}',f'{d600:.8e}','','']); continue
        start=np.array([fe[0,-1],fe[1,-1],fe[2,-1]])
        rm,re,_,_,_,okr=sweep_one_direction(rv,True,start[0],start[1],start[2],pc,br,ks)
        if not okr:
            rows.append([vt,pc,br,ks,'REVERSE_SWEEP_NONFINITE',f'{m:.8f}',f'{d300:.8e}',f'{d600:.8e}','','']); continue
        branch=[]; all_sep=True; all_persist=True
        for r in (1.30,1.40,1.50):
            j=int(round((r-0.80)/0.02))
            xa=fe[:,j].copy(); xb=re[:,j].copy()
            sep,bd300,bd600,okb=branch_sep_and_persistence(xa,xb,r,pc,br,ks)
            branch.append((r,sep,bd300,bd600,okb))
            if not okb or sep <= 5.0: all_sep=False
            if not okb or bd300 >= 1e-6 or bd600 >= 1e-6: all_persist=False
        if all_sep and all_persist:
            selected=(vt,pc,br,ks,m,d300,d600,fm,rm,branch)
            rows.append([vt,pc,br,ks,'PASS_ALL',f'{m:.8f}',f'{d300:.8e}',f'{d600:.8e}',max(x[1] for x in branch),min(x[1] for x in branch)])
            log.append(f'FIRST PASS at grid index {idx}: V_total={vt}, P_crit={pc}, beta_R={br}, k_sig={ks}; MAP={m:.6f}; Cycle_Diff300={d300:.3e}; Cycle_Diff600={d600:.3e}')
            break
        rows.append([vt,pc,br,ks,'COEXISTENCE_OR_BRANCH_PERIODICITY_FAIL',f'{m:.8f}',f'{d300:.8e}',f'{d600:.8e}',max(x[1] for x in branch),min(x[1] for x in branch)])
    write_csv(OUT/'calibration_scan.csv',['V_total_mL','P_crit_mmHg','beta_R','k_sig_mmHg','Status','Baseline_MAP_mmHg','Cycle_Diff_300s','Cycle_Diff_600s','Max_Target_Sep_mmHg','Min_Target_Sep_mmHg'],rows)
    if selected:
        vt,pc,br,ks,m,d300,d600,fm,rm,branch=selected
        write_csv(OUT/'coexistence_multi_Rsys_summary.csv',['Rsys','MAP_Forward_mmHg','MAP_Reverse_mmHg','Max_Traj_Sep_Pa_mmHg','Branch_Cycle_Diff_300s','Branch_Cycle_Diff_600s'],[[r,f'{fm[int(round((r-.8)/.02))]:.8f}',f'{rm[int(round((r-.8)/.02))]:.8f}',f'{s:.8f}',f'{d3:.8e}',f'{d6:.8e}'] for r,s,d3,d6,_ in branch])
        np.savetxt(OUT/'forward_reverse_MAP.csv',np.column_stack((rv,fm,rm)),delimiter=',',header='Rsys,MAP_Forward_mmHg,MAP_Reverse_mmHg',comments='',fmt='%.8f')
        log.append('All three numerical gates passed; this is numerical calibration, not physiological validation.')
    else:
        log.append('NO PARAMETER SET PASSED ALL THREE CRITERIA on the defined grid.')
        log.append('No production model, audit script, or README parameter lock was changed.')
    log.append(f'Parameter sets screened: {len(rows)} / {len(combos)}; elapsed wall time: {time.time()-started:.2f} s')
    (OUT/'calibration_transcript.log').write_text('\\n'.join(log)+'\\n')
    print('\\n'.join(log))
    if selected is None:
        print('CALIBRATION_RESULT=NO_PASS')
        return 2
    print('CALIBRATION_RESULT=PASS')
    return 0

if __name__=='__main__':
    sys.exit(main())