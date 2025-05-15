```@meta
Description = "General Mathematics 2"
```

# Multivariable Functions

In General Mathematics 1, we were introduced to one-variable functions ``y = f(x)``, that had only one independent variable as input, ``x``. But in reality most of the times, we are faced with functions that have more than one independent variable. These functions are called multivariable functions.

``y = f(x)`` is a univariate function.

The function sends the input to the output, ``x \mapsto y``.

## Notation

- A two-variable function: ``z = f(x, y)``.

- A three-variable function is denoted by ``w = f(x, y, z)``.

- An n-variballe function: ``f(x_1, x_2, ..., x_n)``.

A few simple examples that show the relevance of multivariable functions.

### Example

The area of a rectangle: ``f(x, y) = xy``.

The volume of a sphere: ``V(x, y, z) = xyz``.

The volume of a cylinder: ``V(r, h) = \pi r^2 h``.

### Example

The average of the ``n`` numbers ``x_1, x_2, ..., x_n``:

``f(x_1, x_2, ..., x_n) = \frac{1}{n} \sum_{i = 1}^n x_i``.

## The Domain of Multi-variale Functions

The domain of the two-variable function ``f(x, y)`` is either a point in the ``x-y`` plane, or part, or the entire coordinate system ``x-y \in \mathbb{R}^2 ``.

### Example

Find the domain of the follwoing functions and then plot it as a shape.

*Example A.* ``f(x, y) = 2x^3 y + x^2 y^2 - y + 5``
``D_f = \{ (x, y) | x \in \mathbb{R}, y \in \mathbb{R} \} = \mathbb{R}^2``.

*Example B.* ``f(x, y) = \frac{1}{x - y}``

``D_f = \{ (x, y) | x - y \neq 0 \} = \{ (x, y) | x \neq y \}``.

The whole plane, with the line ``y = x`` removed.

*Example C.* ``f(x, y) = \sqrt{x - y}``

``D_f = \{ (x, y) | x - y \geq 0 \} = \{ (x, y) | x \geq y \}``.

On and under the line `` y = x``.

*Example D.* ``f(x, y) = \frac{\sqrt{y - 3}}{\sqrt{5 - x}}``

``D_f = \{ (x, y) | y - 3 \geq 0, 5 - x > 0 \} = \{ (x, y) | y \geq 3, x < 5 \}``.

*Example E.* ``f(x, y) = \frac{\sqrt{y + 1}}{\sqrt[n]{2 - |x|}}``

``D_f = \{ (x, y) | y + 1 \geq 0, 2 - |x| > 0 \} = \{ (x, y) | y \geq -1, -2 < x < 2 \}``.

The shape of two-variable functions are going to be three-dimensional plots, which are also called surfaces.

``z = f(x, y)``.

The triple ``(x, y, z)``.

Since drawing three-dimensional shapes is time consuming, we just make a few examples of surfaces.

And by induction in this way, the domain of the three-variable function ``w = f(x, y, z)`` is three-dimensional, and its plot is four-dimensional.

# Partial Derivatives

``y = f(x)``.

``y = x^3 - 2x^5 + sin(x)``.

``y\prime = f\prime(x)``.

``y\prime = 3x^2 - 10x^4 + cos(x)``.

``f\prime(x) = \lim_{h \to 0} \frac{f(x + h) - f(x)}{h}``.

``f(x, y)``.

When we want to find the derivative of a multivariable function, we must specify with respect to which variable the derivative is to be applied. Other than the one variable, with respect to which the derivative is computed, the rest of the variables are trated as constant values.

The derivative of the function ``f(x, y)`` with respect to ``x`` is denoted by ``\frac{\partial f}{\partial x}`` or ``{f\prime}_x``.
The derivative of the function ``f(x, y)`` with respect to ``y`` is denoted by ``\frac{\partial f}{\partial y}`` or ``{f\prime}_y``.

### Example

If the function ``f(x, y) = -3x^4 y^2 + x^3 y - y^3 + xy`` is defined, then compute the derivative of ``f(x, y)`` with respect to ``x`` and the derivative of ``f(x, y)`` with respect to ``y``.

- ``\frac{\partial f}{\partial x} = -12x^3 y^2 + 3x^2 y + y``.

- ``\frac{\partial f}{\partial y} = -6x^4 y + x^3 -3y^2 + x``.

### Example

