```@meta
Description = "How the reaction wheel unicycle works."
```

# The Reaction Wheel Unicycle

``V_{cnt} = \begin{bmatrix} \dot{x} - r_w \dot{\theta} cos(\delta) \\ \dot{y} - r_w \dot{\theta} sin(\delta) \\ \dot{z} \end{bmatrix} = \begin{bmatrix} 0 \\ 0 \\ 0 \end{bmatrix}``

``\dot{x} = r_w \dot{\theta} cos(\delta)``

``\dot{y} = r_w \dot{\theta} sin(\delta)``

``\dot{z} = 0``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{q}_i}) - \frac{\partial L}{\partial q_i} = Q_i + \sum_{k=1}^n {\lambda}_k a_{ki}``

``i = 1, \ldots, m``

``L = T_{total} - P_{total}``

``{}_{w2}^{cp}T = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\alpha) & -sin(\alpha) & 0 \\ 0 & sin(\alpha) & cos(\alpha) & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & r_w \\ 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\alpha) & -sin(\alpha) & -r_w sin(\alpha) \\ 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{cp}^{g}T = \begin{bmatrix} cos(\delta) & -sin(\delta) & 0 & x \\ sin(\delta) & cos(\delta) & 0 & y \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{w2}^{g}T = {}_{cp}^{g}T  \times {}_{w2}^{cp}T  = \begin{bmatrix} cos(\delta) & -sin(\delta) cos(\alpha) & sin(\delta) sin(\alpha) & x + r_w sin(\delta) sin(\alpha) \\ sin(\delta) & cos(\delta) cos(\alpha) & -cos(\delta) sin(\alpha) & y - r_w cos(\delta) sin(\alpha) \\ 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}^{w2}P_w = \begin{bmatrix} 0 \\ 0 \\ 0 \\ 1 \end{bmatrix}``

``{}^gP_w = {}_{w2}^gT \times {}^{w2}P_w = \begin{bmatrix} x + r_w sin(\alpha) sin(\delta) \\ y - r_w sin(\alpha) cos(\delta) \\ r_w cos(\alpha) \\ 1 \end{bmatrix}``

``{}_c^{w2}T = \begin{bmatrix} cos(\beta) & 0 & sin(\beta) & 0 \\ 0 & 1 & 0 & 0 \\ -sin(\beta) & 0 & cos(\beta) & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & l_c \\ 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} cos(\beta) & 0 & sin(\beta) & l_c sin(\beta) \\ 0 & 1 & 0 & 0 \\ -sin(\beta) & 0 & cos(\beta) & l_c cos(\beta) \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_c^gT = {}_{w2}^gT \times {}_c^{w2}T = \begin{bmatrix} {}_c^gt_{11} & -sin(\delta) cos(\alpha) & {}_c^gt_{13} & {}_c^gt_{14} \\ {}_c^gt_{21} & cos(\delta) cos(\alpha) & {}_c^gt_{23} & {}_c^gt_{24} \\ -cos(\alpha) sin(\beta) & sin(\alpha) & cos(\alpha) cos(\beta) & {}_c^gt_{34} \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_c^gt_{11} = cos(\beta) cos(\delta) - sin(\alpha) sin(beta) sin(\delta)``

``{}_c^gt_{13} = sin(\beta) cos(\delta) + sin(\alpha) cos(\beta) sin(\delta)``

``{}_c^gt_{14} = x + r_w sin(\delta) sin(\alpha) + l_c sin(\beta) cos(\delta) + l_c sin(\alpha) cos(\beta) sin(\delta)``

``{}_c^gt_{21} = cos(\beta) sin(\delta) + sin(\alpha) sin(\beta) cos(\delta)``

``{}_c^gt_{23} = sin(\beta) sin(\delta) - sin(\alpha) cos(\beta) cos(\delta)``

``{}_c^gt_{24} = y - r_w cos(\delta) sin(\alpha) + l_c sin(\beta) sin(\delta) - l_c sin(\alpha) cos(\beta) cos(\delta)``

``{}_c^gt_{34} = r_w cos(\alpha) + l_c cos(\alpha) cos(\beta)``

