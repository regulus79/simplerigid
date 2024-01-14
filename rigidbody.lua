
minetest.register_entity("simplerigid:test",{
    initial_properties={
        visual="mesh",
        mesh="sphere.obj",
        textures={"default_wood.png"},
        physical=false,
        static_save=false,
        visual_size=vector.new(10,10,10)*2,
    },
    _oldpos=nil,
    _acceleration=vector.new(0,0,0),
    _timer=0,
    _active=true,
    _angular_velocity=vector.new(0,0,0),
    _up_vector=vector.new(0,1,0),
    _forwards_vector=vector.new(0,0,1),
    _radius=1.0,
    _angular_inertia=vector.new(1,1,1)*2,
    _mass=1,
    _linear_decay=0.9,
    _angular_decay=0.9,
    on_activate=function(self,staticdata)
        if not self._oldpos then
            self._oldpos=self.object:get_pos()
        end
        local staticdata_table=minetest.deserialize(staticdata)
        if staticdata_table and staticdata_table.random_velocity then
            self._oldpos=self.object:get_pos()+vector.new(math.random(-1,1),math.random(-1,1),math.random(-1,1)):normalize()*0.2
        end
        self.object:set_acceleration(vector.new(0,-10,0))
    end,
    on_step=function(self,dtime)
        if not self._active then
            self.object:set_velocity(vector.new(0,0,0))
            self.object:set_acceleration(vector.new(0,0,0))
            return
        end
        self._up_vector=self._up_vector:rotate_around_axis(self._angular_velocity:normalize(),self._angular_velocity:length()*dtime)
        self._forwards_vector=self._forwards_vector:rotate_around_axis(self._angular_velocity:normalize(),self._angular_velocity:length()*dtime)
        local rotation=vector.dir_to_rotation(self._forwards_vector,self._up_vector)
        self.object:set_rotation(rotation)

        self._angular_velocity=self._angular_velocity-self._angular_velocity*(1-self._angular_decay)*dtime
        self.object:add_velocity(-self.object:get_velocity()*(1-self._linear_decay)*dtime)

        --[[
        self._timer=self._timer+dtime
        --minetest.debug(self._timer)
        if self._timer<1 then
            return
        else
            self._timer=0
        end
        minetest.debug("HEYYYY")
        ]]
        --minetest.debug(dump({self._oldpos,self.object:get_pos()}),self._timer)

        --[[
        if not self._oldpos then
            self._oldpos=self.object:get_pos()
        end
        local accel=vector.new(0,-0.1,0)*dtime
        local current_pos=self.object:get_pos()
        self.object:set_pos(self.object:get_pos()*2-self._oldpos+accel)
        self._oldpos=current_pos
        ]]
        
        
        local rounded_pos=self.object:get_pos():round()
        local max_collision=nil
        local max_overlap=0
        for y=-1,1 do
            for x=-1,1 do
                for z=-1,1 do
                    local checkpos=rounded_pos+vector.new(x,y,z)
                    if minetest.registered_nodes[minetest.get_node(checkpos).name].walkable then
                        local object_params={
                            pos=self.object:get_pos(),
                            radius=self._radius,
                        }
                        --[[
                        local collision=simplerigid.collide(
                            object_params,
                            {pos=rounded_pos+vector.new(x,y,z),radius=0.5},
                            "sphere-sphere"
                        )]]
                        local collision=simplerigid.collide(
                            object_params,
                            simplerigid.generate_node_collision(checkpos),
                            "sphere-polygon"
                        )
                        if collision then
                            if collision.overlap>max_overlap then
                                max_overlap=collision.overlap
                                max_collision=collision
                            end
                            --minetest.debug(dump(collision))
                            --self._active=false
                        end
                    end
                end
            end
        end

        if max_overlap>0 then
            --[[
            local current_pos=self.object:get_pos()
            self.object:set_pos(self.object:get_pos()+max_collision.dir*max_overlap)
            --minetest.debug(max_collision.contact_type)
            self._oldpos=current_pos
            ]]
            --self.object:set_pos(self.object:get_pos()+max_collision.dir*max_overlap)

            local velocity=self.object:get_velocity()
            local amount_of_vel_in_object=-max_collision.overlap/velocity:dot(max_collision.dir)
            local reflected_vel=velocity - 2 * velocity:dot(max_collision.dir)*max_collision.dir

            local old_energy=1/2*self._mass*velocity:length()^2 + 1/2*self._angular_inertia:length()*self._angular_velocity:length()^2
            --vector reflection equation from https://math.stackexchange.com/questions/13261/how-to-get-a-reflection-vector
            self.object:set_pos(self.object:get_pos()+max_collision.dir*max_overlap*2)
            --self.object:set_velocity(reflected_vel)
            self.object:add_velocity(-2 * velocity:dot(max_collision.dir)*max_collision.dir)
            --self._active=false
            self.object:add_velocity(max_collision.dir:cross(self._angular_velocity)/self._mass)
            self._angular_velocity=self.object:get_velocity():cross(max_collision.dir)/self._angular_inertia:length()

            local new_energy=1/2*self._mass*self.object:get_velocity():length()^2 + 1/2*self._angular_inertia:length()*self._angular_velocity:length()^2

            self.object:set_velocity(self.object:get_velocity()*((old_energy/new_energy)^0.5))
            self._angular_velocity=self._angular_velocity*((old_energy/new_energy)^0.5)

            --minetest.debug(new_energy,old_energy,1/2*self.object:get_velocity():length()^2 + 1/2*self._angular_velocity:length()^2)
        end
    end
})