If the function ``f(x, y, z) = x^5 y^2 z^3 + y x^y - sin(y z^3)`` is defined, then compute the derivative of ``f(x, y)`` with respect to ``x``, the derivative of ``f(x, y)`` with respect to ``y``, and the derivative of ``f(x, y)`` with respect to ``z``.

- ``\frac{\partial f}{\partial x} = 5x^4 y^2 z^3 + y x^{y -1}``.

- ``\frac{\partial f}{\partial y} = 2 x^5 y z^3 + x^y ln(x) - z^3 cos(y z^3)``.

- ``\frac{\partial f}{\partial z} = 3z^2 x^5 y^2 - 3z^2 y cos(y z^3)``.

*Reminder:* ``(a^u)\prime = u\prime a^u ln(a)``.

## Higher Order Partial Derivatives

For a two-variable function ``f(x, y)``, higher order derivatives are as follows:

- ``\frac{\partial^2 f}{\partial x^2} = \frac{\partial}{\partial x} (\frac{\partial f}{\partial x})`` or ``{f\prime}_{xx}``.

- ``\frac{\partial^2 f}{\partial y^2} = \frac{\partial}{\partial y} (\frac{\partial f}{\partial y})`` or ``{f\prime}_{yy}``.

- ``\frac{\partial^2 f}{\partial x \partial y} = \frac{\partial}{\partial x} (\frac{\partial f}{\partial y})`` or ``{f\prime}_{yx}``.

- ``\frac{\partial^2 f}{\partial y \partial x} = \frac{\partial}{\partial y} (\frac{\partial f}{\partial x})`` or ``{f\prime}_{xy}``.

### Exercise

With the given function ``f(x, y) = ln(x^4 y^2) - y``, find the second partial derivative of ``f(x, y)`` both with respect to ``x``, the second partial derivative of ``f(x, y)`` both with respect to ``y``, the second partial derivative of ``f(x, y)`` first taken with respect to ``y`` and then with respect to ``x``, and the second partial derivative of ``f(x, y)`` with respect to ``x`` and ``y``.

- ``\frac{\partial^2 f}{\partial x^2} = \frac{\partial}{\partial x}(\frac{4x^3 y^2}{x^4 y^2}) = \frac{\partial}{\partial x}(\frac{4}{x}) = \frac{-4}{x^2}``.

- ``\frac{\partial^2 f}{\partial y^2} = \frac{\partial}{\partial y}(\frac{2x^4 y}{x^4 y^2} - 1) = \frac{\partial}{\partial y}(\frac{2}{y} - 1) = \frac{\partial}{\partial y}(2y^{-1}) = -2y^{-2} = \frac{-2}{y^2}``.

- ``\frac{\partial^2 f}{\partial x \partial y} = \frac{\partial}{\partial x}(\frac{2y x^4}{x^4 y^2} - 1) = \frac{\partial}{\partial x}(\frac{2}{y} - 1) = 0``.

- ``\frac{\partial^2 f}{\partial y \partial x} = \frac{\partial}{\partial y}(\frac{4x^3 y^2}{x^4 y^2}) = \frac{\partial}{\partial y}(\frac{4}{x}) = 0``.

*Reminder:* ``(ln(u))\prime = \frac{u\prime}{u}``.

## The Chain Rule

There are a few states for the chain rule:

- The first state. Suppose the function ``f(x, y)`` is defined. The variables``x`` and ``y`` are on their own functions of other variables, such as ``t``. In this state:

``\frac{\partial f}{\partial t} = \frac{\partial f}{\partial x} \frac{\partial x}{\partial t}``.

### Example

If ``f(x, y) = x^3 y - y^2 x + 4x`` and ``x = sin(t)`` and ``y = 2e^t``, then find ``\frac{\partial f}{\partial t}``.

``\frac{\partial f}{\partial t} = (3x^2 y - y^2 + 4) cos(t) + 2(x^3 - 2yx) e^t``.

*Reminder:* ``(e^u)\prime = u\prime e^u``.

- The second state. If we have ``f(x, y, z)`` a three-variable function and ``x, y, z`` three functions of ``t``, then we have:

``\frac{\partial f}{\partial t} = \frac{\partial f}{\partial x} \frac{\partial x}{\partial t} + \frac{\partial f}{\partial y} \frac{\partial y}{\partial t} + \frac{\partial f}{\partial z} \frac{\partial z}{\partial t}``.

### Example

The three-variable function ``f(x, y, z) = x y^3 - x^2 z^3 + ln(x y)`` is given,  where ``x = t^2``, ``y = cos(4t)`` and ``z = \sqrt{t}``. Find the partial derivative of ``f`` with respect to ``t``.

