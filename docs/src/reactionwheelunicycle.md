```@meta
Description = "How the reaction wheel unicycle works."
```

# The Reaction Wheel Unicycle

``V_{cnt} = \begin{bmatrix} \dot{x} - r_w \dot{\theta} cos(\delta) \\ \dot{y} - r_w \dot{\theta} sin(\delta) \\ \dot{z} \end{bmatrix} = \begin{bmatrix} 0 \\ 0 \\ 0 \end{bmatrix}``

``\dot{x} = r_w \dot{\theta} cos(\delta)``
``\dot{y} = r_w \dot{\theta} sin(\delta)``
``\dot{z} = 0``

``\dv{d}{dt}(\pdv{L}{\dot{q}_i) - \pdv{L}{q_i} = Q_i + \sum_{k=1}^n {\lambda}_k a_{ki}``
``i = 1, \ldots, m``

``L = T_{total} - P_{total}``

``{}_{w2}^{cp}T = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\alpha) & -sin(\alpha) & 0 \\ 0 & sin(\alpha) & cos(\alpha) & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & 1 & 0 & 0 \\ 0 & 0 & 1 & r_w \\ 0 & 0 & 0 & 1 \end{bmatrix} = \begin{bmatrix} 1 & 0 & 0 & 0 \\ 0 & cos(\alpha) & -sin(\alpha) & -r_w sin(\alpha) \\ 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{cp}^{g}T = \begin{bmatrix} cos(\delta) & -sin(\delta) & 0 & x \\ sin(\delta) & cos(\delta) & 0 & y \\ 0 & 0 & 1 & 0 \\ 0 & 0 & 0 & 1 \end{bmatrix}``

``{}_{w2}^{g}T = {}_{cp}^{g}T  * {}_{w2}^{cp}T  = \begin{bmatrix} cos(\delta) & -sin(\delta) cos(\alpha) & sin(\delta) sin(\alpha) & x + r_w sin(\delta) sin(\alpha) \\ sin(\delta) & cos(\delta) cos(\alpha) & -cos(\delta) sin(\alpha) & y - r_w cos(\delta) sin(\alpha) \\ 0 & sin(\alpha) & cos(\alpha) & r_w cos(\alpha) \\ 0 & 0 & 0 & 1 \end{bmatrix}``