``{}^cP_c = \begin{bmatrix} 0 \\ 0 \\ 0 \\ 1 \end{bmatrix}``

``{}^gP_c = {}_c^gT \times {}^cP_c = \begin{bmatrix} {}^gp_{c1} \\ {}^gp_{c2} \\ {}^gp_{c3} \\ 1 \end{bmatrix}``

``{}^gp_{c1} = x + r_w sin(\alpha) sin(\delta) + l_c cos(\beta) sin(\alpha) sin(\delta) + l_c sin(\beta) cos(\delta)``

``{}^gp_{c2} = y - r_w sin(\alpha) cos(\delta) - l_c cos(\beta) sin(\alpha) cos(\delta) + l_c sin(\beta) sin(\delta)``

``{}^gp_{c3} = r_w cos(\alpha) + l_c cos(\beta) cos(\alpha)``

``{}_r^cT = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & l_{cr} \\ 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\gamma) & -sin(\gamma) & 0 \\ 0 & sin(\gamma) & cos(\gamma) & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\gamma) & -sin(\gamma) & 0 \\ 0 & sin(\gamma) & cos(\gamma) & l_{cr} + 0 \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_r^gT = {}_c^gT \times {}_r^cT = \begin{bmatrix} {}_r^gt_{11} & {}_r^gt_{12} & {}_r^gt_{13} & {}_r^gt_{14} \\ {}_r^gt_{21} & {}_r^gt_{22} & {}_r^gt_{23} & {}_r^gt_{24} \\ -cos(\alpha) sin(\beta) & {}_r^gt_{32} & {}_r^gt_{33} & {}_r^gt_{34} \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_r^gt_{11} = cos(\beta) cos(\delta) - sin(\alpha) sin(\beta) sin(\delta)``

``{}_r^gt_{12} = -sin(\delta) cos(\alpha) cos(\gamma) + cos(\delta) sin(\beta) sin(\gamma) + sin(\delta) sin(\alpha) cos(\beta) sin(\gamma)``

``{}_r^gt_{13} = sin(\delta) cos(\alpha) sin(\gamma) + cos(\delta) sin(\beta) cos(\gamma) + sin(\delta) sin(\alpha) cos(\beta) cos(\gamma)``

``{}_r^gt_{14} = 0 + l_{cr} (cos(\delta) sin(\beta) + sin(\delta) sin(\alpha) cos(\beta)) + l_c sin(\beta) cos(\delta) + l_c cos(\beta) sin(\delta) sin(\alpha) + x + r_w sin(\delta) sin(\alpha)``

``{}_r^gt_{21} = cos(\beta) sin(\delta) + sin(\alpha) sin(\beta) cos(\delta)``

``{}_r^gt_{22} = cos(\delta) cos(\alpha) cos(\gamma) + sin(\delta) sin(\beta) sin(\gamma) - cos(\delta) sin(\alpha) cos(\beta) sin(\gamma)``

``{}_r^gt_{23} = -cos(\delta) cos(\alpha) sin(\gamma) + sin(\delta) sin(\beta) cos(\gamma) - cos(\delta) sin(\alpha) cos(\beta) cos(\gamma)``

``{}_r^gt_{24} = l_{cr} (sin(\delta) sin(\beta) - cos(\delta) sin(\alpha) cos(\beta)) + l_c sin(\beta) sin(\delta) - l_c cos(\beta) cos(\delta) sin(\alpha) + y - r_w cos(\delta) sin(\alpha)``

``{}_r^gt_{32} = sin(\alpha) cos(\gamma) + cos(\alpha) cos(\beta) sin(\gamma)``

``{}_r^gt_{33} = -sin(\alpha) sin(\gamma) + cos(\alpha) cos(\beta) cos(\gamma)``

``{}_r^gt_{34} = l_{cr} cos(\alpha) cos(\beta) + l_c cos(\beta) cos(\alpha) + r_w cos(\alpha)``

``{}^rP_r = \begin{bmatrix} 0 \\ 0 \\ 0 \\ 1 \end{bmatrix}``

``{}^gP_r = {}_r^gT \times {}^rP_r = \begin{bmatrix} {}^gp_{r1} \\ {}^gp_{r2} \\ {}^gp_{r3} \\ 1 \end{bmatrix}``