``\frac{\partial f}{\partial t} = (y^3 - 2x z^3 + \frac{y}{x y}) (2t) + (3y^2 x + \frac{x}{x y})(-4sin(4t)) + (-3z^2 x^2)(\frac{1}{2 \sqrt{t}})``.

*Reminder:* ``(ln(u))\prime = \frac{u\prime}{u}``.

- The state of the third kind. If ``f(x, y)`` is a two-variable function, and ``x`` and ``y`` are two-variable functions of for example ``r`` and ``s``, then:

- ``\frac{\partial f}{\partial r} = \frac{\partial f}{\partial x} \frac{\partial x}{\partial r} + \frac{\partial f}{\partial y} \frac{\partial y}{\partial r}``.

- ``\frac{\partial f}{\partial s} = \frac{\partial f}{\partial x} \frac{\partial x}{\partial s} + \frac{\partial f}{\partial y} \frac{\partial y}{\partial s}``.

### Example

The partial derivative of ``f(x, y) = 3x^2 y - y^2 x + x y + y`` with respect to ``s``, where ``y = r + s`` and ``x = s^r``:

``\frac{\partial f}{\partial s} = (6x y - y^2 + y) (r s^{r - 1}) + (3x^2 - 2y x + x + 1)(1)``.

The partial derivative of the function ``f(x, y)`` with respect to ``r``:

``\frac{\partial f}{\partial r} = (6x y - y^2 + y) (s^r ln(s)) + (3x^2 - 2y x + x + 1)(1)``.

*Reminder:* ``\frac{d}{dx} a^x = \frac{d}{dx} e^{x ln(a)} = e^{x ln(a)} (\frac{d}{dx} x ln(a)) = e^{x ln(a)} ln(a) = a^x ln(a)``.

# The Aplications of Partial Derivatives

## Determining the Maximum and Minimum Values of Multivariable Functions

The steps for determining the extremum points of a twovariable function ``f(x, y)``:

1. Solve the system of equations that is formed with ``\frac{\partial f}{\partial x} = 0`` and ``\frac{\partial f}{\partial y} = 0``. Suppose that the solution of the system is equal to ``(x_0, y_0)``.

2. Compute the equation ``\Delta(x, y) = {f\prime}_{xx} {f\prime}{yy} - ({f\prime}{xy})^2``.

3. Compute these values: ``\Delta(x_0, y_0)`` and ``{f\prime}{xx}(x_0, y_0)``.

4. If ``\Delta(x_0, y_0) > 0`` and ``{f\prime}{xx}(x_0, y_0) < 0``, then the point ``(x_0, y_0)`` is a local maximum.

5. If ``\Delta(x_0, y_0) > 0`` and ``{f\prime}{xx}(x_0, y_0) > 0``, then the point ``(x_0, y_0)`` is a local minimum.

6. If ``\Delta(x_0, y_0) < 0``, then the point ``(x_0, y_0)`` is a saddle point.

7. If ``\Delta(x_0, y_0) = 0``, then this test does not succeed at determining the type of the point ``(x_0, y_0)``.

### Example

Find the local extremum points of the function ``f(x, y) = 2x y - 5y^2 + 4x - 2x^2 + 4y - 4``.

``\frac{\partial d}{\partial x} = 0`` and ``\frac{\partial f}{\partial y} = 0`` yields: ``2y + 4 - 4x = 0`` and ``2x - 10y + 4 = 0``. Next, we have: ``2y - 4x = -4`` and ``2x - 10y = -4``. Multiplying the equation ``2x - 10y = -4`` by ``2`` results in ``2y - 4x = -4`` and ``4x - 20y = -8``. Then, ``-18y = -12``. Finally, ``y = \frac{-12}{-18} = \frac{2}{3}``. Subsequently, we solve for ``x`` by substituting the numerical value of ``y`` in the equation ``2(\frac{2}{3}) - 4x = -4``, which siplifies to the equation ``-4x = -4 - \frac{4}{3} = \frac{-16}{3}``. Then, we have ``x = \frac{16}{12} = \frac{4}{3}``. This gives the extremum point ``(x_0, y_0) = (\frac{4}{3}, \frac{2}{3})``. Now, we have to determine the type of ``(\frac{4}{3}, \frac{2}{3})``.

