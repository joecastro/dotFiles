{
    // Serialize a shallow Json object as ZSH property declarations.
    manifestShellVars(value)::
        local aux(root) =
            if !std.isObject(root) then
                error 'Expected a object, got %s' % std.type(value)
            else
                local props = ['export %s="%s"' % [k, root[k]] for k in std.objectFields(root)];
                std.lines(['#! /bin/bash', ''] + props);
        aux(value)
}