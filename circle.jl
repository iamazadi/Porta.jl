function area(radius)
    π * radius^2
end


function distance(x₁, y₁, x₂, y₂)
    dx = x₂ - x₁
    dy = y₂ - y₁
    d² = dx^2 + dy^2
    sqrt(d²)
end


function circlearea(xc, yc, xp, yp)
    area(distance(xc, yc, xp, yp))
end

