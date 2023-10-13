{
    // Serialize a shallow Json object as ZSH property declarations.
    manifestZshVars(value)::
        local aux(root) =
            if !std.isObject(root) then
                error 'Expected a object, got %s' % std.type(value)
            else
                local props = ['%s="%s"' % [k, root[k]] for k in std.objectFields(root)];
                std.lines(props);
        aux(value)
}