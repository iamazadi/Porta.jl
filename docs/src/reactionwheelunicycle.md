```@meta
Description = "How the reaction wheel unicycle works."
```

## The Reaction Wheel Unicycle

``V_{cnt} = \begin{bmatrix} \dot{x} - r_w \dot{\theta} cos(\delta) \newline \dot{y} - r_w \dot{\theta} sin(\delta) \newline \dot{z} \end{bmatrix} = \begin{bmatrix} 0 \newline 0 \newline 0 \end{bmatrix}``

``\dot{x} = r_w \dot{\theta} cos(\delta)``

``\dot{y} = r_w \dot{\theta} sin(\delta)``

``\dot{z} = 0``

``\frac{d}{dt}(\frac{\partial L}{\partial \dot{q}_i}) - \frac{\partial L}{\partial q_i} = Q_i + \sum_{k=1}^n {\lambda}_k a_{ki}``

``i = 1, \ldots, m``

``L = T_{total} - P_{total}``

``{}_{w2}^{cp}T = \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & cos(\alpha) & -sin(\alpha) & 0 \newline 0 & sin(\alpha) & cos(\alpha) & 0 \newline 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & 1 & 0 & 0 \newline 0 & 0 & 1 & r_w \newline 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & cos(\alpha) & -sin(\alpha) & -r_w sin(\alpha) \newline 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{cp}^{g}T = \begin{bmatrix} cos(\delta) & -sin(\delta) & 0 & x \newline sin(\delta) & cos(\delta) & 0 & y \newline 0 & 0 & 1 & 0 \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{w2}^{g}T = {}_{cp}^{g}T  \times {}_{w2}^{cp}T  = \begin{bmatrix} cos(\delta) & -sin(\delta) cos(\alpha) & sin(\delta) sin(\alpha) & x + r_w sin(\delta) sin(\alpha) \newline sin(\delta) & cos(\delta) cos(\alpha) & -cos(\delta) sin(\alpha) & y - r_w cos(\delta) sin(\alpha) \newline 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}^{w2}P_w = \begin{bmatrix} 0 \newline 0 \newline 0 \newline 1 \end{bmatrix}``

``{}^gP_w = {}_{w2}^gT \times {}^{w2}P_w = \begin{bmatrix} x + r_w sin(\alpha) sin(\delta) \newline y - r_w sin(\alpha) cos(\delta) \newline r_w cos(\alpha) \newline 1 \end{bmatrix}``

``{}_c^{w2}T = \begin{bmatrix} cos(\beta) & 0 & sin(\beta) & 0 \newline 0 & 1 & 0 & 0 \newline -sin(\beta) & 0 & cos(\beta) & 0 \newline 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & 1 & 0 & 0 \newline 0 & 0 & 1 & l_c \newline 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} cos(\beta) & 0 & sin(\beta) & l_c sin(\beta) \newline 0 & 1 & 0 & 0 \newline -sin(\beta) & 0 & cos(\beta) & l_c cos(\beta) \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_c^gT = {}_{w2}^gT \times {}_c^{w2}T = \begin{bmatrix} {}_c^gt_{11} & -sin(\delta) cos(\alpha) & {}_c^gt_{13} & {}_c^gt_{14} \newline {}_c^gt_{21} & cos(\delta) cos(\alpha) & {}_c^gt_{23} & {}_c^gt_{24} \newline -cos(\alpha) sin(\beta) & sin(\alpha) & cos(\alpha) cos(\beta) & {}_c^gt_{34} \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_c^gt_{11} = cos(\beta) cos(\delta) - sin(\alpha) sin(beta) sin(\delta)``

``{}_c^gt_{13} = sin(\beta) cos(\delta) + sin(\alpha) cos(\beta) sin(\delta)``

``{}_c^gt_{14} = x + r_w sin(\delta) sin(\alpha) + l_c sin(\beta) cos(\delta) + l_c sin(\alpha) cos(\beta) sin(\delta)``

``{}_c^gt_{21} = cos(\beta) sin(\delta) + sin(\alpha) sin(\beta) cos(\delta)``

``{}_c^gt_{23} = sin(\beta) sin(\delta) - sin(\alpha) cos(\beta) cos(\delta)``

``{}_c^gt_{24} = y - r_w cos(\delta) sin(\alpha) + l_c sin(\beta) sin(\delta) - l_c sin(\alpha) cos(\beta) cos(\delta)``

``{}_c^gt_{34} = r_w cos(\alpha) + l_c cos(\alpha) cos(\beta)``

