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

``(tan(x))^{\prime} = sec^2(x)``

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

``f(x, y) = \int (x + y + 1) dx + h(y) = \frac{x^2}{2} + y x + x + c + h(y)``

``\frac{\partial f(x, y)}{\partial y} = x + h^{\prime}(y)``

``x + h^{\prime}(y) = x - y^2 + 3 \longrightarrow h^{\prime}(y) = x - y^2 + 3 - x``

``h(y) = \int (-y^2 + 3) dy = \frac{-y^3}{3} + 3y``

``f(x, y) = \frac{x^2}{2} + yx + x - \frac{y^3}{3} + 3y + c``.

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

``f(x, y) = \frac{2}{3} x^3 + x^2y^2 + 4yx + c + h(y)``

``N(x, y) = \frac{\partial f}{\partial y} = \frac{\partial}{\partial y} (\frac{2}{3} x^3 + x^2y^2 + 4yx + c + h(y))``

``N(x, y) = 2x^2y + 4x + h^{\prime}(y) = 2x^2 y + 4x + 5y^4``

``h^{\prime}(y) = 2x^2 y + 4x + 5y^4 - 4x - 2x^2y = 5y^4``

``h(y) = \int h^{\prime}(y) dy = \int 5y^4 dy = y^5 + c``

``f(x, y) = \frac{2}{3} x^3 + x^2y^2 + 4yx + y^5 + c``.

```@raw html
<div dir = "rtl">
<h3>

تعریف تابع همگن

</h3>
<p>

تابع اف ایکس و وای را همگن از درجه‌ی ان (ان عضوی از اعداد صحیح) می‌گویند، هرگاه عدد غیر صفری مانند تی وجود داشته باشد، به طوری که:

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

``M(tx, ty) = tx + ty = t(x + y) = t^1 M(x, y)``

``\left\{ \begin{array}{l} M(x, y) dx = N(x, y) dy &\\ (x + y) dx = (x) dy \end{array} \right.``

``y = ux \longrightarrow dy = x \ du + u \ dx``

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
</div>
```

``u = \frac{1}{y^{n - 1}}``

```@raw html
<div dir = "rtl">
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

```@raw html
<div dir = "rtl">
<p>

معادله را بر حسب متغیر یو بازنویسی می‌کنیم.

</p>
</div>
```

``\frac{y^{\prime}}{y^2} + \frac{1}{x} \frac{1}{y} = 1``

``y^{\prime} u^2 + \frac{u}{x} = 1``

``\left\{ \begin{array}{l} -du = dy \ y^{-2} &\\ u^{\prime} = - y^{\prime} y^{-2} \end{array} \right.``

``-u^{\prime} + \frac{u}{x} = 1``

``u^{\prime} - \frac{u}{x} = -1 \longrightarrow u^{\prime} - \frac{u}{x} + 1 = 0``

```@raw html
<div dir = "rtl">
<p>

معادله خطی مرتبه‌ی اول بر حسب متغیرهای یو و ایکس است.

</p>
</div>
```

``\left\{ \begin{array}{l} p(x) = \frac{-1}{x} &\\ q(x) = -1 \end{array} \right.``

``e^{\int p(x) dx} = e^{\int -\frac{1}{x} dx} = e^{-ln|x|} = \frac{1}{x}``

``u = \frac{1}{e^{\int p(x) dx}} (\int q(x) e^{\int p(x) dx} dx + c)``

``u = x (\int (-1) \frac{1}{x} dx + c) = x(\int -\frac{1}{x} dx + c)``

``u = x (-ln|x| + c)``

``u = \frac{1}{y}``

``y^{-1} = u = x(-ln|x| + c) \longrightarrow y = \frac{1}{x(-ln|x| + c)}``.

```@raw html
<div dir = "rtl">
<h3>

یادآوری

</h3>
<p>

به طور کلی متغیر وای عبارتیست بر حسب متغیر ایکس.

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

```@raw html
<div dir = "rtl">
<h3>

تمرین‌های دوره‌ای

</h3>
<h4>

تمرین معادله‌ی جداشدنی

</h4>
</div>
```

- ``y^\prime = \frac{5x}{2y^2}``

``\frac{dy}{dx} = \frac{5x}{2y^2} \longrightarrow 5x \ dx = 2y^2 \ dy``

``\int 5x \ dx = \int 2y^2 \ dy \longrightarrow \frac{5x^2}{2} = \frac{2y^3}{3} + c``

``\frac{2y^3}{3} = \frac{5x^2}{2} + c \longrightarrow y^3 = \frac{3}{2} (\frac{5x^2}{2} - c)``

``y = \sqrt[3]{\frac{3}{2} (\frac{5x^2}{2} - c)}``.

- ``xy^\prime + y = y^2``

``x \frac{dy}{dx} + y = y^2 \longrightarrow \frac{x}{dx} + \frac{y}{dy} = \frac{y^2}{dy}``

``\frac{x}{dx} = \frac{y^2}{dy} - \frac{y}{dy} \longrightarrow \frac{x}{dx} = \frac{y^2 - y}{dy}``

``\frac{dx}{x} = \frac{dy}{y^2 - y} \longrightarrow \frac{dx}{x} = \frac{dy}{y (y - 1)}``

``\frac{dx}{x} = dy (\frac{A}{y} + \frac{B}{y - 1}) \longrightarrow \frac{dx}{x} = \frac{-dy}{y} + \frac{dy}{y - 1}``

``\frac{A (y - 1) + B y}{y (y - 1)} = \frac{1}{y (y - 1)}``

``Ay - A + By = 1``