``{f\prime}_{xx}(\frac{4}{3}, \frac{2}{3}) = -4`` and ``{f\prime}_{yy}(\frac{4}{3}, \frac{2}{3}) = -10`` and ``{f\prime}_{xy}(\frac{4}{3}, \frac{2}{3}) = 2``.

``\Delta(\frac{4}{3}, \frac{2}{3}) = (-4) (-10) - 2^2 = 40 - 4 = 36``.

Having computed the values of ``{f\prime}_{xx}(\frac{4}{3}, \frac{2}{3})`` and ``\Delta(\frac{4}{3}, \frac{2}{3})`` we can examine the type of the point ``(\frac{4}{3}, \frac{2}{3})`` next:

``\Delta(\frac{4}{3}, \frac{2}{3}) > 0`` and ``{f\prime}_{xx}(\frac{4}{3}, \frac{2}{3}) < 0``, therefore the point ``(\frac{4}{3}, \frac{2}{3})`` is a local maximum according to step four above.

### Exercise

Find the local extremum points of the function ``f(x, y) = x^2 - 2x y + \frac{1}{3} y^3 - 3y``.

``\frac{\partial f}{\partial x} = 2x - 2y = 0``,

``\frac{\partial f}{\partial y} = -2x + y^2 - 3 = 0``.

``2x - 2y = 0``,

``-2x + y^2 = 3``.

``y^2 - 2y = 3``.

``y^2 - 2y - 3 = 0``.

``\frac{-(-2) \pm \sqrt{4 + 12}}{2} = \frac{2 \pm 4}{2} = \frac{1 \pm 2}{1}``. So by solving an equation of order 2 in variable ``y``, the variable ``y`` has two distinguished roots: ``y_1 = 3`` and ``y_2 = -1``.

This is the intermediate step for how to find the values of ``x_1`` and ``x_2`` with the given values of ``y_1`` and ``y_2``.

``2x - 2y\_1 = 0``,
``2x - 2(3) = 0``,
``2x = 6``,
``x_1 = 3``.

``2x - 2y_2 = 0``,
``2x - 2(-1) = 0``,
``2x = -2``,
``x_2 = -1``.

The coordinates of the point ``(x_0, y_0)`` for the extremum examination is equal to ``(x_0, y_0) = (3, 3)``, and ``(x_1, y_1) = (-1, -1)``.

``{f\prime}_{xx} = 2``,
``{f\prime}_{yy} = 2y``,
``{f\prime}_{xy} = -2``.

``\Delta(x, y) = {f\prime}_{xx} - {f\prime}{yy} - ({f\prime}_{xy})^2 = (2) (2y) - (-2)^2 = 4y - 4``.

For each point ``(x_0, y_0)`` and ``(x_1, y_1)`` respectively we have: ``\Delta(x\_0, y\_0) = 4 (3) - 4 = 8`` and ``\Delta(x\_1, y\_1) = 4 (-1) - 4 = -8``.

``{f\prime}_{xx}(x_0, y_0) = 2``.

But, ``(x_0, y_0) = (3, 3)`` yields ``\Delta(3, 3) > 0`` and ``{f\prime}_{xx}(3, 3) > 3``. Therefore, ``(3, 3)`` is a local minimum point of the function ``f(x, y)``.

Examining the last extremum point, ``(x_1, y_1) = (-1, -1)`` yields ``\Delta(-1, -1) < 0`` and ``{f\prime}_{xx}(-1, -1) > 0``, which makes ``(-1, -1)`` a saddle point.

## The Directional Derivative of Multivariable Functions

The gradient vector of function ``f(x, y)`` at point ``(x_0, y_0)`` is a vector that is perpendicular to the surface of the function ``f(x, y)`` at the point ``(x_0, y_0)``.

The plot of the function ``f(x, y)``.

The gradient of the function ``f(x, y)`` at point ``a`` is found as follows:

The gradient vector ``\overrightarrow{\nabla f}`` or ``grad \ f = \frac{\partial f}{\partial x} \overrightarrow{\i} + \frac{\partial f}{\partial y} \overrightarrow{j} |_a`` evaluated at point ``a``.

The gradient of the function ``w = f(x, y, z)`` at point ``a`` is equal to ``\frac{\partial f}{\partial x} \overrightarrow{\i} + \frac{\partial f}{\partial y} \overrightarrow{\j} + \frac{\partial f}{\partial z} \overrightarrow{k} |_a``.