``{}^cP_c = \begin{bmatrix} 0 \newline 0 \newline 0 \newline 1 \end{bmatrix}``

``{}^gP_c = {}_c^gT \times {}^cP_c = \begin{bmatrix} {}^gp_{c1} \newline {}^gp_{c2} \newline {}^gp_{c3} \newline 1 \end{bmatrix}``

``{}^gp_{c1} = x + r_w sin(\alpha) sin(\delta) + l_c cos(\beta) sin(\alpha) sin(\delta) + l_c sin(\beta) cos(\delta)``

``{}^gp_{c2} = y - r_w sin(\alpha) cos(\delta) - l_c cos(\beta) sin(\alpha) cos(\delta) + l_c sin(\beta) sin(\delta)``

``{}^gp_{c3} = r_w cos(\alpha) + l_c cos(\beta) cos(\alpha)``

``{}_r^cT = \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & 1 & 0 & 0 \newline 0 & 0 & 1 & l_{cr} \newline 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & cos(\gamma) & -sin(\gamma) & 0 \newline 0 & sin(\gamma) & cos(\gamma) & 0 \newline 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & 1 & 0 & 0 \newline 0 & 0 & 1 & 0 \newline 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & 0 \newline 0 & cos(\gamma) & -sin(\gamma) & 0 \newline 0 & sin(\gamma) & cos(\gamma) & l_{cr} \newline 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_r^gT = {}_c^gT \times {}_r^cT = \begin{bmatrix} {}_r^gt_{11} & {}_r^gt_{12} & {}_r^gt_{13} & {}_r^gt_{14} \newline {}_r^gt_{21} & {}_r^gt_{22} & {}_r^gt_{23} & {}_r^gt_{24} \newline -cos(\alpha) sin(\beta) & {}_r^gt_{32} & {}_r^gt_{33} & {}_r^gt_{34} \newline 0 & 0 & 0 & 1 \end{bmatrix}``

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

``{}^rP_r = \begin{bmatrix} 0 \newline 0 \newline 0 \newline 1 \end{bmatrix}``

``{}^gP_r = {}_r^gT \times {}^rP_r = \begin{bmatrix} {}^gp_{r1} \newline {}^gp_{r2} \newline {}^gp_{r3} \newline 1 \end{bmatrix}``

``{}^gp_{r1} = x + r_w sin(\alpha) sin(\delta) + (l_c + l_{cr}) cos(\beta) sin(\alpha) sin(\delta) + (l_c + l_{cr}) sin(\beta) cos(\delta)``

``{}^gp_{r2} = y - r_w sin(\alpha) cos(\delta) - (l_c + l_{cr}) cos(\beta) sin(\alpha) cos(\delta) + (l_c + l_{cr}) sin(\beta) sin(\delta)``

``{}^gp_{r3} = r_w cos(\alpha) + (l_c + l_{cr}) cos(\beta) cos(\alpha)``

``V_w = \frac{dP_w}{dt}``

``V_c = \frac{dP_c}{dt}``

``V_r = \frac{dP_r}{dt}``

``{\Omega}_w = \begin{bmatrix} 0 \newline \dot{\theta} \newline 0 \newline 0 \end{bmatrix} + \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_g^{w2}T \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} 0 \newline \dot{\theta} \newline 0 \newline 0 \end{bmatrix} + \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_{w2}^gT^{-1} \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} \dot{\alpha} \newline \dot{\theta} + \dot{\delta} sin(\alpha) \newline \dot{\delta} cos(\alpha) \end{bmatrix}``

``{\Omega}_c = \begin{bmatrix} 0 \newline \dot{\beta} \newline 0 \newline 0 \end{bmatrix} + {}_{w2}^cT \times \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_g^cT \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} 0 \newline \dot{\beta} \newline 0 \newline 0 \end{bmatrix} + {}_c^{w2}T^{-1} \times \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_c^gT^{-1} \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} \dot{\alpha} cos(\beta) - \dot{\delta} cos(\alpha) sin(\beta) \newline \dot{\beta} + \dot{\delta} sin(\alpha) \newline \dot{\alpha} sin(\beta) + \dot{\delta} cos(\alpha) cos(\beta) \newline 0 \end{bmatrix}``

``{}_r^{w2}T = {}_{w2}^gT^{-1} \times {}_r^gT``

