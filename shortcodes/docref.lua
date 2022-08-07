local function myhash(in_text)
    return string.sub(pandoc.utils.sha1(in_text),1,16)
    -- return string.sub(sha.sha256(in_text),1,16)
end

return {
    ["docrefhash"] = function(args)
        if #args > 0 then
            local in_text= args[1][1].text
            -- print("input:", in_text)
            local your_hash = myhash(in_text)
            -- print("hash:", your_hash)
            return pandoc.Str(your_hash)
        else
            -- no args, we can't do anything
            return nil
        end
    end,
    ["docref"] = function(args)
        nargs = #args
        assert(nargs > 0, "not enough args")

        local linklabel = args[1]
        local startidx = 1
        local in_type = pandoc.utils.type((args[1]))
        if nargs==2 then
            if in_type == "table" then
                -- add binding if just src and binding
                table.insert(linklabel, args[2][1])
                startidx = 0
            end
        end
        if nargs == 1 then
            startidx = 0
        end
        if (nargs - startidx) == 1 then
            -- space sep means binding signature is specified
            local in_text = args[1+startidx][1].text
            for binding, signature in string.gmatch(in_text, "(%S+)%s+(.+)") do
                return pandoc.Link(linklabel, "/docstrings/" .. myhash(binding) .. ".qmd#" .. myhash(signature))
            end
            return pandoc.Link(linklabel, "/docstrings/" .. myhash(in_text) .. ".qmd")
        elseif (nargs - startidx)==2 then
            -- print("src and binding")
            local src = args[1+startidx][1].text
            local binding = args[2+startidx][1].text
            return pandoc.Link(linklabel, src .. "#" .. myhash(binding))
        else
            print("docref failed")
            return { pandoc.Strong({pandoc.Str("docref failed")}) }
        end
    end,
}