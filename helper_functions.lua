simplerigid.generate_node_collision=function(pos)
    local collision_params={
        polygons={}
    }
    local dirs={
        vector.new(1,0,0),
        vector.new(0,1,0),
        vector.new(0,0,1),
    }
    for i,dir in pairs(dirs) do
        collision_params.polygons[i*4-3]={
            vector.new(0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            vector.new(-0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            vector.new(0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
        }
        collision_params.polygons[i*4-2]={
            vector.new(-0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
            vector.new(-0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            vector.new(0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
        }
        collision_params.polygons[i*4-1]={
            -vector.new(0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            -vector.new(-0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            -vector.new(0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
        }
        collision_params.polygons[i*4]={
            -vector.new(-0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
            -vector.new(-0.5,0.5,0.5):rotate_around_axis(dir,math.pi/2)+pos,
            -vector.new(0.5,0.5,-0.5):rotate_around_axis(dir,math.pi/2)+pos,
        }
    end
    return collision_params
end