``{\Omega}_r = \begin{bmatrix} \dot{\gamma} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_c^rT \times \begin{bmatrix} 0 \newline \dot{\beta} \newline 0 \newline 0 \end{bmatrix} + {}_{w2}^rT \times \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_g^rT \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} \dot{\gamma} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_r^cT^{-1} \times \begin{bmatrix} 0 \newline \dot{\beta} \newline 0 \newline 0 \end{bmatrix} + {}_r^{w2}T^{-1} \times \begin{bmatrix} \dot{\alpha} \newline 0 \newline 0 \newline 0 \end{bmatrix} + {}_r^gT^{-1} \times \begin{bmatrix} 0 \newline 0 \newline \dot{\delta} \newline 0 \end{bmatrix} = \begin{bmatrix} \dot{\gamma} + \dot{\alpha} cos(\beta) - \dot{\delta} cos(\alpha) sin(\beta) \newline {\omega}_{r2} \newline {\omega}_{r3} \newline 0 \end{bmatrix}``

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


``
\frac{\mathrm{d} x\left( t \right)}{\mathrm{d}t} = r_{w} \cos\left( \delta\left( t \right) \right) \frac{\mathrm{d} \theta\left( t \right)}{\mathrm{d}t} \newline
\frac{\mathrm{d} y\left( t \right)}{\mathrm{d}t} = r_{w} \sin\left( \delta\left( t \right) \right) \frac{\mathrm{d} \theta\left( t \right)}{\mathrm{d}t} \newline
\frac{\mathrm{d} z\left( t \right)}{\mathrm{d}t} = 0 \newline
I_{w} = \left[
\begin{array}{cccc}
I_{w1} & 0 & 0 & 0 \newline
0 & I_{w2} & 0 & 0 \newline
0 & 0 & I_{w3} & 0 \newline
0 & 0 & 0 & 0 \newline
\end{array}
\right] \newline
I_{c} = \left[
\begin{array}{cccc}
I_{c1} & 0 & 0 & 0 \newline
0 & I_{c2} & 0 & 0 \newline
0 & 0 & I_{c3} & 0 \newline
0 & 0 & 0 & 0 \newline
\end{array}
\right] \newline
I_{r} = \left[
\begin{array}{cccc}
I_{r1} & 0 & 0 & 0 \newline
0 & I_{r2} & 0 & 0 \newline
0 & 0 & I_{r3} & 0 \newline
0 & 0 & 0 & 0 \newline
\end{array}
\right] \newline
\mathrm{w2cpT}\left( t \right) = \left[
\begin{array}{cccc}
1 & 0 & 0 & 0 \newline
0 & \cos\left( \alpha\left( t \right) \right) &  - \sin\left( \alpha\left( t \right) \right) &  - r_{w} \sin\left( \alpha\left( t \right) \right) \newline
0 & \sin\left( \alpha\left( t \right) \right) & \cos\left( \alpha\left( t \right) \right) & r_{w} \cos\left( \alpha\left( t \right) \right) \newline
0 & 0 & 0 & 1 \newline
\end{array}
\right] \newline
\mathrm{cpgT}\left( t \right) = \left[
\begin{array}{cccc}
\cos\left( \delta\left( t \right) \right) &  - \sin\left( \delta\left( t \right) \right) & 0 & x\left( t \right) \newline
\sin\left( \delta\left( t \right) \right) & \cos\left( \delta\left( t \right) \right) & 0 & y\left( t \right) \newline
0 & 0 & 1 & 0 \newline
0 & 0 & 0 & 1 \newline
\end{array}
\right] \newline
\mathrm{w2gT}\left( t \right) = \mathrm{cpgT}\left( t \right) \mathrm{w2cpT}\left( t \right) \newline
w2P_{w} = \left[
\begin{array}{c}
0 \newline
0 \newline
0 \newline
1 \newline
\end{array}
\right] \newline
\mathrm{gP}_{w}\left( t \right) = \mathrm{w2gT}\left( t \right) w2P_{w} \newline
\mathrm{cw2T}\left( t \right) = \left[
\begin{array}{cccc}
\cos\left( \beta\left( t \right) \right) & 0 & \sin\left( \beta\left( t \right) \right) & l_{c} \sin\left( \beta\left( t \right) \right) \newline
0 & 1 & 0 & 0 \newline
 -\sin\left( \beta\left( t \right) \right) & 0 & \cos\left( \beta\left( t \right) \right) & l_{c} \cos\left( \beta\left( t \right) \right) \newline
0 & 0 & 0 & 1 \newline
\end{array}
\right] \newline
\mathrm{cgT}\left( t \right) = \mathrm{w2gT}\left( t \right) \mathrm{cw2T}\left( t \right) \newline
cP_{c} = \left[
\begin{array}{c}
0 \newline
0 \newline
0 \newline
1 \newline
\end{array}
\right] \newline
\mathrm{gP}_{c}\left( t \right) = \mathrm{cgT}\left( t \right) cP_{c} \newline
\mathrm{rcT}\left( t \right) = \left[
\begin{array}{cccc}
1 & 0 & 0 & 0 \newline
0 & \cos\left( \gamma\left( t \right) \right) &  - \sin\left( \gamma\left( t \right) \right) & 0 \newline
0 & \sin\left( \gamma\left( t \right) \right) & \cos\left( \gamma\left( t \right) \right) & l_{cr} \newline
0 & 0 & 0 & 1 \newline
\end{array}
\right] \newline
\mathrm{rgT}\left( t \right) = \mathrm{cgT}\left( t \right) \mathrm{rcT}\left( t \right) \newline
rP_{r} = \left[
\begin{array}{c}
0 \newline
0 \newline
0 \newline
1 \newline
\end{array}
\right] \newline
\mathrm{gP}_{r}\left( t \right) = \mathrm{rgT}\left( t \right) rP_{r} \newline
\mathrm{rw2T}\left( t \right) = \mathrm{inv}\left( \mathrm{w2gT}\left( t \right) \right) \mathrm{rgT}\left( t \right) \newline
V_{w}\left( t \right) = \mathrm{broadcast}\left( D, \mathrm{gP}_{w}\left( t \right) \right) \newline
V_{c}\left( t \right) = \mathrm{broadcast}\left( D, \mathrm{gP}_{c}\left( t \right) \right) \newline
V_{r}\left( t \right) = \mathrm{broadcast}\left( D, \mathrm{gP}_{r}\left( t \right) \right) \newline
\Omega_{w}\left( t \right) = \mathrm{broadcast}\left( +, \left[
\begin{array}{c}
_{derivative}\left( \alpha\left( t \right), t, 1 \right) \newline
_{derivative}\left( \theta\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
\end{array}
\right], \mathrm{inv}\left( \mathrm{w2gT}\left( t \right) \right) \left[
\begin{array}{c}
0 \newline
0 \newline
_{derivative}\left( \delta\left( t \right), t, 1 \right) \newline
0 \newline
\end{array}
\right] \right) \newline
\Omega_{c}\left( t \right) = \mathrm{broadcast}\left( +, \mathrm{broadcast}\left( +, \left[
\begin{array}{c}
0 \newline
_{derivative}\left( \beta\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
\end{array}
\right], \mathrm{inv}\left( \mathrm{cw2T}\left( t \right) \right) \left[
\begin{array}{c}
_{derivative}\left( \alpha\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
0 \newline
\end{array}
\right] \right), \mathrm{inv}\left( \mathrm{cgT}\left( t \right) \right) \left[
\begin{array}{c}
0 \newline
0 \newline
_{derivative}\left( \delta\left( t \right), t, 1 \right) \newline
0 \newline
\end{array}
\right] \right) \newline
\Omega_{r}\left( t \right) = \mathrm{broadcast}\left( +, \mathrm{broadcast}\left( +, \mathrm{broadcast}\left( +, \left[
\begin{array}{c}
_{derivative}\left( \gamma\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
0 \newline
\end{array}
\right], \mathrm{inv}\left( \mathrm{rcT}\left( t \right) \right) \left[
\begin{array}{c}
0 \newline
_{derivative}\left( \beta\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
\end{array}
\right] \right), \mathrm{inv}\left( \mathrm{rw2T}\left( t \right) \right) \left[
\begin{array}{c}
_{derivative}\left( \alpha\left( t \right), t, 1 \right) \newline
0 \newline
0 \newline
0 \newline
\end{array}
\right] \right), \mathrm{inv}\left( \mathrm{rgT}\left( t \right) \right) \left[
\begin{array}{c}
0 \newline
0 \newline
_{derivative}\left( \delta\left( t \right), t, 1 \right) \newline
0 \newline
\end{array}
\right] \right) \newline
T_{w}\left( t \right) = \mathrm{adjoint}\left( V_{w}\left( t \right) \right) \mathrm{broadcast}\left( *, V_{w}\left( t \right), \mathrm{Ref}\left( 0.5 m_{w} \right) \right)_{1} + \mathrm{adjoint}\left( \Omega_{w}\left( t \right) \right) \mathrm{broadcast}\left( *, I_{w} \Omega_{w}\left( t \right), 0.5 \right)_{1} \newline
P_{w}\left( t \right) = g \mathrm{gP}_{w}\left( t \right)_{3} m_{w} \newline
T_{c}\left( t \right) = \mathrm{adjoint}\left( V_{c}\left( t \right) \right) \mathrm{broadcast}\left( *, V_{c}\left( t \right), \mathrm{Ref}\left( 0.5 m_{c} \right) \right)_{1} + \mathrm{adjoint}\left( \Omega_{c}\left( t \right) \right) \mathrm{broadcast}\left( *, I_{c} \Omega_{c}\left( t \right), 0.5 \right)_{1} \newline
P_{c}\left( t \right) = g \mathrm{gP}_{c}\left( t \right)_{3} m_{c} \newline
T_{r}\left( t \right) = \mathrm{adjoint}\left( V_{r}\left( t \right) \right) \mathrm{broadcast}\left( *, V_{r}\left( t \right), \mathrm{Ref}\left( 0.5 m_{r} \right) \right)_{1} + \mathrm{adjoint}\left( \Omega_{r}\left( t \right) \right) \mathrm{broadcast}\left( *, I_{r} \Omega_{r}\left( t \right), 0.5 \right)_{1} \newline
P_{r}\left( t \right) = g \mathrm{gP}_{r}\left( t \right)_{3} m_{r} \newline
T_{total}\left( t \right) = T_{r}\left( t \right) + T_{c}\left( t \right) + T_{w}\left( t \right) \newline
P_{total}\left( t \right) = P_{w}\left( t \right) + P_{c}\left( t \right) + P_{r}\left( t \right) \newline
L\left( t \right) = T_{total}\left( t \right) - P_{total}\left( t \right) \newline
``


``\left[
\begin{array}{c}
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
_{derivative}\left( 0, t, 1 \right) \newline
\end{array}
\right] = \left[
\begin{array}{c}
\lambda_1 \newline
\lambda_2 \newline
\tau_{w} - r_{w} \sin\left( \delta\left( t \right) \right) \lambda_2 - r_{w} \cos\left( \delta\left( t \right) \right) \lambda_1 \newline
 -\tau_{w} \newline
0 \newline
\tau_{p} \newline
0 \newline
\end{array}
\right]``


## References
1. Yohanes Daud, Abdullah Al Mamun and Jian-Xin Xu, *Dynamic modeling and characteristics analysis of lateral-pendulum unicycle robot*, Robotica (2017) volume 35, pp. 537–568. Cambridge University Press 2015, doi: 10.1017/S0263574715000703.

2. Sebastian Trimpe and Raffaello D’Andrea, *Accelerometer-based Tilt Estimation of a Rigid Body with only Rotational Degrees of Freedom*, 2010 IEEE International Conference on Robotics and Automation, Anchorage Convention District, May 3-8, 2010, Anchorage, Alaska, USA.

3. K. G. Vamvoudakis, D. Vrabie and F. L. Lewis, "Online adaptive learning of optimal control solutions using integral reinforcement learning," 2011 IEEE Symposium on Adaptive Dynamic Programming and Reinforcement Learning (ADPRL), Paris, France, 2011, pp. 250-257, doi: 10.1109/ADPRL.2011.5967359.

4. Y. Engel, S. Mannor, and R. Meir, “The kernel recursive least-squares algorithm,” IEEE Transactions on Signal Processing, vol. 52, no. 8, pp. 2275–2285, 2004.

5. C. Fernandes, L. Gurvits and Z. X. Li, "Attitude control of space platform/manipulator system using internal motion," Proceedings 1992 IEEE International Conference on Robotics and Automation, Nice, France, 1992, pp. 893-898 vol.1, doi: 10.1109/ROBOT.1992.220183.

6. G. C. Walsh and S. S. Sastry, "On reorienting linked rigid bodies using internal motions," in IEEE Transactions on Robotics and Automation, vol. 11, no. 1, pp. 139-146, Feb. 1995, doi: 10.1109/70.345946.

7. Hayes, Monson H. (1996). "9.4: Recursive Least Squares". Statistical Digital Signal Processing and Modeling. Wiley. p. 541. ISBN 0-471-59431-8.

8. Richard M. Murray, Zexiang Li, and S. Shankar Sastry, *A Mathematical Introduction to Robotic Manipulation*, CRC-Press, March 22, 1994, ISBN 9780849379819, 0849379814.