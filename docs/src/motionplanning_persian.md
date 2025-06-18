```@meta
Description = "Nonholonomic motion planning: steering using sinusoids."
```


# Ordinary Differential Equations

```@raw html
<div dir = "rtl">
<h1>

معادله‌ی دیفرانسیل معمولی

</h1>
<p>

معادلاتی به شکل زیر: 

</p>
</div>
```

``F(x, y, y^{\prime}, y^{\prime \prime}, ..., y^{(n)})``

```@raw html
<div dir = "rtl">
<p>

یعنی معادلاتی که در آن‌ها تابع مجهول وای: 

</p>
</div>
```

``y = f(x)``

```@raw html
<div dir = "rtl">
<p>

به همراه یک یا چند مشتق مراتب مختلف آن و همچنین به احتمال متغیر مستقل ایکس وجود دارد، معادلات دیفرانسیل معمولی گفته می‌شود.

</p>
<h3>

چند مثال:

</h3>
</div>
```

- ``y^{\prime \prime} - 3 y^{\prime} + x y = y^2``

- ``y^{\prime} + y = 0``

- ``4y^{(5)} - y + x = 0``

```@raw html
<div dir = "rtl">
<p>

اما مثال زیر یک معادله‌ی دیفرانسیل نیست:

</p>
</div>
```

``2y - y^2 = 0``

```@raw html
<div dir = "rtl">
<p>

حل کردن یک معادله‌ی دیفرانسیل یعنی پیدا کردن تابع مجهول وای.

</p>
<h3>

مرتبه‌ی معادله‌ی دیفرانسیل

</h3>
<p>

بالاترین مرتبه‌ی مشتق ظاهر شده در معادله‌ی دیفرانسیل را مرتبه‌ی معادله‌ی دیفرانسیل می‌گویند.

</p>
<h3>

حل چند مثال ساده

</h3>
</div>
```

- ``y^{\prime} = 3``,

``y = 3x + c``.

- ``y^{\prime} - y = 0``,

``y^{\prime} = y``,

``y = ce^x``.

- ``y^{\prime} = e^x``,

``y = e^x + c``.

- ``y^{\prime} = 4e^x``,

``y = 4e^x``.

```@raw html
<div dir = "rtl">
<h3>

یادآوری ریاضی عمومی:

</h3>
</div>
```

``(e^u)^{\prime} = u^{\prime} e^u``.

``(e^x)^{\prime} = 1 e^x = e^x``,

``(kf)^{\prime} = kf^{\prime}``.

```@raw html
<div dir = "rtl">
<p>

چون تنوع معادلات دیفرانسیل زیاد است، آن‌ها را در چند نوع طبقه‌بندی می‌کنند و برای هر کدام روش حل ارایه می‌شود. انواع معادلات دیفرانسیل معمولی مرتبه‌ی اول: جداشدنی، کامل، همگن، خطی با ضرایب ثابت، برنولی و ریکاتی. مجهول ما در معادله، وای برابر با تابعی از ایکس می‌باشد.

</p>
<h2>

معادله‌ی دیفرانسیل جداشدنی (تفکیک پذیر)

</h2>
<p>

اگر معادله‌ی دیفرانسیل را بتوان به شکل زیر نوشت:

</p>
</div>
```

``f(y) \ dy = f(x) \ dx``

```@raw html
<div dir = "rtl">
<p>

اف ایکس تابعی به طور تمام بر حسب ایکس است و اف وای تابعی به طور تمام بر حسب وای است. می‌گوییم این معادله جدا شده است و برای حل کردن آن از دو طرف انتگرال می‌گیریم.

</p>
<h3>

مثال

</h3>
</div>
```

``y^{\prime} = \frac{2x}{3y^2} \longrightarrow \frac{dy}{dx} = \frac{2x}{3y^2} \longrightarrow 3y^2 \ dy = 2x \ dx``,

``\int 3y^2 \ dy = \int 2x \ dx \longrightarrow y^3 = x^2 + c \longrightarrow y = \sqrt[3]{x^2 + c}``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
</div>
```

``y^{\prime} = e^{x + y} \longrightarrow \frac{dy}{dx} = e^x \ e^y \longrightarrow \frac{dy}{e^y} = e^x \ dx``,

``e^{-y} \ dy = e^x \ dx \longrightarrow \int e^{-y} \ dy = \int e^x \ dx \longrightarrow -e^{-y} = e^x + c``,

``e^{-y} = c - e^x \longrightarrow ln(e^{-y}) = ln(c - e^x) \longrightarrow -y = ln(c - e^x)``,

``y = -ln(c - e^x)``.

```@raw html
<div dir = "rtl">
<h3>