``{}^gp_{r1} = x + r_w sin(\alpha) sin(\delta) + (l_c + l_{cr}) cos(\beta) sin(\alpha) sin(\delta) + (l_c + l_{cr}) sin(\beta) cos(\delta)``

``{}^gp_{r2} = y - r_w sin(\alpha) cos(\delta) - (l_c + l_{cr}) cos(\beta) sin(\alpha) cos(\delta) + (l_c + l_{cr}) sin(\beta) sin(\delta)``

``{}^gp_{r3} = r_w cos(\alpha) + (l_c + l_{cr}) cos(\beta) cos(\alpha)``

``V_w = \frac{dP_w}{dt}``

``V_c = \frac{dP_c}{dt}``

``V_r = \frac{dP_r}{dt}``

``{\Omega}_w = \begin{bmatrix} 0 \\ \dot{\theta} \\ 0 \\ 0 \end{bmatrix} + \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_g^{w2}T \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} 0 \\ \dot{\theta} \\ 0 \\ 0 \end{bmatrix} + \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_{w2}^gT^{-1} \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} \dot{\alpha} \\ \dot{\theta} + \dot{\delta} sin(\alpha) \\ \dot{\delta} cos(\alpha) \end{bmatrix}``

``{\Omega}_c = \begin{bmatrix} 0 \\ \dot{\beta} \\ 0 \\ 0 \end{bmatrix} + {}_{w2}^cT \times \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_g^cT \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} 0 \\ \dot{\beta} \\ 0 \\ 0 \end{bmatrix} + {}_c^{w2}T^{-1} \times \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_c^gT^{-1} \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} \dot{\alpha} cos(\beta) - \dot{\delta} cos(\alpha) sin(\beta) \\ \dot{\beta} + \dot{\delta} sin(\alpha) \\ \dot{\alpha} sin(\beta) + \dot{\delta} cos(\alpha) cos(\beta) \\ 0 \end{bmatrix}``

``{}_r^{w2}T = {}_{w2}^gT^{-1} \times {}_r^gT``

``{\Omega}_r = \begin{bmatrix} \dot{\gamma} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_c^rT \times \begin{bmatrix} 0 \\ \dot{\beta} \\ 0 \\ 0 \end{bmatrix} + {}_{w2}^rT \times \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_g^rT \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} \dot{\gamma} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_r^cT^{-1} \times \begin{bmatrix} 0 \\ \dot{\beta} \\ 0 \\ 0 \end{bmatrix} + {}_r^{w2}T^{-1} \times \begin{bmatrix} \dot{\alpha} \\ 0 \\ 0 \\ 0 \end{bmatrix} + {}_r^gT^{-1} \times \begin{bmatrix} 0 \\ 0 \\ \dot{\delta} \\ 0 \end{bmatrix} = \begin{bmatrix} \dot{\gamma} + \dot{\alpha} cos(\beta) - \dot{\delta} cos(\alpha) sin(\beta) \\ {\omega}_{r2} \\ {\omega}_{r3} \\ 0 \end{bmatrix}``

``{\omega}_{r2} = \dot{\beta} cos(\gamma) + \dot{\alpha} sin(\beta) sin(\gamma) + \dot{\delta} sin(\alpha) cos(\gamma) + \dot{\delta} cos(\alpha) cos(\beta) sin(\gamma)``

``{\omega}_{r3} = -\dot{\beta} sin(\gamma) + \dot{\alpha} sin(\beta) cos(\gamma) - \dot{\delta} sin(\alpha) sin(\gamma) + \dot{\delta} cos(\alpha) cos(\beta) cos(\gamma)``

``T_w = \frac{1}{2} m_w V_w^T V_w + \frac{1}{2} {\Omega}_w^T I_w {\Omega}_w``

``P_w = m_w g P_w(3)``

``T_c = \frac{1}{2} m_c V_c^T V_c + \frac{1}{2} {\Omega}_c^T I_c {\Omega}_c``

``P_c = m_c g P_c(3)``

``T_r = \frac{1}{2} m_r V_r^T V_r + \frac{1}{2} {\Omega}_r^T I_r {\Omega}_r``