``\left\{ \begin{array}{l} A + B = 0 &\\ -A = 1 \end{array} \right.``

``\left\{ \begin{array}{l} A = -1 &\\ B = 1 \end{array} \right.``

``\int \frac{dx}{x} = - \int \frac{dy}{y} + \int \frac{dy}{y - 1} \longrightarrow ln|x| = -ln|y| + ln|y - 1| + c``

``ln|x| = ln|\frac{y - 1}{y}| + c \longrightarrow e^{ln|x|} = e^{ln|\frac{y - 1}{y}| + c} \longrightarrow x = \frac{y - 1}{y} + c_1``

``x = 1 - \frac{1}{y} + c_1 \longrightarrow \frac{1}{y} = 1 - x + c_1``

``y = \frac{1}{1 - x + c_1}``.

```@raw html
<div dir = "rtl">
<h4>

تمرین معادله‌ی همگن

</h4>
</div>
```

- ``(x^2 + y^2) dx + 2xy \ dy = 0``

``u = \frac{y}{x} \longrightarrow y = ux \longrightarrow dy = u \ dx + x \ du``

``(x^2 + u^2 x^2) dx + 2x ux \ dy = 0``

``x^2 (u^2 + 1) dx + 2x^2 u \ dy = 0 \longrightarrow x^2 (u^2 + 1) dx + 2x^2 u (u \ dx + x \ du) = 0``

``(u^2 + 1) dx + 2u^2 \ dx + 2ux \ du = 0``

``dx(u^2 + 1 + 2u^2) + 2ux \ du = 0 \longrightarrow (3u^2 + 1) dx + 2ux \ du = 0``

``\frac{3u^2 + 1}{x} dx + 2u \ du = 0 \longrightarrow \frac{dx}{x} + \frac{2u}{3u^2 + 1} du = 0``

``\frac{dx}{x} = \frac{-2u}{3u^2 + 1} du \longrightarrow \int \frac{dx}{x} = \int \frac{-2u}{3u^2 + 1} du``

``ln|x| = \frac{-1}{3} \int \frac{2u}{u^2 + 1} du \longrightarrow ln|x| = \frac{-1}{3} ln|u^2 +1| + c``

``e^{ln|x|} = e^{\frac{-1}{3} ln|u^2 + 1| + c}``

``x = e^{ln|(u^2 + 1)^{\frac{-1}{3}}| + c} \longrightarrow x = \frac{1}{\sqrt[3]{u^2 + 1}} + c_1``

``\frac{1}{x} = \sqrt[3]{u^2 + 1} + c_1 \longrightarrow \frac{1}{x^3} = u^2 + 1 + c_1``

``u^2 = \frac{1}{x^3} - 1 - c_1 \longrightarrow u = \sqrt{\frac{1}{x^3} - 1 - c_1}``

``\frac{y}{x} = \sqrt{\frac{1}{x^3} - 1 - c_1}``

``y = x \sqrt{\frac{1}{x^3} - 1 - c_1}``.

- ``y^\prime = 2 + \frac{y}{x}``

``u = \frac{y}{x} \longrightarrow y = ux \longrightarrow dy = u \ dx + x \ du``

``\frac{dy}{dx} = u + x \frac{du}{dx} \longrightarrow y^\prime = u + x u^\prime``

``u + xu^\prime = 2 + u \longrightarrow x u^\prime = 2 \longrightarrow u^\prime = \frac{2}{x}``

``\frac{du}{dx} = \frac{2}{x} \longrightarrow du = \frac{2 dx}{x}``

``\int du = \int 2 \frac{dx}{x} \longrightarrow u = 2 ln|x| + c``

``\frac{y}{x} = ln(x^2) + c \longrightarrow y = x \ ln(x^2) + cx``.

```@raw html
<div dir = "rtl">
<h4>

تمرین معادله‌ی کامل

</h4>
</div>
```

- ``(x + y + 2) dx + (x - y^2 + 1) dy = 0``

``f(x, y) = \int (x + y + 2) dx + h(y) = \frac{x^2}{2} + xy + 2x + c + h(y)``

``\frac{\partial f}{\partial y} = N(x, y)``

``x + h^\prime (y) = x - y^2 + 1 \longrightarrow h^\prime (y) = \int h(y) dy = \int (1 - y^2) dy = y - \frac{y^3}{3} + c_1``

``f(x, y) = \frac{x^2}{2} + xy + 2x + y - \frac{y^3}{3} + c_2``.

- ``(2x^2 + 4y) dx + (4x - 3y^2) dy = 0``

``f(x, y) = \int M(x, y) dx + h(y) \longrightarrow f(x, y) = \int (2x^2 + 4y) dx + h(y) = \frac{2x^3}{3} + 4xy + h(y)``

``\frac{\partial f(x, y)}{\partial y} = N(x, y) \longrightarrow 4x + h^\prime (y) = 4x - 3y^2 \longrightarrow h^\prime (y) = -3y^2``

``h(y) = \int h^\prime (y) dy \longrightarrow h(y) = \int -3y^2 \ dy \longrightarrow h(y) = -3 \frac{y^3}{3} + c \longrightarrow h(y) = -y^3 + c``

``f(x, y) = \frac{2}{3} x^3 + 4xy - y^3 + c``.

- ``(2xe^y + e^x) dx + (x^2 + 1) e^y dy = 0``

``f(x, y) = \int M(x, y) dx + h(y) = \int (2xe^y + e^x) dx + h(y) = \frac{2x^2}{2} e^y + e^x + c + h(y)``

``\frac{\partial f(x, y)}{\partial y} = N(x, y) \longrightarrow x^2 e^y + h^\prime (y) = e^y (x^2 + 1)``

``h^\prime (y) = e^y (x^2 + 1) - x^2 e^y = e^y x^2 + e^y - e^y x^2 = e^y``

``h(y) = \int h^\prime (y) dy = \int e^y dy = e^y + c_1``

``f(x, y) = x^2 e^y + e^x + e^y + c_2``

```@raw html
<div dir = "rtl">
<h4>

تمرین معادله‌ی خطی مرتبه اول

</h4>
</div>
```

- ``\frac{dy}{dx} + y = e^x``

``\left\{ \begin{array}{l} p(x) = 1 &\\ q(x) = e^x \end{array} \right.``

``\int p(x) dx = \int dx = x``

``y = \frac{1}{e^{\int p(x) dx}} (\int e^{\int p(x) dx} q(x) dx + c)``

``y = \frac{1}{e^x} (\int e^x e^x dx + c) \longrightarrow y = e^{-x} (\int e^{2x} dx + c)``

``y = e^{-x} (\frac{e^{2x}}{2} + c) \longrightarrow y = \frac{e^x}{2} + c e^{-x}``.

- ``\frac{dy}{dx} = \frac{e^{2y}}{xe^{2y} - y}``

``\frac{dx}{dy} = \frac{x e^{2y} - y}{e^{2y}} = \frac{x e^{2y}}{e^{2y}} - \frac{y}{e^{2y}}``

``\frac{dx}{dy} = x - \frac{y}{e^{2y}} \longrightarrow x^\prime - x = -\frac{y}{e^{2y}}``

``\left\{ \begin{array}{l} p(y) = -1 &\\ q(y) = \frac{-y}{e^{2y}} \end{array} \right.``

``\int p(y) dy = \int -dy = -y``

``x = \frac{1}{e^{\int p(y) dy}} (\int e^{\int p(y) dy} q(y) dy + c)``

``x = \frac{1}{e^{-y}} (\int e^{-y} \frac{-y}{e^{2y}} dy + c) \longrightarrow x = e^y (\int -e^{-3y} y \ dy + c)``

``\left\{ \begin{array}{l} u = y \longrightarrow du = dy &\\ dv = -e^{-3y} dy \longrightarrow v = \frac{e^{-3y}}{3} \end{array} \right.``

``\int -e^{-3y} y \ dy = \int u \ dv = uv - \int v \ du = y \frac{e^{-3y}}{3} - \int \frac{e^{-3y}}{3} dy``

``\int -e^{-3y} y \ dy = \frac{y}{3e^{3y}} - (\frac{-1}{3})) \frac{e^{-3y}}{3} = \frac{y}{3e^{3y}} + \frac{1}{9} e^{-3y}``

``x = e^y (\frac{y}{3} e^{-3y} + \frac{1}{9} e^{-3y} + c) \longrightarrow x = e^{-2y} (\frac{y}{3} + \frac{1}{9}) + c e^y``.

```@raw html
<div dir = "rtl">
<h4>

تمرین معادله‌ی برنولی

</h4>
</div>
```

- ``y^\prime - \frac{y}{x} = y^2``

``n = 2``

``y^\prime y^{-2} - \frac{1}{xy} = 1``

``u = \frac{1}{y^{2 - 1}} = \frac{1}{y} \longrightarrow y = \frac{1}{u} \longrightarrow y^\prime = (u^{-1})^\prime = -u^{-2} u^\prime``

``u^\prime (-u^{-2}) (u^2) - \frac{u}{x} = 1``

``-u^\prime - \frac{u}{x} = 1 \longrightarrow u^\prime + \frac{u}{x} = -1``

``\left\{ \begin{array}{l} p(x) = \frac{1}{x} &\\ q(x) = -1 \end{array} \right.``

``\int p(x) dx = \int \frac{dx}{x} = ln|x|``

``u = \frac{1}{e^{\int p(x) dx}} (\int e^{\int p(x) dx} q(x) dx + c)``

``u = \frac{1}{e^{ln|x|}} (\int e^{ln|x|} (-1) dx + c)``

``u = \frac{1}{x} (\int -\frac{dx}{x} + c) = \frac{1}{x} (-ln|x| + c)``

``\frac{1}{y} = \frac{-ln|x| + c}{x}``

``y = \frac{x}{-ln|x| + c}``.

- ``y^\prime + xy = \frac{x}{y^3}``

``n = 3``

``u = \frac{1}{y^{3 - 1}} = \frac{1}{y^2} \longrightarrow y^{-2} = u \longrightarrow -2y^{-3}dy = du \longrightarrow dy = \frac{du}{-2}y^3``

``y^\prime y^{-3} + xy^{-2} = x``

``\frac{-u^\prime}{2} + xu = x \longrightarrow u^\prime - 2xu = -2x``

``\left\{ \begin{array}{l} p(x) = -2x &\\ q(x) = -2x \end{array} \right.``

``\int p(x) dx = \int -2x \ dx = -x^2``

``u = \frac{1}{e^{\int p(x) dx}} (\int e^{\int p(x) dx} q(x) dx + c)``

``u = \frac{1}{e^{-x^2}} (\int e^{-x^2} (-2x) dx + c)``

``\left\{ \begin{array}{l} v = -x^2 &\\ dv = -2x \ dx \end{array} \right.``

``\int -e^{-x^2} 2x \ dx = \int e^v dv = e^v = e^{-x^2}``

``u = \frac{1}{e^{-x^2}} (e^{-x^2} + c) = 1 + c e^{x^2}``

``\frac{1}{y^2} = 1 + c e^{x^2} \longrightarrow y^2 = \frac{1}{1 + c e^{x^2}}``

``y = \sqrt{\frac{1}{1 + c e^{x^2}}}``.

```@raw html
<div dir = "rtl">
<h2>

معادلات خطی مرتبه‌ی دوم همگن (با ضرایب ثابت)

</h2>
<p>

معادلاتی هستند به فرم زیر

</p>
</div>
```

``y^{\prime \prime} + a y^{\prime} + by = 0``

```@raw html
<div dir = "rtl">
<p>

که در اینجا آ و ب عددهای ثابتی هستند. به این دسته از معادلات همگن نیز گفته می‌شود زیرا در سمت راست معادله صفر وجود دارد. برای حل کردن این نوع معادلات، ابتدا باید معادله‌ی مفسر (مشخصه) را به دست آوریم و حل کنیم. معادله‌ی مفسر، معادله‌ای درجه دوم است که به صورت زیر به دست می‌آید:

</p>
</div>
```

``r^2 + ar + b = 0``

```@raw html
<div dir = "rtl">
<p>

این معادله را با روش دلتا حل می‌کنیم.

</p>
<h3>

حالت اول

</h3>
<p>

اگر دلتا بزرگتر از صفر باشد، معادله‌ی مفسر دو ریشه‌ی مجزا آر پایین‌نویس ۱ و آر پایین‌نویس ۲ خواهد داشت. در این صورت جواب معادله‌ی دیفرانسیل به شکل زیر است:

</p>
</div>
```

``\Delta > 0 \longrightarrow y = c_1 e^{r_1 x} + c_2 e^{r_2 x}``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل زیر را حل کنید.

</p>
</div>
```

``y^{\prime \prime} + y^{\prime} - 2y = 0``

``\left\{ \begin{array}{l} a = 1 &\\ b = -2 \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

معادله‌ی مفسر را تشکیل می‌دهیم.

</p>
</div>
```

``r^2 + r - 2 = 0``,

``\Delta = 1^2 - 4 (1) (-2) = 9 > 0``,

``r_1 = \frac{-1 + \sqrt{9}}{2 (1)} = -1``,

``r_2 = \frac{-1 - \sqrt{9}}{2 (1)} = -2``,

``y = c_1 e^{-x} + c_2 e^{-2x}``.

```@raw html
<div dir = "rtl">
<h3>

حالت دوم

</h3>
<p>

اگر دلتا برابر با صفر باشد، در این حالت معادله‌ی مفسر یک ریشه‌ی مضاعف دارد. فرض کنید که آر ریشه‌ی آن باشد. جواب معادله‌ی دیفرانسیل به صورت زیر است:

</p>
</div>
```

``\Delta = 0 \longrightarrow y = (c_1 + c_2 x) e^{r x}``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل زیر را حل کنید.

</p>
</div>
```

``y^{\prime \prime} + 4 y^{\prime} + 4y = 0``.

```@raw html
<div dir = "rtl">
<p>

معادله‌ی مفسر را تشکیل می‌دهیم:

</p>
</div>
```

``r^2 + 4r + 4 = 0``

``\Delta = 4^2 - 4 (1) (4) = 0 \longrightarrow r = \frac{-4}{2 (1)} = -2``

``y = (c_1 + c_2 x) e^{-2x}``.

```@raw html
<div dir = "rtl">
<h3>

حالت سوم

</h3>
</div>
```

``\Delta < 0``

```@raw html
<div dir = "rtl">
<p>

اگر دلتا کوچکتر از صفر باشد، معادله‌ی مفسر ریشه‌ی حقیقی ندارد. عدد آی عددی موهومی است.

</p>
</div>
```

``i^2 = -1 \longrightarrow i = \sqrt{-1}``

``z^2 = -1 \longrightarrow z^2 + 1 = 0``

``i \in \mathbb{C}``

![1](./assets/motionplanning/i.jpeg)

```@raw html
<div dir = "rtl">
<p>

در این حالت، معادله‌ی مفسر دو ریشه‌ی مختلط به شکل زیر دارد.

</p>
</div>
```

``\left\{ \begin{array}{l} r_1 = \alpha + \beta i &\\ r_2 = \alpha - \beta i \end{array} \right.``

``r_1, r_2 \in \mathbb{C} = \{ x + y i | x \in \mathbb{R}, y \in \mathbb{R} \}``

```@raw html
<div dir = "rtl">
<p>

در این صورت، جواب معادله‌ی دیفرانسیل به شکل زیر خواهد بود:

</p>
</div>
```

``y = e^{\alpha x} (c_1 cos(\beta x) + c_2 sin(\beta x))``

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی مرتبه دوم با ضرایب ثابت (همگن) را حل کنید.

</p>
</div>
```

``y^{\prime \prime} + 4 y^{\prime} + 5y = 0``

```@raw html
<div dir = "rtl">
<p>

معادله‌ی مشخصه را تشکیل می‌دهیم.

</p>
</div>
```

``r^2 + 4r + 5 = 0``,

``\Delta = 16 - 20 = -4``,

``r_1 = \frac{-4 + \sqrt{-4}}{2} = -2 + i``,

``r_2 = \frac{-4 - \sqrt{-4}}{2} = -2 - i``,

``\left\{ \begin{array}{l} \alpha = -2 &\\ \beta = 1 \end{array} \right.``,

``y = e^{-2x} (c_1 cos(x) + c_2 sin(x))``.

```@raw html
<div dir = "rtl">
<h2>

معادلات غیرکامل

</h2>
<p>

پیش‌تر گفتیم که معادلاتی به شکل زیر به شرطی که مشتق جزیی تابع ام نسبت به متغیر وای برابر با مشتق جزیی تابع ان نسبت به متغیر ایکس باشد کامل هستند.

</p>
</div>
```

``\left\{ \begin{array}{l} M(x, y) dx + N(x, y) dy = 0 &\\ \frac{\partial M}{\partial y} = \frac{\partial N}{\partial x} \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

اگر شرط بالا برقرار نباشد، معادله غیر کامل است.

</p>
</div>
```

``\frac{\partial M}{\partial y} \neq \frac{\partial N}{\partial x}``

```@raw html
<div dir = "rtl">
<p>

برای حل کردن معادلات غیر کامل، باید عبارتی مانند تابع ایچ بر حسب متغیرهای ایکس و وای را پیدا کنیم، به طوری که با ضرب کردن دو طرف معادله در تابع ایچ معادله کامل شود.

</p>
</div>
```

``h(x, y)``

```@raw html
<div dir = "rtl">
<p>

یعنی معادله‌ی زیر کامل باشد.

</p>
</div>
```

``h(x, y) M(x, y) dx + h(x, y) N(x, y) dy = 0``

```@raw html
<div dir = "rtl">
<p>

به تابع ایچ که بر حسب متغیرهای ایکس و وای است عامل انتگرال‌ساز گفته می‌شود. عامل انتگرال‌ساز منحصر به فرد نمی‌باشد. و در حالت کلی پیدا کردن عامل انتگرال‌ساز کار بسیار سختی است. اما در اینجا در دو حالت خیلی خاص عامل انتگرال‌ساز را معرفی می‌کنیم.

</p>
<h3>

حالت اول

</h3>
<p>

اگر معادله‌ی زیر غیر کامل باشد، یعنی مشتق جزیی تابع ام نسبت به متغیر وای نابرابر با مشتق جزیی تابع ان نسبت به متغیر ایکس باشد،

</p>
</div>
```

``\left\{ \begin{array}{l} M(x, y) dx + N(x, y) dy = 0 &\\ \frac{\partial M}{\partial y} \neq \frac{\partial N}{\partial x} \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

و همچنین عبارت پی عبارتی فقط بر حسب متغیر ایکس باشد،

</p>
</div>
```

``p(x) = \frac{1}{N} (\frac{\partial M}{\partial y} - \frac{\partial N}{\partial x})``

```@raw html
<div dir = "rtl">
<p>

آن‌گاه عامل انتگرال‌ساز برابر است با:

</p>
</div>
```

``e^{\int p(x) dx}``.

```@raw html
<div dir = "rtl">
<h3>

حالت دوم

</h3>
<p>

اگر عبارت پی عبارتی فقط بر حسب متغیر وای باشد،

</p>
</div>
```

``p(y) = \frac{-1}{M} (\frac{\partial M}{\partial y} - \frac{\partial N}{\partial x})``

```@raw html
<div dir = "rtl">
<p>

آن‌گاه عامل انتگرال‌ساز برابر است با:

</p>
</div>
```

``e^{\int p(y) dy}``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی غیرکامل زیر را حل کنید.

</p>
</div>
```

``dx + \frac{x - sin(y)}{y} dy = 0``.

``\left\{ \begin{array}{l} M(x, y) = 1 &\\ N(x, y) = \frac{x - sin(y)}{y} \end{array} \right.``

``\left\{ \begin{array}{l} \frac{\partial M}{\partial y} = 0 &\\ \frac{\partial N}{\partial x} = \frac{1}{y} \end{array} \right.``

``\left\{ \begin{array}{l} 0 \neq \frac{1}{y} &\\ \frac{\partial M}{\partial y} \neq \frac{\partial N}{\partial x} \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

پس معادله غیرکامل است. حالا مقدار عبارت پی را محاسبه می‌کنیم تا عامل انتگرال‌ساز را پیدا کنیم.

</p>
</div>
```

``p(y) = \frac{-1}{1} (0 - \frac{1}{y}) = \frac{1}{y}``

```@raw html
<div dir = "rtl">
<p>

عبارت پی به طور تمام بر حسب متغیر وای به دست آمد. سپس عامل انتگرال‌ساز را به شکل زیر به دست می‌آوریم:

</p>
</div>
```

``e^{\int p(y) dy} = e^{\int \frac{1}{y} dy} = e^{ln|y|} = y``

```@raw html
<div dir = "rtl">
<p>

دو طرف معادله را در عامل انتگرال‌ساز ضرب می‌کنیم تا معادله کامل شود.

</p>
</div>
```

``y \ dx + (x - sin(y)) dy = 0``

``\left\{ \begin{array}{l} M_1(x, y) = y &\\ N_1(x, y) = x - sin(y) \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

دوباره شرط کامل بودن معادله را بررسی می‌کنیم.

</p>
</div>
```

``\left\{ \begin{array}{l} \frac{\partial M_1}{\partial y} = 1 &\\ \frac{\partial N_1}{\partial x} = 1 \end{array} \right.``

``\frac{\partial M_1}{\partial y} = \frac{\partial N_1}{\partial x}``

```@raw html
<div dir = "rtl">
<p>

پس معادله کامل شد. در ادامه، معادله‌ی کامل را حل می‌کنیم تا به تابع مجهول اف برسیم.

</p>
</div>
```

``f(x, y) = \int M_1(x, y) dx + h(y) = \int y \ dx + h(y)``

``f(x, y) = xy + c + h(y)``

``\frac{\partial f(x, y)}{\partial y} = N_1(x, y) = \frac{\partial}{\partial y} (xy + c + h(y))``

```@raw html
<div dir = "rtl">
<p>

مقدار مشتق جزیی تابع اف نسبت به متغیر ایگرگ را با مقدار عبارت تابع ان پایین‌نویس ۱ مقایسه می‌کنیم تا مقدار مشتق تابع ایچ بر حسب متغیر ایگرگ را بیابیم.

</p>
</div>
```

``N_1(x, y) = x + h^{\prime}(y)``,

``x + h^{\prime}(y) = x - sin(y) \longrightarrow h^{\prime}(y) = -sin(y)``,

``f(x, y) = xy + c + \int h^{\prime}(y) dy = xy + c + \int -sin(y) dy``,

``f(x, y) = xy + c + cos(y) + c_1``,

``f(x, y) = xy + cos(y) + c_2``.

```@raw html
<div dir = "rtl">
<h3>

تمرین

</h3>
<p>

معادله‌ی غیرکامل را حل کنید.

</p>
</div>
```

``(x^2 + x - y^2) dx + x y \ dy = 0``.

``\left\{ \begin{array}{l} M(x, y) = x^2 + x - y^2 &\\ N(x, y) = xy \end{array} \right.``

``\left\{ \begin{array}{l} \frac{\partial M(x, y)}{\partial y} = -2y &\\ \frac{\partial N(x, y)}{\partial x} = y \end{array} \right.``

``\frac{\partial M}{\partial y} \neq \frac{\partial N}{\partial x}``

```@raw html
<div dir = "rtl">
<p>

معادله غیرکامل است. برای پیدا کردن عامل انتگرال‌ساز به شکل زیر عمل می‌کنیم.

</p>
</div>
```

``\frac{\partial M}{\partial y} - \frac{\partial N}{\partial x} = -2y - y = -3y``

``p(x) = \frac{1}{N} (\frac{\partial M}{\partial y} - \frac{\partial N}{\partial x}) = \frac{1}{xy} (-3y) = \frac{-3}{x}``

```@raw html
<div dir = "rtl">
<p>

به دلیل اینکه پی عبارتی فقط بر حسب متغیر ایکس است، عامل انتگرال‌ساز برابر است با:

</p>
</div>
```

``e^{\int p(x) dx} = e^{-3 \int \frac{dx}{x}} = e^{-3 ln|x|} = e^{ln|x^{-3}|} = x^{-3}``

```@raw html
<div dir = "rtl">
<p>

با ضرب کردن عامل انتگرال‌ساز در دو طرف معادله، آن را کامل می‌کنیم.

</p>
</div>
```

``x^{-3} (x^2 + x - y^2) dx + x^{-3} (xy) dy = 0``

``(x^{-1} + x^{-2} - y^2 x^{-3}) dx + (x^{-2} y) dy = 0``

``\left\{ \begin{array}{l} M_1(x, y) = x^{-1} + x^{-2} - y^2 x^{-3} &\\ N_1(x, y) = x^{-2} y \end{array} \right.``

``\frac{\partial M_1}{\partial y} = -2y x^{-3}``

``\frac{\partial N_1}{\partial x} = -2x^-3 y``

```@raw html
<div dir = "rtl">
<p>

معادله‌ی دیفرانسیل پس از ضرب کردن عامل انتگرال‌ساز کامل شد.

</p>
</div>
```

``\frac{\partial M_1}{\partial y} = \frac{\partial N_1}{\partial x}``

``f(x, y) = \int M_1(x, y) dx + h(y) = \int x^{-1} + x^{-2} - y^2 x^{-3} \ dx + h(y)``

``f(x, y) = ln|x| - x + y^2 \frac{x^{-2}}{2} + c + h(y)``

``N_1(x, y) = \frac{\partial f(x, y)}{\partial y} = \frac{\partial}{\partial y} (ln|x| - x + y^2 \frac{x^{-2}}{2} + c + h(y))``

```@raw html
<div dir = "rtl">
<p>

مشتق جزیی تابع اف نسبت به متغیر ایگرگ را با تابع ان پایین‌نویس ۱ مقایسه می‌کنیم تا مقدار مشتق تابع ایچ را پیدا کنیم.

</p>
</div>
```

``N_1(x, y) = yx^{-2} + h^{\prime}(y)``,

``h^{\prime}(y) = 0 \longrightarrow h(y) = \int h^{\prime}(y) dy = \int 0 dy = c_1``,

``f(x, y) = ln|x| - x + y^2 \frac{x^{-2}}{2} + c + c_1``,

``f(x, y) = ln|x| - x + y^2 \frac{x^{-2}}{2} + c_2``.

```@raw html
<div dir = "rtl">
<h2>

تبدیل لاپلاس

</h2>
<p>

در ریاضیات تبدیل‌هایی داریم که یک تابع را به تابع دیگری تبدیل می‌کند. برای مثال، مشتق‌گیری یک تبدیل است که تابع اف بر حسب متغیر ایکس را به تابع اف پریم بر حسب متغیر ایکس بدیل می‌کند.

</p>
</div>
```

``D: f(x) \to f^{\prime}(x)``,

``D f(x) = f^{\prime}(x)``.

```@raw html
<div dir = "rtl">
<p>

تبدیل لاپلاس یک تبدیل انتگرالی است که تابع اف بر حسب متغیر تی (که به طور معمول زمان فرض می‌شود) را به تابع اف بر حسب متغیر اس  (که به طور معمول فرکانس فرض می‌شود) تبدیل می‌کند. تبدیل لاپلاس کاربردهایی در فیزیک دارد، اما در اینجا (درس معادلات دیفرانسیل) ما فقط به این نکته توجه می‌کنیم که تبدیل لاپلاس می‌تواند ابزاری برای حل بعضی از معادلات دیفرانسیل باشد. تبدیل لاپلاس تابع اف بر حسب متغیر تی به صورت زیر تعریف می‌شود:

</p>
</div>
```

``L\{ f(t) \} = \int_0^\infty e^{-st} f(t) dt = F(s)``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

تبدیل لاپلاس تابع اف بر حسب متغیر تی با ضابطه‌ی داده شده در زیر، را به دست آورید.

</p>
</div>
```

``f(t) = 1``

``L\{ f(t) \} = \int_0^{\infty} e^{-st} dt = -\frac{1}{s} e^{-st} |_0^\infty = 0 - (-\frac{1}{s}) = \frac{1}{s}``.

```@raw html
<div dir = "rtl">
<p>

به شرطی که متغیر اس بزرگ‌تر از صفر باشد.

</p>
</div>
```

``s > 0``

```@raw html
<div dir = "rtl">
<p>

به دلیل اینکه علامت منفی متغیر اس انتگرال را بی‌نهایت می‌کند. یعنی انتگرال واگرا می‌شود. divergent

</p>
<h3>

مثال

</h3>
<p>

تبدیل لاپلاس تابع اف بر حسب متغیر تی را به دست آورید.

</p>
</div>
```

``f(t) = e^{at}``

``L\{ e^{at} \} = \int_0^\infty e^{-st} e^{at} dt = \int_0^\infty e^{(a - s) t} dt``

``L\{ e^{at} \} = \frac{e^{(a - s) t}}{a - s} |_0^\infty = \frac{e^{(a - s) \infty}}{a - s} - \frac{e^0}{a - s}``

``\left\{ \begin{array}{l} a > s \longrightarrow \infty &\\ a < s \longrightarrow -\frac{1}{a - s} = \frac{1}{s - a} \end{array} \right.``

```@raw html
<div dir = "rtl">
<h3>

یادآوری ریاضی عمومی

</h3>
<p>

روش تغییر متغیر:

</p>
</div>
```

``\int e^{at} dt``

``u = at \longrightarrow du = a \ dt``

``\frac{1}{a} \int e^u du = \int e^{at} dt = \frac{1}{a} e^u + c = \frac{1}{a} e^{at} + c``

```@raw html
<div dir = "rtl">
<h3>

جدول تبدیل لاپلاس

</h3>
</div>
```

``f(t) \to L \{ f(t) \} = F(s)``:

``f(t) = 1 \to L\{ 1 \} = F(s) = \frac{1}{s}, \ D_f: s > 0``,

``f(t) = e^at \to L\{ e^at \} = F(s) = \frac{1}{s - a}, \ D_f: s > 0``,

``f(t) = t \to L\{ t \} = F(s) = \frac{1}{s^2}, \ D_f: s > 0``,

``f(t) = t^n \ (n \in \mathbb{N}) \to L\{ t^n \} = F(s) = \frac{n!}{s^{n + 1}}, \ D_f: s > 0``,

``f(t) = cos(at) \to L\{ cos(at) \} = F(s) = \frac{s}{s^2 + a^2}, \ D_f: s > 0``,

``f(t) = sin(at) \to L\{ sin(at) \} = F(s) = \frac{a}{s^2 + a^2}, \ D_f: s > 0``.

```@raw html
<div dir = "rtl">
<h2>

تبدیل معکوس لاپلاس

</h2>
</div>
```

``F(s) \leftrightarrow f(t)``

```@raw html
<div dir = "rtl">
<p>

فرض کنید تابع اف بزرگ بر حسب متغیر اس را داشته باشیم و بخواهیم تابع اف کوچک بر حسب متغیر تی را پیدا کنیم. به این کار، تبدیل معکوس لاپلاس گفته می‌شود. برای مثال، فرض کنیم داشته باشیم:

</p>
</div>
```

``F(s) = \frac{1}{s - 8}``

```@raw html
<div dir = "rtl">
<p>

آن‌گاه داریم:

</p>
</div>
```

``L^{-1}\{ \frac{1}{s - 8} \} = e^{8t} = f(t)``

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

تبدیل معکوس لاپلاس تابع زیر را به دست آورید.

</p>
</div>
```

``F(s) = \frac{5s - 1}{s^2 - 1}``

``\frac{5s - 1}{s^2 - 1} = \frac{5s - 1}{(s + 1) (s - 1)} = \frac{A}{s - 1} + \frac{B}{s + 1} = \frac{A (s + 1) + B (s - 1)}{(s - 1) (s + 1)}``

``\frac{As + Bs + A - B}{(s - 1) (s + 1)} = \frac{(A + B) s + (A - B)}{(s - 1) (s + 1)}``

``\left\{ \begin{array}{l} A + B = 5 &\\ A - B = -1 \end{array} \right.``

``\left\{ \begin{array}{l} 2A = 4 \longrightarrow A = 2 &\\ B = 3 \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

از خاصیت خطی تبدیل لاپلاس معکوس استفاده می‌کنیم.

</p>
</div>
```

``L^{-1} \{ \frac{5s - 1}{s^2 - 1} \} = L^{-1} \{ \frac{2}{s - 1} + \frac{3}{s + 1} \} = 2 e^t + 3 e^{-t}``.

```@raw html
<div dir = "rtl">
<h3>

تمرین

</h3>
</div>
```

``L^{-1} \{ \frac{3s - 2}{s^3} \}``

``L^{-1} \{ \frac{3s - 2}{s^3} \} = L^{-1} \{ \frac{A}{s^3} + \frac{B}{s^2} + \frac{C}{s} \} = L^{-1} \{ \frac{A + Bs + Cs^2}{s^3} \}``

``3s - 2 = A + Bs + C s^2``

``\left\{ \begin{array}{l} A = -2 &\\ B = 3 &\\ C = 0 \end{array} \right.``

``L^{-1} \{ \frac{3s - 2}{s^3} \} = L^{-1} \{ \frac{-2}{s^3} + \frac{3}{s^2} + \frac{0}{s} \} = L^{-1} \{ \frac{-2}{s^3} \} + L^{-1} \{ \frac{3}{s^2} \} = -t^2 + 3t``

``t^n \leftrightarrow \frac{n!}{s^{n + 1}}``

```@raw html
<div dir = "rtl">
<h2>

تبدیل لاپلاس مشتق

</h2>
<p>

اگر تبدیل لاپلاس تابع اف بر حسب متغیر تی و تبدیل لاپلاس تابع اف پریم بر حسب متغیر تی موجود باشد،

</p>
</div>
```

``L\{ f(t) \}, \ L\{ f^{\prime}(t) \}``

```@raw html
<div dir = "rtl">
<p>

آن گاه:

</p>
</div>
```

``L \{ f^{\prime}(t) \} = s L \{ f(t) \} - f(0)``

``L \{ f^{\prime \prime}(t) \} = s L \{ f^\prime (t) \} - f^\prime (0)``

``L \{ f^{\prime \prime} (t) \} = s (s L \{ f(t) \} - f(0)) - f^\prime (0)``

``L \{ f^{\prime \prime} (t) \} = s^2 L \{ f(t) \} - s \ f(0) - f^\prime (0)``

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

به کمک تبدیل لاپلاس، معادله‌ی دیفرانسیل زیر را با شرایط اولیه‌ی داده شده حل کنید.

</p>
</div>
```

``y^\prime + y = e^{2t}``,

``f(0) = y(0) = 0``.

```@raw html
<div dir = "rtl">
<p>

برای حل کردن معادله از دو طرف معادله تبدیل لاپلاس می‌گیریم.

</p>
</div>
```

``L \{ y^\prime + y \} = L \{ e^{2t} \}``

``L \{ y^\prime \} + L \{ y \} = \frac{1}{s - 2}``

``s \ L \{ y \} - y(0) + L \{ y \} = \frac{1}{s - 2}``

``L \{ y \} (s + 1) = \frac{1}{s - 2}``

``L \{ y \} = \frac{1}{(s + 1) (s - 2)} \longrightarrow y = L^{-1} \{ \frac{1}{(s + 1) (s - 2)} \}``

``\frac{1}{(s + 1) (s - 2)} = \frac{A}{s + 1} + \frac{B}{s - 2} = \frac{A (s - 2) + B (s + 1)}{(s + 1) (s - 2)} = \frac{(A + B) s - 2A + B}{(s + 1) (s - 2)}``

``\left\{ \begin{array}{l} A + B = 0 &\\ -2A + B = 1 \end{array} \right.``

``3A = -1 \longrightarrow A = \frac{-1}{3} \longrightarrow B = \frac{1}{3}``

``y = L^{-1} \{ \frac{\frac{-1}{3}}{s + 1} + \frac{\frac{1}{3}}{s - 2} \} = \frac{-1}{3} L^{-1} \{ \frac{1}{s + 1} \} + \frac{1}{3} L^{-1} \{ \frac{1}{s - 2} \}``

``y = \frac{-1}{3} e^{-t} + \frac{1}{3} e^{2t}``.

```@raw html
<div dir = "rtl">
<p>

یادآوری

</p>
</div>
```

``L \{ y^\prime \} = s L \{ y \} - y(0)``.

``L \{ y^{\prime \prime} \} = s L \{ y^{\prime} \} - y^\prime (0) = s (s L \{ y \} - y(0)) - y^\prime (0)``,

``L \{ y^{\prime \prime} \} = s^2 L \{ y \} - s \ y(0) - y^{\prime} (0)``.

```@raw html
<div dir = "rtl">
<h3>

مثال

</h3>
<p>

معادله‌ی دیفرانسیل زیر با شرایط اولیه‌ی داده شده را با استفاده از تبدیل لاپلاس حل کنید.

</p>
</div>
```

``y^{\prime \prime} - 4 y^\prime - 5 y = 0``,

``\left\{ \begin{array}{l} y(0) = 1 &\\ y^\prime (0) = 0 \end{array} \right.``.

``L \{ y^{\prime \prime} - 4 y^\prime - 5y \} = L \{ 0 \}``

``L \{ y^{\prime \prime} \} - 4 L \{ y^\prime \} - 5 L \{ y \} = 0``

``s^2 L \{ y \} - s (1) - 4 (s L \{ y \} - 1) - 5 L \{ y \} = 0``

``s^2 L \{ y \} - s - 4s L \{ y \} + 4 - 5 L \{ y \} = 0``

``L \{ y \} (s^2 - 4s - 5) - s + 4 = 0``

``L \{ y \} (s^2 - 4s - 5) = s - 4``

``L \{ y \} = \frac{s - 4}{s^2 - 4s - 5} \longrightarrow y = L^{-1} \{ \frac{s - 4}{s^2 - 4s - 5} \}``

``\frac{s - 4}{s^2 - 4s - 5} = \frac{s - 4}{(s + 1) (s - 5)} = \frac{A}{s + 1} + \frac{B}{s - 5}``

``\frac{A (s - 5) + B (s + 1)}{(s + 1) (s - 5)} = \frac{(A + B) s - 5A + B}{(s + 1) (s - 5)}``

``\left\{ \begin{array}{l} A + B = 1 &\\ -5A + B = -4 \end{array} \right.``

``\left\{ \begin{array}{l} A + B = 1 &\\ 5A - B = 4 \end{array} \right.``

``\left\{ \begin{array}{l} 6A = 5 \longrightarrow A = \frac{5}{6} &\\ B = 1 - \frac{5}{6} = \frac{1}{6} \end{array} \right.``

``y = L^{-1} \{ \frac{\frac{5}{6}}{s + 1} + \frac{\frac{1}{6}}{s - 5} \} = \frac{5}{6} L^{-1} \{ \frac{1}{s + 1} \} + \frac{1}{6} L^{-1} \{ \frac{1}{s - 5} \}``

``y = \frac{5}{6} e^{-t} + \frac{1}{6} e^{5t}``

```@raw html
<div dir = "rtl">
<p>

اگر که بخواهیم سوال را با روش قبل حل کنیم:

</p>
</div>
```

``y^{\prime \prime} - 4 y^\prime - 5y = 0``

```@raw html
<div dir = "rtl">
<p>

معادله‌ی مفسر را می‌نویسیم:

</p>
</div>
```

``r^2 - 4r - 5 = 0``

``\Delta = \frac{4 \pm \sqrt{16 + 20}}{2}``

``\Delta = \frac{4 \pm 6}{2} = 2 \pm 3``

``\left\{ \begin{array}{l} r_1 = 5 &\\ r_2 = -1 \end{array} \right.``

``(r + 1) (r - 5) = 0``

``y = c_1 e^{r_1 x} + c_2 e^{r_2 x} \longrightarrow y = c_1 e^{-t} + c_2 e^{5t}``

```@raw html
<div dir = "rtl">
<p>

شرایط اولیه‌ی معادله را بررسی می‌کنیم تا ضریب‌های تابع نمایی را پیدا کنیم.

</p>
</div>
```

``\left\{ \begin{array}{l} y(0) = 1 &\\ y^\prime (0) = 0 \end{array} \right.``

``y(0) = 1 \longrightarrow c_1 e^{-(0)} + c_2 e^{5 (0)} = 1 \longrightarrow c_1 + c_2 = 1``

``y^\prime (0) = 0 \longrightarrow y^\prime = -c_1 e^{-x} + 5 c_2 e^{5x} = 0``

``y^\prime (0) = -c_1 e^0 + 5c_2 e^0 = 0 \longrightarrow -c_1 + 5c_2 = 0``

``\left\{ \begin{array}{l} c_1 + c_2 = 1 &\\ -c_1 + 5c_2 = 0 \end{array} \right.``

``6c_2 = 1 \longrightarrow c_2 = \frac{1}{6}``

``c_1 + \frac{1}{6} = 1 \longrightarrow c_1 = 1 - \frac{1}{6} = \frac{5}{6}``

``y = \frac{5}{6} e^{-t} + \frac{1}{6} e^{5t}``.

```@raw html
<div dir = "rtl">
<h3>

تمرین

</h3>
<p>

معادله‌ی دیفرانسیل زیر را به کمک تبدیل لاپلاس حل کنید.

</p>
</div>
```

``y^{\prime \prime} - 2 y^\prime - 8y = 0``,

``\left\{ \begin{array}{l} y(0) = 1 &\\ y^\prime (0) = 0 \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

تبدیل لاپلاس مشتق‌های مرتبه‌ی اول و مرتبه‌ی دوم را محاسبه می‌کنیم.

</p>
</div>
```

``L \{ y^\prime \} = s L \{ y \} - y(0)``

``L \{ y^{\prime \prime} \} = s L \{ y^\prime \} - y^\prime (0) = s (s L \{ y \} - y(0)) - y^\prime (0)``

``L \{ y^{\prime \prime} \} = s^2 L \{ y \} - s \ y(0) - y^\prime (0)``

```@raw html
<div dir = "rtl">
<p>

از خاصیت خطی بودن تبدیل لاپلاس استفاده می‌کنیم تا معادله‌ی دیفرانسیل را تبدیل کنیم.

</p>
</div>
```

``s^2 L \{ y \} - s \ y(0) - y^\prime (0) - 2s \ L \{ y \} + 2y(0) - 8 L \{ y \} = 0``.

```@raw html
<div dir = "rtl">
<p>

از تبدیل لاپلاس متغیر وای فاکتور می‌گیریم.

</p>
</div>
```

``L \{ y \} (s^2 - 2s - 8) - s y(0) - y^\prime (0) + 2 y(0) = 0``

```@raw html
<div dir = "rtl">
<p>

شرایط اولیه را در معادله‌ی تبدیل شده جایگذاری می‌کنیم.

</p>
</div>
```

``L \{ y \} (s^2 - 2s - 8) - s + 2 = 0 \longrightarrow L \{ y \} (s^2 - 2s - 8) = s - 2``

``L \{ y \} = \frac{s - 2}{s^2 - 2s - 8} \longrightarrow L \{ y \} = \frac{s - 2}{(s - 4) (s + 2)}``

``\sqrt{\Delta} = \sqrt{(-2)^2 - 4 (1) (-8)} = \sqrt{4 + 32} = \sqrt{36} = 6``

``s_{1, 2} = \frac{2 \pm 6}{2} = 1 \pm 3``

``\left\{ \begin{array}{l} s_1 = 4 &\\ s_2 = -2 \end{array} \right.``

``y = L^{-1} \{ \frac{s - 2}{(s - 4) (s + 2)} \} = L^{-1} \{ \frac{A}{s - 4} + \frac{B}{s + 2} \}``

``y = L^{-1} \{ \frac{A (s + 2)}{(s - 4) (s + 2)} + \frac{B (s - 4)}{(s - 4) (s + 2)} \}``

``y = L^{-1} \{ \frac{As + 2A + Bs - 4B}{(s - 4) (s + 2)} \} = L^{-1} \{ \frac{s - 2}{(s - 4) (s + 2)} \}``

``\left\{ \begin{array}{l} A + B = 1 &\\ 2A - 4B = -2 \end{array} \right.``

``\left\{ \begin{array}{l} A + B = 1 &\\ -A + 2B = 1 \end{array} \right.``

``3B = 2 \longrightarrow B = \frac{2}{3} \longrightarrow A = \frac{1}{3}``

``y = L^{-1} \{ \frac{\frac{1}{3}}{s - 4} + \frac{\frac{2}{3}}{s + 2} \} = \frac{1}{3} L^{-1} \{ \frac{1}{s - 4} \} + \frac{2}{3} L^{-1} \{ \frac{1}{s + 2} \}``

``y = \frac{1}{3} e^{4t} + \frac{2}{3} e^{-2t}``.

```@raw html
<div dir = "rtl">
<h3>

نکته

</h3>
<p>

برای استفاده کردن از شتاب در معادله‌ی دیفرانسیل به سرعت اولیه نیاز داریم. اما برای استفاده کردن از سرعت در معادله‌ی دیفرانسیل به مکان اولیه نیاز داریم.

</p>
<h2>

دستگاه معادلات دیفرانسیل

</h2>
</div>
```

``\left\{ \begin{array}{l} y_1^{\prime} = 2 y_1 + 3 y_2 &\\ y_2^{\prime} = 4 y_1 - 2 y_2 \end{array} \right.``,

``y = f(x)``.

``y_1^{\prime \prime} = 2y_1^\prime + 3y_2^\prime \longrightarrow y_1^{\prime \prime} = 2y_1^\prime + 3(4y_1 - 2y_2) \longrightarrow y_1^{\prime \prime} = 2y_1^\prime + 12y_1 - 2(3y_2)``

``y_1^{\prime \prime} = 2y_1^\prime + 12y_1 - 2(y_1^\prime - 2y_1) \longrightarrow y_1^{\prime \prime} = 16y_1 \longrightarrow y_1^{\prime \prime} - 16y_1 = 0``

```@raw html
<div dir = "rtl">
<p>

به یک دستگاه معادله‌ی دیفرانسیل خطی مرتبه‌ی دوم با ضرایب ثابت رسیدیم. حالا معادله‌ی مفسر را تشکیل می‌دهیم.

</p>
</div>
```

``r^2 - 16 = 0 \longrightarrow r^2 = 16 \longrightarrow r = \pm 4``

```@raw html
<div dir = "rtl">
<p>

یادآوری: معادله‌ی خطی مرتبه دوم با ضرایب ثابت.

</p>
</div>
```

``\left\{ \begin{array}{l} y^{\prime \prime} + ay^\prime + by = 0 &\\ r^2 + ar + b = 0 \end{array} \right.``

```@raw html
<div dir = "rtl">
<p>

در نتیجه برای حل معادله داریم:

</p>
</div>
```

``y_1 = c_1 e^{r_1 x} + c_2 e^{r_2 x} = c_1 e^{4x} + c_2 e^{-4x}``

``y_1^\prime = 4c_1 e^{4x} - 4c_2 e^{-4x} = 2(c_1 e^{4x} + c_2 e^{-4x}) + 3y_2``

``y_2 = \frac{1}{3} (4c_1 e^{4x} - 4c_2 e^{-4x} - 2(c_1 e^{4x} + c_2 e^{-4x}))``

``y_2 = \frac{1}{3} ((4c_1 - 2c_1) e^{4x} + (-2 c_2 - 4 c_2) e^{-4x})``

``y_2 = \frac{2}{3} c_1 e^{4x} - 2e^{-4x}``

```@raw html
<div dir = "rtl">
<h3>

تمرین

</h3>
<p>

دستگاه معادله ی دیفرانسیل زیر را حل کنید.

</p>
</div>
```

``\left\{ \begin{array}{l} y_1^\prime = y_1 + y_2 &\\ y_2^\prime = 4y_1 - 2y_2 \end{array} \right.``

``y = f(x)``

``y_1^{\prime \prime} = y_1^\prime + y_2^\prime \longrightarrow y_1^{\prime \prime} = y_1 + (4y_1 - 2y_2)``

``y_1^{\prime \prime} = y_1^\prime + 4y_1 - 2(y_1^\prime - y_1) \longrightarrow y_1^{\prime \prime} = -y_1^\prime + 3y_1``

``y_1^{\prime \prime} + y_1^\prime - 3y_1 = 0``.

```@raw html
<div dir = "rtl">
<p>

به یک معادله‌ی دیفرانسیل خطی مرتبه‌ی دوم با ضرایب ثابت رسیدیم. پس باید معادله‌ی مفسر را در ادامه بنویسیم.

</p>
</div>
```

``\left\{ \begin{array}{l} r^2 + ar + b = 0 &\\ y^{\prime \prime} + ay^\prime + by = 0 \end{array} \right.``

``\left\{ \begin{array}{l} a = 1 &\\ b = -3 \end{array} \right.``

``r^2 + r - 3 = 0``

``r_{1, 2} = \frac{-1 \pm \sqrt{(1)^2 - 4 (1) (-3)}}{2} = \frac{-1 \pm \sqrt{1 + 12}}{2} = \frac{-1 \pm \sqrt{13}}{2}``

``\Delta = 13 > 0``

``y_1 = c_1 e^{r_1 x} + c_2 e^{r_2 x} \longrightarrow y_1 = c_1 e^{\frac{-1 + \sqrt{13}}{2} x} + c_2 e^{\frac{-1 - \sqrt{13}}{2} x}``

``y_1^\prime = \frac{-1 + \sqrt{13}}{2} c_1 e^{\frac{-1 + \sqrt{13}}{2} x} + \frac{-1 - \sqrt{13}}{2} c_2 e^{\frac{-1 - \sqrt{13}}{2} x}``

``y_2 = y_1^\prime - y_1 = \frac{-1 + \sqrt{13}}{2} c_1 e^{\frac{-1 + \sqrt{13}}{2} x} + \frac{-1 - \sqrt{13}}{2} c_2 e^{\frac{-1 - \sqrt{13}}{x} x} - y_1``

``y_2 = \frac{-1 + \sqrt{13}}{2} c_1 e^{\frac{-1 + \sqrt{13}}{2} x} + \frac{-1 - \sqrt{13}}{2} c_2 e^{\frac{-1 - \sqrt{13}}{2} x} - c_1 e^{\frac{-1 + \sqrt{13}}{2} x} - c_2 e^{\frac{-1 - \sqrt{13}}{2} x}``.

```@raw html
<div dir = "rtl">
<h3>

تمرین

</h3>
<p>

دستگاه معادله ی دیفرانسیل زیر را حل کنید.

</p>
</div>
```

``\left\{ \begin{array}{l} y_1^\prime = 2y_1 - 5y_2 &\\ y_2^\prime = 5y_1 - 6y_2 \end{array} \right.``

``y = f(x)``

```@raw html
<div dir = "rtl">
<p>

از مشتق تابع وای پایین‌نویس ۱، یک بار مشتق می‌گیریم تا به مشتق مرتبه‌ی دوم آن دست پیدا کنیم.

</p>
</div>
```

``y_1^{\prime \prime} = 2y_1^\prime - 5y_2^\prime = 2y_1^\prime - 5(5y_1 - 6y_2) = 2y_1^\prime - 25y_1 + 30y_2``

```@raw html
<div dir = "rtl">
<p>

از طرفی داریم:

</p>
</div>
```

``-5y_2 = y_1^\prime - 2y_1 \longrightarrow y_2 = \frac{-1}{5}y_1^\prime + \frac{2}{5} y_1``

``y_1^{\prime \prime} = 2y_1^{\prime} - 25y_1 + 30(\frac{-1}{5}y_1^\prime + \frac{2}{5}y_1) = 2y_1^\prime - 25y_1 - 6y_1^\prime + 12y_1``

``y_1 ^{\prime \prime} = -4y_1^\prime - 13y_1 \longrightarrow y_1^{\prime \prime} + 4y_1^\prime + 13y_1 = 0``

```@raw html
<div dir = "rtl">
<p>

به یک معادله‌ی خطی مرتبه دوم با ضرایب ثابت رسیدیم. پس معادله‌ی مفسر را ایجاد می‌کنیم.

</p>
</div>
```

``\left\{ \begin{array}{l} r^2 + ar + b = 0 &\\ y^{\prime \prime} + ay^\prime + by = 0 \end{array} \right.``

``\left\{ \begin{array}{l} a = 4 &\\ b = 13 \end{array} \right.``

``r^2 + 4r + 13 = 0``

``\sqrt{\Delta} = \sqrt{b_1^2 - 4a_1c_1} = \sqrt{(4)^2 - 4 (1) (13)} = \sqrt{16 - 52} = \sqrt{-36} = 6i``

``\Delta = -36 < 0``.

```@raw html
<div dir = "rtl">
<p>

مقدار دلتا کوچک‌تر از صفر شد. پس جواب معادله‌ی دیفرانسیل به شکل زیر است:

</p>
</div>
```

``\left\{ \begin{array}{l} r_1 = \alpha + i \beta &\\ r_2 = \alpha - i \beta \end{array} \right.``

``\left\{ \begin{array}{l} r_1 = \frac{-4 + 6i}{2} &\\ r_2 = \frac{-4 - 6i}{2} \end{array} \right.``

``\left\{ \begin{array}{l} r_1 = -2 + 3i &\\ r_2 = -2 - 3i \end{array} \right.``

``\left\{ \begin{array}{l} \alpha = -2 &\\ \beta = 3 \end{array} \right.``

``y = e^{\alpha x} (c_1 \ cos(\beta x) + c_2 \ sin(\beta x))``

``y_1 = e^{-2x} (c_1 \ cos(3x) + c_2 \ sin(3x))``

``y_1^\prime = -2e^{-2x}(c_1cos(3x) + c_2sin(3x)) + e^{-2x}(-3c_1sin(3x) + 3c_2cos(3x))``

```@raw html
<div dir = "rtl">
<p>

با جایگذاری مقدارهای تابع ایگرگ پایین‌نویس ۱ و مشتق آن در دستگاه معادلات دیفرانسیل به مقدار تابع ایگرگ پایین‌نویس ۲ می‌رسیم.

</p>
</div>
```

``y_1^\prime = 2y_1 - 5y_2 \longrightarrow y_2 = \frac{-1}{5} y_1^\prime + \frac{2}{5}y_1``,

``y_2 = \frac{-1}{5}(-2e^{-2x}(c_1cos(3x) + c_2sin(3x)) + e^{-2x}(-3c_1sin(3x) + 3c_2cos(3x)) + \frac{2}{5} e^{-2x}(c_1cos(3x) + c_2sin(3x))``.



# References

```@raw html
<div dir = "rtl">
<h1>

منابع

</h1>

<ol start=1>

<li>
محمد علی کرایه چیان، ریاضی عمومی ۲، انتشارات تمرین، سال ۱۴۰۱، شابک 978-964-7695-64-0
</li>

<li>
ریچارد ام. موری، اس. شانکار ساستری، برنامه‌ریزی حرکت غیرمقید: هدایت با استفاده از موج سینوسی، در رسالات کنترل خودکار موسسه‌ی مهندسان برق و الکترونیک، جلد ۳۸، شماره‌ی ۵، ماه اردیبهشت، سال ۱۳۷۲.
</li>

</ol>
</div>
```