یادآوری درباره‌ی لگاریتم طبیعی

</h3>
</div>
```

``ln(x) = log_e^x``,

``ln(7) = log_e^7 = 1.94591014906 \longrightarrow e^{1.94591014906} = 7``,

``log_a^b = log_a^b``,

``a^{log_a^b} = b``,

``ln(e^{-y}) = log_e^{e^{-y}}``.

```@raw html
<div dir = "rtl">
<p>

خاصیت لگاریتم طبیعی

</p>
</div>
```

``log_a^{b^n} = n \ log_a^b``,

``log_e^{e^{-y}} = -y \ log_e^e = -y``.

```@raw html
<div dir = "rtl">
<p>

روش تغییر متغیر برای حل کردن انتگرال تابع نمایی

</p>
</div>
```

``\int e^{-y}``

``u = -y \longrightarrow du = -dy \longrightarrow -\int e^u \ du = -e^u = -e^{-y}``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل جداشدنی زیر را حل کنید.

</p>
</div>
```

``sec^2(x) \ tan(y) \ dx + sec^2(y) \ tan(x) \ dy = 0``

``sec(x) = \frac{1}{cos(x)}``

``sec^2(x) \ tan(y) \ dx = -sec^2(y) \ tan(x) \ dy``

``\frac{sec^2(x) dx}{tan(x)} = \frac{-sec^2(y) dy}{tan(y)}``

``\int \frac{sec^2(x)}{tan(x)} dx = -\int \frac{sec^2(y)}{tan(y)} dy \longrightarrow ln|tan(x)| = -ln|tan(y)| + c``

``\int \frac{u^{\prime}}{u} du = ln|u| + c``

``(tan(x))^{\prime} = sec(x)``

``(tan(u))^{\prime} = u^{\prime} (1 + tan^2(u)) \longrightarrow (tan(x))^{\prime} = 1 + tan^2(x)``

``1 + tan^2(x) = 1 + \frac{sin^2(x)}{cos^2(x)} = \frac{cos^2(x) + sin^2(x)}{cos^2(x)} = \frac{1}{cos^2(x)} = sec^2(x)``

``ln|tan(x)| + ln|tan(y)| = c \longrightarrow ln|tan(y)| = c - ln|tan(x)|``

``ln|tan(x) \ tan(y)| = c \longrightarrow e^{ln|tan(x) \ tan(y)|} = e^c``

``tan(x) \ tan(y) = e^c \longrightarrow tan(y) = \frac{e^c}{tan(x)} \longrightarrow y = tan^{-1} (\frac{e^c}{tan(x)})``.

```@raw html
<div dir = "rtl">
<h2>

معادلات دیفرانسیل کامل

</h2>
<p>

معادلاتی هستند به شکل کلی زیر:

</p>
</div>
```

``M(x, y) \ dx + N(x, y) \ dy = 0``

```@raw html
<div dir = "rtl">
<p>

به شرطی که:

</p>
</div>
```

``\frac{\partial M}{\partial y} = \frac{\partial N}{\partial x}``.

```@raw html
<div dir = "rtl">
<p>

برای حل کردن این دسته از معادلات فرض می‌کنیم که اف ایکس و وای جواب معادله باشد و قرار می‌دهیم:

</p>
</div>
```

``f(x, y) = \int M(x, y) \ dx + h(y)``

```@raw html
<div dir = "rtl">
<p>

که در اینجا ایچ وای تابعی به طور تمام بر حسب وای است. در ادامه، مقدار مشتق جزیی تابع اف نسبت به متغیر وای را به دست می‌آوریم و قرار می‌دهیم:

</p>
</div>
```

``N(x, y) = \frac{\partial f(x, y)}{\partial y}``

```@raw html
<div dir = "rtl">
<p>

از این راه، تابع ایچ وای را به دست می‌آوریم و در آخر تابع اف ایکس و وای را به طور تمام به دست می‌آوریم.

</p>
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل کامل زیر را حل کنید.

</p>
</div>
```

``(x + y + 1) dx + (x - y^2 + 3) dy = 0``