``P_r = m_r g P_r(3)``

``T_{total} = T_w + T_c + T_r``

``P_{total} = P_w + P_c + P_r``

``m = 7, \ n = 2``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{x}}) - \frac{\partial L}{\partial x} = {\lambda}_1``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{y}}) - \frac{\partial L}{\partial y} = {\lambda}_2``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{\theta}}) - \frac{\partial L}{\partial \theta} = {\tau}_w - r_w cos(\delta) {\lambda}_1 - r_w sin(\delta) {\lambda}_2``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{\beta}}) - \frac{\partial L}{\partial \beta} = -{\tau}_w``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{\alpha}}) - \frac{\partial L}{\partial \alpha} = 0``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{\gamma}}) - \frac{\partial L}{\partial \gamma} = {\tau}_r``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{\delta}}) - \frac{\partial L}{\partial \delta} = 0``

Wheel dynamics:

``m_{11} \ddot{\beta} + m_{12} \ddot{\gamma} + m_{13} \ddot{\delta} + m_{14} \ddot{\theta} + c_{11} \dot{\beta}^2 + c_{12} \dot{\gamma}^2 + c_{13} \dot{\delta}^2 + c_{14} \dot{\alpha} \dot{\delta} + c_{15} \dot{\beta} \dot{\gamma} + c_{16} \dot{\beta} \dot{\delta} + c_{17} \dot{\gamma} \dot{\delta} = {\tau}_w``

Chassis longitudinal dynamics:

``m_{21} \ddot{\alpha} + m_{22} \ddot{\beta} + m_{23} \ddot{\delta} + m_{24} \ddot{\theta} + c_{21} \dot{\alpha}^2 + c_{22} \dot{\delta}^2 + c_{23} \dot{\alpha} \dot{\gamma} + c_{24} \dot{\alpha} \dot{\delta} + c_{25} \dot{\beta} \dot{\gamma} + c_{26} \dot{\gamma} \dot{\delta} + c_{27} \dot{\delta} \dot{\theta} + g_{21} = -{\tau}_w``

Chassis lateral dynamics:

``m_{31} \ddot{\alpha} + m_{32} \ddot{\beta} + m_{33} \ddot{\gamma} + m_{34} \ddot{\delta} + c_{31} \dot{\beta}^2 + c_{32} \dot{\gamma}^2 + c_{33} \dot{\delta}^2 + c_{34} \dot{\alpha} \dot{\beta} + c_{35} \dot{\alpha} \dot{\gamma} + c_{36} \dot{\beta} \dot{\gamma} + c_{37} \dot{\beta} \dot{\delta} + c_{38} \dot{\gamma} \dot{\delta} + c_{39} \dot{\delta} \dot{\theta} = 0``

Reaction wheel dynamics:

``m_{41} \ddot{\alpha} + m_{42} \ddot{\gamma} + m_{43} \ddot{\delta} + m_{44} \ddot{\theta} + c_{41} \dot{\alpha}^2 + c_{42} \dot{\beta}^2 + c_{43} \dot{\delta}^2 + c_{44} \dot{\alpha} \dot{\beta} + c_{45} \dot{\alpha} \dot{\delta} + c_{46} \dot{\beta} \dot{\delta} + c_{47} \dot{\delta} \dot{\theta} + g_{41} = {\tau}_r``

Turning dynamics:

``m_{51} \ddot{\alpha} + m_{52} \ddot{\beta} + m_{53} \ddot{\gamma} + m_{54} \ddot{\delta} + m_{55} \ddot{\theta} + c_{51} \dot{\alpha}^2 + c_{52} \dot{\beta}^2 + c_{53} \dot{\gamma}^2 + c_{54} \dot{\alpha} \dot{\beta} + c_{55} \dot{\alpha} \dot{\gamma} + c_{56} \dot{\alpha} \dot{\delta} + c_{57} \dot{\alpha} \dot{\theta} + c_{58} \dot{\beta} \dot{\gamma} + c_{59} \dot{\beta} \dot{\delta} + c_{510} \dot{\gamma} \dot{\delta} + c_{511} \dot{\delta} \dot{\theta} = 0``