Here, ``\overrightarrow{\i}``, ``\overrightarrow{\j}`` and ``\overrightarrow{\k}`` are unit vectors, which represent the unit basis vectors in the three-dimensional space. These are the spatial triples. Every two of them are linearly independent. In other words, none of them can be represented as a linear combination of the other two.

- ``\overrightarrow{i} = (1, 0, 0)``

- ``\overrightarrow{j} = (0, 1, 0)``

- ``\overrightarrow{k} = (0, 0, 1)``

``|\overrightarrow{\imath}| + |\overrightarrow{j}| + |\overrightarrow{k}| = 1``.

``(3, -2, 1) = 3\overrightarrow{imath} - 2\overrightarrow{j} + \overrightarrow{k}``.

### Example

Find the gradient of the function ``f(x, y) = -x^4 y^3 + x^2 y - x`` at point ``(2, 3)``.

``\overrightarrow{\nable f} \rvert{(2, 3)} = (-4x^3 y^3 + 2x y - 1) \overrightarrow{i} + (-3x^4 y^2 + x^2) \overrightarrow{j}``,

``\overrightarrow{\nable f} \rvert{(2, 3)} = ((-4) (2^3) (3^3) + 2(2) (3) - 1) \overrightarrow{i} + ((-3) (2^4) (3^2) + 2^2) \overrightarrow{j}``,

``\overrightarrow{\nable f} \rvert{(2, 3)} = ((-4) (8) (27) + 12 - 1) \overrightarrow{i} + ((-3) (16) (9) + 4) \overrightarrow{j}``,

``\overrightarrow{\nable f} \rvert{(2, 3)} = -853 \overrightarrow{i} - 428 \overrightarrow{j} = (-853, -428)``.


Remember how we compute the slope ``m_L`` of the line ``L`` in the ``x-y`` plane at point ``x_0``:

``f\prime (x_0) = m_L``.

``f\prime (x_0) = lim_{x \to x_0} \frac{f(x) - f(x\_0)}{x - x_0}``.

Now, the directional derivative of the function ``f(x, y)`` at point ``a`` in the direction of vector ``\overrightarrow{u}``:

``Df_{\overrightarrow{u}} = \overrightarrow{\nabla f} \cdot e_{\overrightarrow{u}}``,

where ``cdot`` denotes the inner product, and ``e_{\overrightarrow{u}}`` denotes the unit vector of ``\overrightarrow{u}``.

In order to compute the unit vector ``e_{\overrightarrow{u}}``, divide the vector ``\overrightarrow{u}`` by its magnitude ``|\overrightarrow{u}|`` by element:

``e_{\overrightarrow{u}} = \frac{\overrightarrow{u}}{|\overrightarrow{u}|}``.

The magnitude of a vector such as ``a = (a_1, a_2, a_3)`` equals ``|\overrightarrow{a}| = \sqrt{{a_1}^2 + {a_2}^2 + {a_3}^2}`` in the three-dimensional case. However, in the two-dimensional case where ``a = (a_1, a_2)`` is a tuple, the length of ``a`` is equal to ``|\overrightarrow{a}| = \sqrt{{a_1}^2 + {a_2}^2}``.

The inner product of a pair of vectors such as ``\overrightarrow{a} = (a_1, a_2)`` and ``\overrightarrow{b} = (b_1, b_2)`` is computed either as ``\overrightarrow{a} \cdot \overrightarrow{b} = a_1 b_1 + a_2 b_2`` or ``\overrightarrow{a} \cdot \overrightarrow{b} = |\overrightarrow{a}| |\overrightarrow{b}| cos(\alpha)``, where ``\alpha`` denotes the angle between the two vectors ``\overrightarrow{a}`` and ``\overrightarrow{b}``.

The three-dimensional inner product of vectors ``\overrightarrow{a} = (a_1, a_2, a_3)`` and ``\overrightarrow{b} = (b_1, b_2, b_3)`` is eqaul to:

``\overrightarrow{a} \cdot \overrightarrow{b} = a_1 b_1 + a_2 b_2 + a_3 b_3``.

### Example

For example, the coordinates of vector ``overrightarrow{a}`` equals its head minus its tail as an arrow, which is equal to ``(6, 4) - (2, 1) = (4, 3)``.
Also, the magnitude of ``\overrightarrow{a}`` equals ``\overrightarrow{a} = \sqrt{4^2 + 3^2} = \sqrt{25} = 5``.

# Dual Integrals

# The Applications of Dual Integrals

# Reference

- Dr. M.A. Kerayeh Chyan, General mathematics 2, 2022.