``\left\{ \begin{array}{l} M(x, y) = x + y + 1 &\\ N(x, y) = x - y^2 + 3 \end{array} \right.``

``\left\{ \begin{array}{l} \frac{\partial M(x, y)}{\partial y} = 1 &\\ \frac{\partial N(x, y)}{\partial x} = 1 \end{array} \right.``

``f(x, y) = \int (x + y + 1) dx + h(y) = \frac{x^2}{2} + y x + x + h(y)``

``\frac{\partial f(x, y)}{\partial y} = x + h^{\prime}(y)``

``x + h^{\prime}(y) = x - y^2 + 3 \longrightarrow h^{\prime}(y) = x - y^2 + 3 - x``

``h(y) = \int (-y^2 + 3) dy = \frac{-y^3}{3} + 3y``

``f(x, y) = \frac{x^2}{2} + yx + x - \frac{y^3}{3} + 3y``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل کامل زیر را حل کنید.

</p>
</div>
```

``(2x^2 + 2xy^2 + 4y) dx + (2x^2y + 4x + 5y^4) dy = 0``

``\left\{ \begin{array}{l} M(x, y) = 2x^2 + 2xy^2 + 4y &\\ N(x, y) = 2x^2y + 4x + 5y^4 \end{array} \right.``

``\left\{ \begin{array}{l} \frac{\partial M(x, y)}{\partial y} = 4xy + 4 &\\ \frac{\partial N(x, y)}{\partial x} = 4xy + 4 \end{array} \right.``

``f(x, y) = \int (2x^2 + 2xy^2 + 4y) dx + h(y)``

``f(x, y) = \frac{2}{3} x^3 + xy^2 + 4yx + c + h(y)``

``N(x, y) = \frac{\partial f}{\partial y} = \frac{\partial}{\partial y} (\frac{2}{3} x^3 + xy^2 + 4yx + c + h(y))``

``N(x, y) = 2xy + 4x + h^{\prime}(y) = 2x^2 y + 4x + 5y^4``

``h^{\prime}(y) = 2x^2 y + 4x + 5y^4 - 4x - 2xy = 2x^2 y + 5y^4 - 2xy``

``h(y) = \int h^{\prime}(y) dy = \int (2x^2y + 5y^4 - 2xy) dy = x^2 y^2 + y^5 - xy^2 + c``

``f(x, y) = \frac{2}{3} x^3 + xy^2 + 4yx + x^2y^2 + y^5 - xy^2 + c``

``f(x, y) = \frac{2}{3}x^3 + 4yx + x^2 y^2 + y^5 + c``.

```@raw html
<div dir = "rtl">
<h3>

تعریف تابع همگن

</h3>
<p>

تابع اف ایکس و وای را همگن ار درجه‌ی ان (ان عضوی از اعداد صحیح) می‌گویند، هرگاه عدد غیر صفری مانند تی وجود داشته باشد، به طوری که:

</p>
</div>
```

``f(tx, ty) = t^n f(x, y)``,

``n \in \mathbb{Z}``,

``t \neq 0``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

تابع اف ایکس و وای که با ضابطه‌ی زیر تعریف شده است یک تابع همگن از درجه‌ی چند است؟

</p>
</div>
```

``f(x, y) = x^4 - x^3 y``

``f(tx, ty) = (tx)^4 - (tx)^3 (ty) = t^4 x^4 - t^3 x^3 t y = t^4 x^4 - t^4 x^3 y = t^4 (x^4 - x^3 y) = t^4 f(x, y)``

``n = 4``

```@raw html
<div dir = "rtl">
<p>

پس تابع اف ایکس و وای یک تابع همگن از درجه‌ی چهار است.

</p>
<h2>

معادلات دیفرانسیل مرتبه‌ی اول همگن

</h2>
<p>

معادلاتی به فرم زیر هستند:

</p>
</div>
```

``M(x, y) dx + N(x, y) dy = 0``

```@raw html
<div dir = "rtl">
<p>

به طوری که تابع‌های ام و ان همگن هستند.

</p>
<p>

روش حل: با تغییر متغیر زیر، معادله را به یک معادله‌ی جداشدنی تبدیل می‌کنیم و سپس آن را حل می‌کنیم.

</p>
</div>
```

``u = \frac{y}{x}``

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل همگن زیر را حل کنید.

</p>
</div>
```

``y^{\prime} = 1 + \frac{y}{x}``

``y^{\prime} = \frac{x + y}{x}``

```@raw html
<div dir = "rtl">
<p>

واضح است که ام و ان تابع‌هایی همگن از درجه‌ی یک هستند. پس از روش تغییر متغیر استفاده می‌کنیم.

</p>
</div>
```

``\left\{ \begin{array}{l} M(x, y) dx = N(x, y) dy &\\ (x + y) dx = (x) dy \end{array} \right.``

``y = ux \longrightarrow dy = x \ du + u \ dx``

``M(tx, ty) = tx + ty = t(x + y) = t^1 M(x, y)``

``(x + ux) dx - x(x \ du + u \ dx) = 0``

``x \ dx + u x \ dx - x^2 \ du - x u \ dx = 0``

``x \ dx = x^2 \ du \longrightarrow \frac{1}{x} dx = du``

```@raw html
<div dir = "rtl">
<p>

معادله بر حسب متغیرهای ایکس و وای تفکیک شد. حالا از دو طرف معادله انتگرال می‌گیریم تا به تابع مجهول وای بر حسب متغیر ایکس برسیم.

</p>
</div>
```

``\int \frac{1}{x} dx = \int du``,

``ln(x) = u + c \longrightarrow ln(x) = \frac{y}{x} + c \longrightarrow ln(x) = \frac{y + cx}{x}``,

``y = x \ ln(x) - cx``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل همگن زیر را حل کنید.

</p>
</div>
```

``(x e^{\frac{y}{x}} + y) dx - x \ dy = 0``.

``y = ux \longrightarrow dy = x \ du + u \ dx \longrightarrow (x e^u + ux) dx - x (x \ du + u \ dx) = 0``

``x e^u \ dx + ux \ dx - x^2 \ du - xu \ dx = 0``

``x e^u \ dx = x^2 \ du \longrightarrow \frac{1}{x} dx = e^{-u} du``

``\int \frac{1}{x} dx = \int e^{-u} du \longrightarrow ln(x) = -e^{-u} + c``

``ln(x) = -e^{-\frac{y}{x}} + c``

``ln(c - ln(x)) = ln(e^{-\frac{y}{x}}) \longrightarrow ln(c - ln(x)) = -ln(e^{\frac{y}{x}}) \longrightarrow -ln(c - ln(x)) = \frac{y}{x}``

``y = -x \ ln(c - ln(x))``.

```@raw html
<div dir = "rtl">
<p>

یادآوری

</p>
</div>
```

``log_b^a = log_b^a``,

``b^{log_b^a} = a``,

``log_e^{e^y} = y \ log_e^e = y``.

```@raw html
<div dir = "rtl">
<h2>

معادله‌ی دیفرانسیل خطی مرتبه‌ی اول

</h2>
<p>

حل کردن معادله‌ی دیفرانسیل خطی مرتبه‌ی اول به فرم زیر

</p>
</div>
```

``y^{\prime} + p(x) y = q(x)``

```@raw html
<div dir = "rtl">
<p>

که تابع پی و تابع کیو، تابع‌هایی پیوسته و بر حسب ایکس هستند. جواب این معادله به صورت زیر است:

</p>
</div>
```

``y = \frac{1}{e^{\int p(x)dx}}(\int e^{\int p(x)dx} q(x)dx + c)``

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی خطی مرتبه‌ی اول زیر را حل کنید.

</p>
</div>
```

``y^{\prime} + y = e^x``

``\left\{ \begin{array}{l} p(x) = 1 &\\ q(x) = e^x \end{array} \right.``

``\int p(x) dx = \int dx = x + c``

``y = \frac{1}{e^{x + c}} (\int e^{x + c} e^x dx + c)``

``y = \frac{1}{e^{x + c}} (\int e^{2x + c} dx + c) = \frac{1}{e^{x + c}} (\frac{e^{2x + c}}{2} + c)``

``y = \frac{e^x}{2} + ce^{-x - c}``

``y = \frac{1}{e^x} (\frac{1}{2} e^{2x} + c)``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
</div>
```

``y^{\prime} + \frac{2x}{1 + x^2} y = \frac{cot(x)}{1 + x^2}``

``\left\{ \begin{array}{l} p(x) = \frac{2x}{1 + x^2} &\\ q(x) = \frac{cot(x)}{1 + x^2} \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

فرم کلی معادلات خطی:

</p>
</div>
```

``y^{\prime} + p(x) y = q(x)``

``e^{\int p(x) dx} = e^{\int \frac{2x}{1 + x^2} dx} = e^{\int \frac{du}{u}} = e^{ln|u|} = u``.

``e^{\int p(x) dx} = u = 1 + x^2``

``y = \frac{1}{1 + x^2} (\int q(x) e^{\int p(x) dx} dx + c)``

``y = \frac{1}{1 + x^2} (\int \frac{cot(x)}{1 + x^2} (1 + x^2) dx + c)``

``y = \frac{1}{1 + x^2} (\int cot(x) dx + c) = \frac{1}{1 + x^2} (ln(|sin(x)|) + c)``

```@raw html
<div dir = "rtl">
<p>

یادآوری

</p>
</div>
```

``\int cot(x) dx = \int \frac{cos(x)}{sin(x)} dx = ln|sin(x)| + c``.

```@raw html
<div dir = "rtl">
<h2>

معادلات برنولی

</h2>
<p>

معادلاتی هستند به فرم

</p>
</div>
```

``y^{\prime} + p(x) y = q(x) y^n``.

```@raw html
<div dir = "rtl">
<p>

در حالتی که ان برابر با صفر باشد و در حالتی که ان برابر با یک باشد، معادلات برنولی همان معادلات خطی مرتبه‌ی اول هستند.

</p>
</div>
```

``n = 0, n = 1``

```@raw html
<div dir = "rtl">
<p>

بنابراین، این معادلات را در حالتی که ان نابرابر با صفر ونابرابر با یک است، حل می‌کنیم.

</p>
</div>
```

``n \neq 0, n \neq 1``

```@raw html
<div dir = "rtl">
<p>

روش حل: برای حل معادلات برنولی، ابتدا طرفین معادله را بر وای به توان ان تقسیم می‌کنیم.

</p>
</div>
```

``/ y^n``

```@raw html
<div dir = "rtl">
<p>

و سپس با تغییر متغیر زیر، معادله را به یک معادله‌ی خطی مرتبه‌ی اول بر حسب ایکس و یو تبدیل می‌کنیم و بعد آن راحل می‌کنیم.

</p>
<h3>

مثال

</h3>
<p>

معادله‌ی برنولی زیر را حل کنید.

</p>
</div>
```

``y^{\prime} + \frac{1}{x} y = y^2``

```@raw html
<div dir = "rtl">
<p>

حل: تقسیم دو طرف معادله بر وای به توان ان:

</p>
</div>
```

``n = 2 \longrightarrow y^n = y^2``

``\frac{y^{\prime}}{y^2} + \frac{1}{xy} = 1``

```@raw html
<div dir = "rtl">
<p>

تغییر متغیر

</p>
</div>
```

``\left\{ \begin{array}{l} u = \frac{1}{y} = y^{-1} &\\ du = d(y^{-1}) = -y^{-2} dy \end{array} \right.``

``y^{\prime} u^2 + \frac{u}{x} = 1``

``\left\{ \begin{array}{l} -du = dy \ y^{-2} &\\ u^{\prime} = - y^{\prime} y^{-2} \end{array} \right.``

``-u^{\prime} + \frac{u}{x} = 1``

``u^{\prime} - \frac{u}{x} = -1 \longrightarrow u^{\prime} - \frac{u}{x} + 1 = 0``

``\left\{ \begin{array}{l} p(x) = \frac{-1}{x} &\\ q(x) = -1 \end{array} \right.``

``e^{\int p(x) dx} = e^{\int -\frac{1}{x} dx} = e^{-ln|x|} = \frac{1}{x}``

``u = \frac{1}{e^{\int p(x) dx}} (\int q(x) e^{\int p(x) dx} dx + c)``

``u = x (\int (-1) \frac{1}{x} dx + c) = x(\int -\frac{1}{x} dx + c)``

``u = x (-ln|x| + c)``

```@raw html
<div dir = "rtl">
<p>

معادله را بر حسب متغیر یو بازنویسی می‌کنیم.

</p>
</div>
```

``\frac{y^{\prime}}{y^2} + \frac{1}{x} \frac{1}{y} = 1``

``u^{\prime} - \frac{1}{x} u = -1``

```@raw html
<div dir = "rtl">
<p>

معادله خطی مرتبه‌ی اول بر حسب متغیرهای یو و ایکس است.

</p>
</div>
```

``u = \frac{1}{y}``

``y^{-1} = u = x(-ln|x| + c) \longrightarrow y = \frac{1}{x(-ln|x| + c)}``.

```@raw html
<div dir = "rtl">
<p>

یادآوری: به طور کلی متغیر وای عبارتیست بر حسب متغیر ایکس.

</p>
</div>
```

``(y^n)^{\prime} = n y^{\prime} y^{n - 1}``

```@raw html
<div dir = "rtl">
<p>

در حالت خاص

</p>
</div>
```

``y = x \longrightarrow (x^n)^{\prime} = n x^{\prime} x^{n - 1}``.