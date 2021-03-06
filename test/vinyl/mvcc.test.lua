net = require('net.box')
address  = os.getenv('ADMIN')
box.schema.user.grant('guest', 'read,write,execute', 'universe')
yaml = require('yaml')
test_run = require('test_run').new()


_ = box.schema.space.create('test', {engine = 'vinyl'})
_ = box.space.test:create_index('pk')

c1 = net:new(address)
c2 = net.new(address)


test_run:cmd("setopt delimiter ';'")
getmetatable(c1).__call = function(c, command)
    local f = yaml.decode(c:console(command))
    if type(f) == 'table' then
        f = f[1]
        setmetatable(f, {__serialize='array'})
    end
    return f
end;
test_run:cmd("setopt delimiter ''");
methods = getmetatable(c1)['__index']
methods.begin = function(c) return c("box.begin()") end
methods.commit = function(c) return c("box.commit()") end
methods.rollback = function(c) return c("box.rollback()") end

-- basic effects

c1:begin()
c1("box.space.test:insert{1,2,3}")
c1("box.space.test:select{}")
c1:rollback()
c1("box.space.test:select{}")

-- cleanup
box.space.test:drop()
c1 = nil
c2 = nil
