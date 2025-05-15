```@meta
Description = "News Report"
```

# Multivariable Functions

In General Mathematics 1, we were introduced to one-variable functions ``y = f(x)``, that had only one independent variable as input, ``x``. But in reality most of the times, we are faced with functions that have more than one independent variable. These functions are called multivariable functions.

``y = f(x)`` a one-variable.

input ``to`` output \equiv ``x \to y``.

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

The domain of the two-variable function ``f(x, y)`` is either a point in the ``x-y`` plane, or part, or the entire coordinate system ``x-y in \mathbb{R}^2 ``.

### Example

Find the domain of the follwoing functions and then plot it as a shape.

*A.* ``f(x, y) = 2x^3 y + x^2 y^2 - y + 5``
``D_f = \{ (x, y) | x \in \mathbb{R}, y \in \mathbb{R} \} = \mathbb{R}^2``.

*B.* ``f(x, y) = \frac{1}{x - y}``

``D_f = \{ (x, y) | x - y \neq 0 \} = \{ (x, y) | x \neq y \}``.

The whole plane, with the line ``y = x`` removed.

*C.* ``f(x, y) = \sqrt{x - y}``

``D_f = \{ (x, y) | x - y \geq 0 \} = \{ (x, y) | x \geq y \}``.

On and under the line `` y = x``.

*D.* ``f(x, y) = \frac{\sqrt{y - 3}}{\sqrt{5 - x}}``

``D_f = \{ (x, y) | y - 3 \geq 0, 5 - x > 0 \} = \{ (x, y) | y \geq 3, x < 5 \}``.

*E.* ``f(x, y) = \frac{\sqrt{y + 1}}{\sqrt[n]{2 - |x|}}``

``D_f = \{ (x, y) | y + 1 \geq 0, 2 - |x| > 0 \} = \{ (x, y) | y \geq -1, -2 < x < 2 \}``.

The shape of two-variable functions are going to be three-dimensional plots, which are also called surfaces.

``z = f(x, y)``.

The triple ``x(, y, z)``.

Since drawing three-dimensional shapes is time consuming, we just make a few examples of surfaces.

And inducing in this way, the domain of the three-variable function ``w = f(x, y, z)`` is three-dimensional, and its plot is four-dimensional.

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

## Higher Order Derivatives

For a two-variable function ``f(x, y)``, higher order derivatives are as follows:

- ``\frac{\partial^2 f}{\partial x^2} = \frac{\partial}{\partial x} (\frac{\partial f}{\partial x})`` or ``{f\prime}_{xx}``.

- ``\frac{\partial^2 f}{\partial y^2} = \frac{\partial}{\partial y} (\frac{\partial f}{\partial y})`` or ``{f\prime}_{yy}``.

- ``\frac{\partial^2 f}{\partial x \partial y} = \frac{\partial}{\partial x} (\frac{\partial f}{\partial y})`` or ``{f\prime}_{yx}``.

- ``\frac{\partial^2 f}{\partial y \partial x} = \frac{\partial}{\partial y} (\frac{\partial f}{\partial x})`` or ``{f\prime}_{xy}``.

### Example

With the given function ``f(x, y) = ln(x^4 y^2) - y``, find ``\frac{\partial^2 f}{\partial x^2}``, ``\frac{\partial^2 f}{\partial y^2}``, ``\frac{\partial^2 f}{\partial x \partial y}`` and ``\frac{\partial^2 f}{\partial y \partial x}``.

- ``\frac{\partial^2 f}{\partial x^2} = \frac{\partial}{\partial x}(\frac{4x^3 y^2}{x^4 y^2}) = \frac{\partial}{\partial x}(\frac{4}{x}) = \frac{-4}{x^2}``.

- ``\frac{\partial^2 f}{\partial y^2} = \frac{\partial}{\partial y}(\frac{2x^4 y}{x^4 y^2} - 1) = \frac{\partial}{\partial y}(\frac{2}{y} - 1) = \frac{\partial}{\partial y}(2y^{-1}) = -2y^{-2} = \frac{-2}{y^2}``.

- ``\frac{\partial^2 f}{\partial x \partial y} = \frac{\partial}{\partial x}(\frac{2y x^4}{x^4 y^2} - 1) = \frac{\partial}{\partial x}(\frac{2}{y} - 1) = 0``.

- ``\frac{\partial^2 f}{\partial y \partial x} = \frac{\partial}{\partial y} = \frac{\partial}{\partial y}(\frac{4x^3 y^2}{x^4 y^2}) = \frac{\partial}{\partial y}(\frac{4}{x}) = 0``.

*Reminder:* ``(ln(u))\prime = \frac{u\prime}{u}``.

# The Aplications of Partial Derivatives

# Dual Integrals

# The Applications of Dual Integrals

# Reference

- Dr. M.A. Kerayeh Chyan, General mathematics 2, 2022.