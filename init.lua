simplerigid={}

dofile(minetest.get_modpath("simplerigid").."/collision_detection.lua")
dofile(minetest.get_modpath("simplerigid").."/helper_functions.lua")
dofile(minetest.get_modpath("simplerigid").."/rigidbody.lua")

minetest.register_chatcommand("test",{
    description="test the rigidbody collision",
    func=function(name,param)
        --minetest.debug(dump(simplerigid.collide({pos=vector.new(0,0,0),radius=1},{pos=vector.new(0,1,0),radius=1},"sphere-sphere")))
        --[[minetest.debug(dump(simplerigid.is_point_over_polygon(
            vector.new(0,0.5,-0.1),
            {vector.new(-1,0,-1),vector.new(-1,0,1),vector.new(1,0,1)}
        )))]]
        --[[minetest.debug(dump(
            simplerigid.get_closest_along_line(vector.new(0,0,0),vector.new(0,0,1),vector.new(0,1,2))
        ))]]
        --[[minetest.debug(dump(simplerigid.collide(
            {
                pos=vector.new(0,0.4,-0.9),
                radius=0.5
            },
            {
                polygons={{
                    vector.new(0,0,1),
                    vector.new(-1,0,-1),
                    vector.new(1,0,-1)
                }}
            },
            "sphere-polygon")
        ))]]
    end
})

minetest.register_chatcommand("ball",{
    description="spawn a sphere rigidbody for testing",
    func=function(name)
        local player=minetest.get_player_by_name(name)
        local object=minetest.add_entity(player:get_pos(),"simplerigid:test",minetest.serialize({random_velocity=true}))
    end
})