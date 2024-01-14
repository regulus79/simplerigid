
simplerigid.collide=function(sphere,object,type)
    if type=="sphere-sphere" then
        return simplerigid.sphere_sphere_collide(sphere,object)
    elseif type=="sphere-polygon" then
        return simplerigid.sphere_polygon_collide(sphere,object)
    else
        minetest.debug("Unknown collision type: "..tostring(type))
    end
end

simplerigid.sphere_sphere_collide=function(sphere,object)
    local dir=object.pos:direction(sphere.pos)
    local dist=object.pos:distance(sphere.pos)
    local overlap=dist-object.radius-sphere.radius
    if overlap>=0 then
        return nil
    else
        return {
            dir=dir,
            overlap=-overlap
        }
    end
end

simplerigid.sphere_polygon_collide = function(sphere,object)
    local dir=vector.new(0,0,0)
    local max_overlap=0
    local contact_type=nil

    local contact_priority={
        face=1,
        edge=2,
        point=3,
    }

    for _,polygon in pairs(object.polygons) do
        if simplerigid.is_point_over_polygon(sphere.pos,polygon) then
            local normal=(polygon[2]-polygon[1]):cross(polygon[3]-polygon[1]):normalize()
            local center=(polygon[1]+polygon[2]+polygon[3])/3
            local overlap=math.abs(normal:dot(sphere.pos-center))-sphere.radius
            if overlap<0 and -overlap>max_overlap and not (contact_type and contact_priority[contact_type]<contact_priority["face"]) then
                local dot_product=normal:dot(sphere.pos-center)
                --minetest.debug(dot_product,dump(sphere.pos-center))
                if dot_product>0 then
                    dir=normal
                else
                    dir=-normal
                end
                max_overlap=-overlap
                contact_type="face"
                --minetest.debug(dump({dir=dir,overlap=max_overlap,contact_type=contact_type}))
            end
        end
        local edges={
            polygon[1]-polygon[2],
            polygon[2]-polygon[3],
            polygon[3]-polygon[1]
        }
        for i,edge in pairs(edges) do
            local closest_point=simplerigid.get_closest_along_line(sphere.pos,polygon[i],polygon[i%3+1])
            if closest_point.t>=0 and closest_point.t<=1 then
                local overlap=closest_point.dist-sphere.radius
                if overlap<0 and -overlap>max_overlap and not (contact_type and contact_priority[contact_type]<contact_priority["edge"]) then 
                    dir=closest_point.pos:direction(sphere.pos)
                    max_overlap=-overlap
                    contact_type="edge"
                    --minetest.debug(dump({dir=dir,overlap=max_overlap,contact_type=contact_type}))
                end
            end
        end
        for _,point in pairs(polygon) do
            local point_dir=point:direction(sphere.pos)
            local dist=point:distance(sphere.pos)
            local point_overlap=dist-sphere.radius
            if point_overlap<0 and -point_overlap>max_overlap and not (contact_type and contact_priority[contact_type]<contact_priority["point"]) then
                dir=point_dir
                max_overlap=-point_overlap
                contact_type="point"
                --minetest.debug(dump({dir=dir,overlap=max_overlap,contact_type=contact_type}))
            end
        end
    end
    if max_overlap>0 then
        return {
            dir=dir,
            overlap=max_overlap,
            contact_type=contact_type
        }
    end
end

simplerigid.get_closest_along_line=function(p0,p1,p2)
    --[[
        p(t)=p1+t(p2-p1)
        p'(t)=(p2-p1)
        d(t)=(p(t)-p0).x^2 + (p(t)-p0).y^2 + (p(t)-p0).z^2
        d'(t)=2(p(t)-p0).x*p'(t).x + 2(p(t)-p0).y*p'(t).y + 2(p(t)-p0).z*p'(t).z
            =2(p1+t(p2-p1)-p0).x*(p2-p1).x + 2(p1+t(p2-p1)-p0).y*(p2-p1).y + 2(p1+t(p2-p1)-p0).z*(p2-p1).z
            =2p1.x*(p2-p1).x+2t(p2-p1).x*(p2-p1).x-2p0.x*(p2-p1).x + 2p1.y*(p2-p1).y+2t(p2-p1).y*(p2-p1).y-2p0.y*(p2-p1).y + 2p1.z*(p2-p1).z+2t(p2-p1).z*(p2-p1).z-2p0.z*(p2-p1).z
        0=2p1.x*(p2-p1).x+2t(p2-p1).x*(p2-p1).x-2p0.x*(p2-p1).x + 2p1.y*(p2-p1).y+2t(p2-p1).y*(p2-p1).y-2p0.y*(p2-p1).y + 2p1.z*(p2-p1).z+2t(p2-p1).z*(p2-p1).z-2p0.z*(p2-p1).z
        -2t(p2-p1).x*(p2-p1).x-2t(p2-p1).y*(p2-p1).y-2t(p2-p1).z*(p2-p1).z=2p1.x*(p2-p1).x-2p0.x*(p2-p1).x + 2p1.y*(p2-p1).y-2p0.y*(p2-p1).y + 2p1.z*(p2-p1).z-2p0.z*(p2-p1).z
        -2t((p2-p1).x*(p2-p1).x+(p2-p1).y*(p2-p1).y+(p2-p1).z*(p2-p1).z)=2p1.x*(p2-p1).x-2p0.x*(p2-p1).x + 2p1.y*(p2-p1).y-2p0.y*(p2-p1).y + 2p1.z*(p2-p1).z-2p0.z*(p2-p1).z
        Final equation:
        t=(2p1.x*(p2-p1).x-2p0.x*(p2-p1).x + 2p1.y*(p2-p1).y-2p0.y*(p2-p1).y+ 2p1.z*(p2-p1).z-2p0.z*(p2-p1).z)/((p2-p1).x*(p2-p1).x+(p2-p1).y*(p2-p1).y+(p2-p1).z*(p2-p1).z)/-2
    ]]
    local t=(
        2*p1.x*(p2-p1).x - 2*p0.x*(p2-p1).x + 
        2*p1.y*(p2-p1).y - 2*p0.y*(p2-p1).y +
        2*p1.z*(p2-p1).z - 2*p0.z*(p2-p1).z)/(
            (p2-p1).x*(p2-p1).x +
            (p2-p1).y*(p2-p1).y +
            (p2-p1).z*(p2-p1).z
        )/-2
    local pos=t*(p2-p1)+p1
    local dist=pos:distance(p0)
    return {
        t=t,
        pos=pos,
        dist=dist
    }
end

simplerigid.is_point_over_polygon=function(point,polygon)
    local center=(polygon[1]+polygon[2]+polygon[3])/3
    local normal=(polygon[2]-polygon[1]):cross(polygon[3]-polygon[1]):normalize()
    local edges={
        polygon[1]-polygon[2],
        polygon[2]-polygon[3],
        polygon[3]-polygon[1]
    }
    for i,edge in pairs(edges) do
        if edge:cross(normal):dot(center-polygon[i])*edge:cross(normal):dot(point-polygon[i])<0 then
            return false
        end
    end
    return true
end