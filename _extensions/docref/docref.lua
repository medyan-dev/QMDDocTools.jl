-- local logging = require 'logging'
local text = require 'text'

local CurrentModule = ""

local function get_CurrentModule(meta)
    if meta.CurrentModule ~= nil then
        CurrentModule = meta.CurrentModule[1].text
    end
    -- logging.temp('CurrentModule', CurrentModule)
    return nil
end

local function myhash(in_text)
    -- replace all non a-z A-Z 0-9 - _ and . bytes with -
    local t1 = string.gsub(in_text, "[^a-zA-Z0-9%-%.%_]" ,"-")
    -- make lower case
    local t2 = text.lower(t1)
    -- make sure the string starts with a letter.
    local t3 = string.match(t2, "[a-z].*")
    local hash_text = string.sub(pandoc.utils.sha1(in_text),1,16)
    if t3 then
        return t3 .. "-" .. hash_text
    else
        return hash_text
    end
end

local function docref(el)
    if el.target == "@ref" then
        -- logging.temp('el', el)
        -- note: currently # in filenames are not allowed
        -- assert(#(el.title)>0, "@ref needs a quoted expression after to create a link")
        -- try and get binding from link content
        local filepath = ""
        local binding = ""
        local signature = ""
        local CurrentModulebinding = ""
        if #(el.title)==0 then
            assert(el.content[1].tag == "Code", "@ref needs a quoted expression after to create a link: link label " .. pandoc.utils.stringify(el))
            binding, signature = string.match(el.content[1].text, "^([^#]*)#?(.*)")
        else
            filepath, binding, signature = string.match(el.title, "^([^#]*)#?([^#]*)#?(.*)")
        end
        if (not string.find(binding, "%.")) and #CurrentModule ~= 0 then
            CurrentModulebinding = CurrentModule .. "." .. binding
        else
            CurrentModulebinding = binding
        end
        -- print("filepath:", filepath)
        -- print("binding:", binding)
        -- print("CurrentModulebinding:", CurrentModulebinding)
        -- print("signature:", signature)
        if #filepath == 0 then
            assert(#binding > 0, "binding must exist if no filename: link label " .. pandoc.utils.stringify(el))
            el.target = "/docstrings/" .. myhash(CurrentModulebinding) .. ".qmd"
            if #signature > 0 then
                el.target = el.target .. "#" .. myhash(signature)
            end
        else
            el.target = filepath
            if #binding > 0 then
                el.target = el.target .. "#" .. myhash(CurrentModulebinding)
            end
        end
        return el
    else
        return nil
    end
end

return {{Meta = get_CurrentModule}, {Link = docref}}