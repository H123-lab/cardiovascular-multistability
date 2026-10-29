# Raw Sensitivity Screen Logs

This directory captures raw sensitivity outputs mapping independent One-At-A-Time (OAT) variations across companion system constants ($E_{max}$, $C_a$, $C_v$).

## Output Metadata Layout
Individual text logs record terminal cycle properties across parameter intervals:
* `row_entry`: Evaluated local parameter scalar coordinate
* `MAP_mean`: Calculated steady-state mean arterial pressure output
* `CO_mean`: Calculated steady-state cardiac output level
* `converged_flag`: Numerical validation check bit (`1` = Converged Limit Cycle, `0` = Unstable/Divergent)
